import Foundation
import Speech
import AVFoundation

#if canImport(UIKit)
import UIKit
#endif

/// States for the speech recognition service
enum SpeechRecognitionState: Equatable {
    case idle
    case requestingPermission
    case listening
    case processing  // New: Processing audio with OpenAI
    case error(SpeechRecognitionError)
    
    var isActive: Bool {
        self == .listening || self == .processing
    }
    
    var isListening: Bool {
        self == .listening
    }
    
    var isProcessing: Bool {
        self == .processing
    }
}

/// Errors that can occur during speech recognition
enum SpeechRecognitionError: LocalizedError, Equatable {
    case notAuthorized
    case notAvailable
    case audioEngineError(String)
    case recognitionFailed(String)
    case noSpeechDetected
    case apiKeyNotConfigured
    case transcriptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in Settings."
        case .notAvailable:
            return "Speech recognition is not available on this device."
        case .audioEngineError(let detail):
            return "Audio error: \(detail)"
        case .recognitionFailed(let detail):
            return "Recognition failed: \(detail)"
        case .noSpeechDetected:
            return "No speech was detected. Please try again."
        case .apiKeyNotConfigured:
            return "OpenAI API key not configured. Please add it in Settings or use Native recognition."
        case .transcriptionFailed(let detail):
            return "Transcription failed: \(detail)"
        }
    }
}

/// Service that handles speech-to-text conversion using Apple's Speech Framework or OpenAI Whisper
@MainActor
@Observable
final class SpeechRecognitionService {
    
    // MARK: - Published State
    
    /// Current state of the speech recognition
    private(set) var state: SpeechRecognitionState = .idle
    
    /// The transcribed text (updates in real-time for native, after processing for OpenAI)
    private(set) var transcribedText: String = ""
    
    /// Audio level for visualization (0.0 - 1.0)
    private(set) var audioLevel: Float = 0.0
    
    /// Current voice input provider
    var provider: VoiceInputProvider = VoiceInputSettings.shared.defaultProvider
    
    // MARK: - Private Properties
    
    // Native speech recognition
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Shared audio engine
    private var audioEngine: AVAudioEngine?
    
    // OpenAI audio recording
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    /// Flag to track if we're intentionally stopping (to ignore the cancellation error)
    private var isStoppingIntentionally = false
    
    // MARK: - Initialization
    
    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    // MARK: - Permission Management
    
    /// Current authorization status for speech recognition
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }
    
    /// Whether speech recognition is authorized and available
    var isAvailable: Bool {
        guard let recognizer = speechRecognizer else { return false }
        return authorizationStatus == .authorized && recognizer.isAvailable
    }
    
    /// Whether OpenAI transcription is available (API key configured)
    var isOpenAIAvailable: Bool {
        get async {
            await AIService.shared.isConfigured
        }
    }
    
    /// Request authorization for speech recognition and microphone access
    func requestAuthorization() async -> Bool {
        state = .requestingPermission
        
        // Request speech recognition authorization (needed for native mode)
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        // For OpenAI mode, we don't strictly need speech authorization, but we do need mic
        if provider == .native && speechStatus != .authorized {
            state = .error(.notAuthorized)
            return false
        }
        
        // Request microphone access
        #if os(iOS)
        let micStatus = await AVAudioApplication.requestRecordPermission()
        guard micStatus else {
            state = .error(.notAuthorized)
            return false
        }
        #else
        // macOS handles audio permissions differently
        let micStatus: Bool = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        guard micStatus else {
            state = .error(.notAuthorized)
            return false
        }
        #endif
        
        state = .idle
        return true
    }
    
    // MARK: - Speech Recognition
    
    /// Start listening and transcribing speech
    func startListening() async {
        // For OpenAI provider, check API key first
        if provider == .openai {
            let isConfigured = await AIService.shared.isConfigured
            if !isConfigured {
                state = .error(.apiKeyNotConfigured)
                return
            }
        }
        
        // Check authorization
        if provider == .native && authorizationStatus != .authorized {
            let authorized = await requestAuthorization()
            guard authorized else { return }
        } else if provider == .openai {
            // Still need mic permission for OpenAI
            let authorized = await requestAuthorization()
            guard authorized else { return }
        }
        
        // Clean up any existing session first
        cleanupRecognition()
        
        // Reset state for new session
        transcribedText = ""
        audioLevel = 0.0
        isStoppingIntentionally = false
        
        // Start based on provider
        switch provider {
        case .native:
            await startNativeRecognition()
        case .openai:
            await startOpenAIRecording()
        }
    }
    
    /// Stop listening and finalize transcription
    func stopListening() async {
        guard state == .listening else { return }
        
        // Mark that we're stopping intentionally
        isStoppingIntentionally = true
        
        // Provide haptic feedback on stop
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        
        switch provider {
        case .native:
            stopNativeRecognition()
        case .openai:
            await stopOpenAIRecording()
        }
    }
    
    /// Cancel recognition and discard any transcribed text
    func cancelListening() {
        isStoppingIntentionally = true
        cleanupRecognition()
        transcribedText = ""
        audioLevel = 0.0
        state = .idle
    }
    
    /// Clear the transcribed text (for starting fresh)
    func clearText() {
        transcribedText = ""
    }
    
    /// Reset the service to its initial state
    func reset() {
        cancelListening()
    }
    
    // MARK: - Native Speech Recognition
    
    private func startNativeRecognition() async {
        guard let recognizer = speechRecognizer else {
            state = .error(.notAvailable)
            return
        }
        
        guard recognizer.isAvailable else {
            state = .error(.recognitionFailed("Speech recognizer not available for locale"))
            return
        }
        
        // Configure audio session (iOS only)
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error(.audioEngineError("Failed to configure audio session: \(error.localizedDescription)"))
            return
        }
        #endif
        
        // Create a fresh audio engine for each session
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            state = .error(.audioEngineError("Failed to create audio engine"))
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            state = .error(.recognitionFailed("Could not create recognition request"))
            return
        }
        
        // Configure for real-time results
        recognitionRequest.shouldReportPartialResults = true
        
        // On-device recognition: only enable if truly available
        #if os(iOS)
        if recognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        #endif
        
        // Set up audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            state = .error(.audioEngineError("Invalid recording format"))
            return
        }
        
        // Install tap on input node to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level for visualization
            Task { @MainActor [weak self] in
                self?.updateAudioLevel(buffer: buffer)
            }
        }
        
        // Start the audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            state = .error(.audioEngineError("Failed to start audio engine: \(error.localizedDescription)"))
            cleanupRecognition()
            return
        }
        
        // Now we're listening
        state = .listening
        
        // Provide haptic feedback on start
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.isStoppingIntentionally {
                    return
                }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    if self.isStoppingIntentionally {
                        return
                    }
                    self.handleRecognitionError(error)
                }
            }
        }
        
        if recognitionTask == nil {
            state = .error(.recognitionFailed("Failed to create recognition task"))
            cleanupRecognition()
        }
    }
    
    private func stopNativeRecognition() {
        // End the audio stream to the recognizer
        recognitionRequest?.endAudio()
        
        // Stop and clean up
        cleanupRecognition()
        
        // Transition to idle
        audioLevel = 0.0
        state = .idle
    }
    
    // MARK: - OpenAI Recording
    
    private func startOpenAIRecording() async {
        // Configure audio session
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error(.audioEngineError("Failed to configure audio session: \(error.localizedDescription)"))
            return
        }
        #endif
        
        // Create temporary file URL for recording
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice_recording_\(UUID().uuidString).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)
        
        guard let recordingURL = recordingURL else {
            state = .error(.audioEngineError("Failed to create recording URL"))
            return
        }
        
        // Audio recording settings for m4a (AAC)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            state = .listening
            
            // Provide haptic feedback on start
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            
            // Start audio level monitoring
            startAudioLevelMonitoring()
            
        } catch {
            state = .error(.audioEngineError("Failed to start recording: \(error.localizedDescription)"))
            return
        }
    }
    
    private func stopOpenAIRecording() async {
        // Stop recording
        audioRecorder?.stop()
        stopAudioLevelMonitoring()
        
        // Transition to processing state
        state = .processing
        audioLevel = 0.0
        
        // Read audio file and send to OpenAI
        guard let recordingURL = recordingURL else {
            state = .error(.transcriptionFailed("No recording found"))
            return
        }
        
        do {
            let audioData = try Data(contentsOf: recordingURL)
            
            // Check if we have any audio data
            guard audioData.count > 1000 else {
                state = .error(.noSpeechDetected)
                cleanupRecording()
                return
            }
            
            // Send to OpenAI for transcription
            let text = try await AIService.shared.transcribeAudio(audioData)
            
            if text.isEmpty {
                state = .error(.noSpeechDetected)
            } else {
                transcribedText = text
                state = .idle
            }
            
        } catch let error as AIServiceError {
            state = .error(.transcriptionFailed(error.localizedDescription))
        } catch {
            state = .error(.transcriptionFailed(error.localizedDescription))
        }
        
        // Clean up recording file
        cleanupRecording()
        
        // Deactivate audio session
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
    
    private var audioLevelTimer: Timer?
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                
                // Convert decibels to 0-1 range
                let db = recorder.averagePower(forChannel: 0)
                // db typically ranges from -160 (silent) to 0 (max)
                // Normalize to 0-1 range
                let normalized = max(0, (db + 50) / 50)
                self.audioLevel = self.audioLevel * 0.7 + normalized * 0.3
            }
        }
    }
    
    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    private func cleanupRecording() {
        // Delete temporary recording file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        audioRecorder = nil
    }
    
    // MARK: - Error Handling
    
    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        
        print("🎤 Speech recognition error: \(nsError.domain) code=\(nsError.code) - \(nsError.localizedDescription)")
        
        if nsError.domain == "kAFAssistantErrorDomain" {
            switch nsError.code {
            case 1110:
                if transcribedText.isEmpty {
                    state = .error(.noSpeechDetected)
                } else {
                    state = .idle
                }
            case 216, 1:
                if state == .listening {
                    state = .idle
                }
            case 203:
                state = .error(.recognitionFailed("Server unavailable. Please try again."))
            case 209:
                state = .error(.recognitionFailed("No internet connection for speech recognition."))
            case 301:
                state = .error(.recognitionFailed("Too many requests. Please wait and try again."))
            default:
                state = .error(.recognitionFailed("Error \(nsError.code): \(nsError.localizedDescription)"))
            }
        } else if nsError.domain == "kLSRErrorDomain" {
            switch nsError.code {
            case 201:
                state = .error(.recognitionFailed("Speech recognition assets not available."))
            case 300:
                state = .error(.recognitionFailed("Speech recognition request was denied."))
            default:
                state = .error(.recognitionFailed("LSR Error \(nsError.code)"))
            }
        } else {
            state = .error(.recognitionFailed("\(nsError.domain) \(nsError.code)"))
        }
        
        cleanupRecognition()
    }
    
    // MARK: - Cleanup
    
    private func cleanupRecognition() {
        // Stop audio engine (native mode)
        if let audioEngine = audioEngine {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        
        // Cancel recognition task (native mode)
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Stop recorder (OpenAI mode)
        audioRecorder?.stop()
        stopAudioLevelMonitoring()
        cleanupRecording()
        
        // Deactivate audio session on iOS
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
    
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        
        var sum: Float = 0
        
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameLength)
        let normalizedLevel = min(1.0, average * 10)
        audioLevel = audioLevel * 0.7 + normalizedLevel * 0.3
    }
}

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
    case processing
    case error(SpeechRecognitionError)
    
    var isActive: Bool {
        switch self {
        case .listening, .processing:
            return true
        default:
            return false
        }
    }
}

/// Errors that can occur during speech recognition
enum SpeechRecognitionError: LocalizedError, Equatable {
    case notAuthorized
    case notAvailable
    case audioEngineError
    case recognitionFailed
    case noSpeechDetected
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in Settings."
        case .notAvailable:
            return "Speech recognition is not available on this device."
        case .audioEngineError:
            return "Could not start audio capture. Please try again."
        case .recognitionFailed:
            return "Speech recognition failed. Please try again."
        case .noSpeechDetected:
            return "No speech was detected. Please try again."
        }
    }
}

/// Service that handles speech-to-text conversion using Apple's Speech Framework
@MainActor
@Observable
final class SpeechRecognitionService {
    
    // MARK: - Published State
    
    /// Current state of the speech recognition
    private(set) var state: SpeechRecognitionState = .idle
    
    /// The transcribed text (updates in real-time during recognition)
    private(set) var transcribedText: String = ""
    
    /// Audio level for visualization (0.0 - 1.0)
    private(set) var audioLevel: Float = 0.0
    
    // MARK: - Private Properties
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
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
    
    /// Request authorization for speech recognition and microphone access
    func requestAuthorization() async -> Bool {
        state = .requestingPermission
        
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard speechStatus == .authorized else {
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
        // Check authorization
        if authorizationStatus != .authorized {
            let authorized = await requestAuthorization()
            guard authorized else { return }
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            state = .error(.notAvailable)
            return
        }
        
        // Stop any existing recognition
        await stopListening()
        
        // Reset state
        transcribedText = ""
        audioLevel = 0.0
        state = .listening
        
        // Configure audio session
        do {
            try await configureAudioSession()
        } catch {
            state = .error(.audioEngineError)
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            state = .error(.recognitionFailed)
            return
        }
        
        // Configure for real-time results
        recognitionRequest.shouldReportPartialResults = true
        
        // Use on-device recognition if available (privacy + offline support)
        if #available(iOS 13, macOS 10.15, *) {
            recognitionRequest.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        }
        
        // Set up audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
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
            state = .error(.audioEngineError)
            cleanupRecognition()
            return
        }
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    
                    // Check if this is the final result
                    if result.isFinal {
                        self.state = .processing
                        await self.stopListening()
                        self.state = .idle
                    }
                }
                
                if let error = error {
                    // Check if it's just a timeout (no speech detected)
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                        // Timeout - user stopped speaking
                        if !self.transcribedText.isEmpty {
                            self.state = .idle
                        } else {
                            self.state = .error(.noSpeechDetected)
                        }
                    } else {
                        self.state = .error(.recognitionFailed)
                    }
                    await self.stopListening()
                }
            }
        }
        
        // Provide haptic feedback on start
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
    
    /// Stop listening and finalize transcription
    func stopListening() async {
        // Provide haptic feedback on stop
        #if os(iOS)
        if state == .listening {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        #endif
        
        audioLevel = 0.0
        cleanupRecognition()
        
        if state == .listening {
            state = .idle
        }
    }
    
    /// Cancel recognition and discard any transcribed text
    func cancelListening() async {
        await stopListening()
        transcribedText = ""
        state = .idle
    }
    
    /// Reset the service to its initial state
    func reset() {
        Task {
            await stopListening()
            transcribedText = ""
            state = .idle
        }
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() async throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
    }
    
    private func cleanupRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
    
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameLength)
        
        // Normalize to 0-1 range with some smoothing
        let normalizedLevel = min(1.0, average * 10)
        audioLevel = audioLevel * 0.7 + normalizedLevel * 0.3
    }
}


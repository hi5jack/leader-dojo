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
    case error(SpeechRecognitionError)
    
    var isActive: Bool {
        self == .listening
    }
}

/// Errors that can occur during speech recognition
enum SpeechRecognitionError: LocalizedError, Equatable {
    case notAuthorized
    case notAvailable
    case audioEngineError(String)
    case recognitionFailed(String)
    case noSpeechDetected
    
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
    private var audioEngine: AVAudioEngine?
    
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
        // Check authorization first
        if authorizationStatus != .authorized {
            let authorized = await requestAuthorization()
            guard authorized else { return }
        }
        
        guard let recognizer = speechRecognizer else {
            state = .error(.notAvailable)
            return
        }
        
        guard recognizer.isAvailable else {
            state = .error(.recognitionFailed("Speech recognizer not available for locale"))
            return
        }
        
        // Clean up any existing session first
        cleanupRecognition()
        
        // Reset state for new session
        transcribedText = ""
        audioLevel = 0.0
        isStoppingIntentionally = false
        
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
        // On macOS, on-device recognition may not work well, so we don't force it
        #if os(iOS)
        if recognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        #endif
        // On macOS, leave requiresOnDeviceRecognition as default (false)
        // This allows the system to use server-based recognition if needed
        
        // Set up audio input
        let inputNode = audioEngine.inputNode
        
        // Get the native format of the input node
        let nativeFormat = inputNode.inputFormat(forBus: 0)
        
        // Check if format is valid
        guard nativeFormat.sampleRate > 0 && nativeFormat.channelCount > 0 else {
            state = .error(.audioEngineError("Invalid audio format: SR=\(nativeFormat.sampleRate) CH=\(nativeFormat.channelCount)"))
            return
        }
        
        // For speech recognition, we need a specific format
        // Use the output format which is what we'll tap into
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            state = .error(.audioEngineError("Invalid recording format: SR=\(recordingFormat.sampleRate) CH=\(recordingFormat.channelCount)"))
            return
        }
        
        // Install tap on input node to capture audio
        do {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                
                // Calculate audio level for visualization
                Task { @MainActor [weak self] in
                    self?.updateAudioLevel(buffer: buffer)
                }
            }
        } catch {
            state = .error(.audioEngineError("Failed to install audio tap: \(error.localizedDescription)"))
            return
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
        
        // Now we're listening - set state before starting recognition
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
                
                // If we're intentionally stopping, ignore any callbacks
                if self.isStoppingIntentionally {
                    return
                }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    // Note: We do NOT auto-stop on isFinal. User must explicitly stop.
                }
                
                if let error = error {
                    // If we're stopping intentionally, ignore the error
                    if self.isStoppingIntentionally {
                        return
                    }
                    
                    self.handleRecognitionError(error)
                }
            }
        }
        
        // Check if the recognition task was created successfully
        if recognitionTask == nil {
            state = .error(.recognitionFailed("Failed to create recognition task"))
            cleanupRecognition()
        }
    }
    
    /// Handle errors from the speech recognition task
    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        
        // Log for debugging
        print("🎤 Speech recognition error: \(nsError.domain) code=\(nsError.code) - \(nsError.localizedDescription)")
        
        // Check for common error cases
        if nsError.domain == "kAFAssistantErrorDomain" {
            switch nsError.code {
            case 1110:
                // Timeout - no speech detected
                if transcribedText.isEmpty {
                    state = .error(.noSpeechDetected)
                } else {
                    state = .idle
                }
            case 216, 1:
                // Cancelled - this is normal when we stop
                if state == .listening {
                    state = .idle
                }
            case 203:
                // Server error - retry might help
                state = .error(.recognitionFailed("Server unavailable. Please try again."))
            case 209:
                // No internet connection
                state = .error(.recognitionFailed("No internet connection for speech recognition."))
            case 301:
                // Recognition request rate limited
                state = .error(.recognitionFailed("Too many requests. Please wait and try again."))
            default:
                state = .error(.recognitionFailed("Error \(nsError.code): \(nsError.localizedDescription)"))
            }
        } else if nsError.domain == "kLSRErrorDomain" {
            // Local speech recognizer errors (macOS)
            switch nsError.code {
            case 201:
                state = .error(.recognitionFailed("Speech recognition assets not available."))
            case 300:
                state = .error(.recognitionFailed("Speech recognition request was denied."))
            default:
                state = .error(.recognitionFailed("LSR Error \(nsError.code)"))
            }
        } else {
            // Unknown error domain
            state = .error(.recognitionFailed("\(nsError.domain) \(nsError.code)"))
        }
        
        cleanupRecognition()
    }
    
    /// Stop listening and finalize transcription
    func stopListening() {
        guard state == .listening else { return }
        
        // Mark that we're stopping intentionally
        isStoppingIntentionally = true
        
        // Provide haptic feedback on stop
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        
        // End the audio stream to the recognizer
        recognitionRequest?.endAudio()
        
        // Stop and clean up
        cleanupRecognition()
        
        // Transition to idle
        audioLevel = 0.0
        state = .idle
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
    
    // MARK: - Private Methods
    
    private func cleanupRecognition() {
        // Stop audio engine
        if let audioEngine = audioEngine {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Clear request
        recognitionRequest = nil
        
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
        
        // Normalize to 0-1 range with some smoothing
        let normalizedLevel = min(1.0, average * 10)
        audioLevel = audioLevel * 0.7 + normalizedLevel * 0.3
    }
}

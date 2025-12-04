import SwiftUI
import Speech
import Combine

#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

/// Full-screen overlay for voice input with real-time transcription
struct VoiceInputOverlay: View {
    @Bindable var speechService: SpeechRecognitionService
    
    /// Called when the user confirms the transcription
    let onComplete: (String) -> Void
    
    /// Called when the user cancels voice input
    let onCancel: () -> Void
    
    /// Optional title to show context
    var title: String = "Voice Input"
    
    /// Placeholder text when no speech detected yet
    var placeholder: String = "Tap the microphone to start recording"
    
    /// Accent color for the UI
    var accentColor: Color = .blue
    
    @State private var showingPermissionAlert = false
    @State private var selectedProvider: VoiceInputProvider = VoiceInputSettings.shared.defaultProvider
    @State private var isOpenAIAvailable = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var recordingStartTime: Date?
    @Environment(\.colorScheme) private var colorScheme
    
    /// Timer for updating elapsed time during recording
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    /// Whether we're currently recording
    private var isRecording: Bool {
        speechService.state.isListening
    }
    
    /// Whether we're processing (OpenAI transcription)
    private var isProcessing: Bool {
        speechService.state.isProcessing
    }
    
    /// Whether we have text that can be used
    private var hasText: Bool {
        !speechService.transcribedText.isEmpty
    }
    
    /// Whether we can show the "Use This Text" button
    private var canConfirm: Bool {
        !isRecording && !isProcessing && hasText
    }
    
    /// Whether the provider can be changed (only when idle)
    private var canChangeProvider: Bool {
        speechService.state == .idle || (speechService.state != .listening && speechService.state != .processing)
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(colorScheme == .dark ? 0.8 : 0.6)
                .ignoresSafeArea()
            
            // Main content card
            VStack(spacing: 0) {
                // Header
                header
                
                Divider()
                
                // Provider selector
                providerSelector
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                
                Divider()
                
                // Transcription area
                transcriptionArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                
                // Controls
                controlsArea
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
            .frame(maxWidth: 500)
        }
        .onAppear {
            // Clear any previous text when overlay appears
            speechService.clearText()
            // Set the initial provider from settings
            selectedProvider = VoiceInputSettings.shared.defaultProvider
            speechService.provider = selectedProvider
            // Check OpenAI availability
            Task {
                isOpenAIAvailable = await AIService.shared.isConfigured
            }
        }
        .onDisappear {
            // Make sure we stop if overlay is dismissed
            speechService.cancelListening()
        }
        .onChange(of: selectedProvider) { _, newValue in
            speechService.provider = newValue
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        } message: {
            Text("Please enable microphone and speech recognition access in Settings to use voice input.")
        }
        .onReceive(timer) { _ in
            if isRecording, let startTime = recordingStartTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        .onChange(of: isRecording) { wasRecording, nowRecording in
            if nowRecording && !wasRecording {
                // Started recording
                recordingStartTime = Date()
                elapsedTime = 0
            } else if !nowRecording && wasRecording {
                // Stopped recording
                recordingStartTime = nil
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                speechService.cancelListening()
                onCancel()
            } label: {
                Text("Cancel")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            
            Spacer()
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            // Status indicator
            statusBadge
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if isRecording {
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text(formattedElapsedTime)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.red)
            }
        } else if isProcessing {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Processing")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        } else if case .error = speechService.state {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Error")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } else if hasText {
            Text("Ready")
                .font(.caption)
                .foregroundStyle(.green)
        } else {
            Text("Ready")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Provider Selector
    
    private var providerSelector: some View {
        VStack(spacing: 8) {
            Picker("Voice Input Method", selection: $selectedProvider) {
                ForEach(VoiceInputProvider.allCases) { provider in
                    Label {
                        Text(provider.shortName)
                    } icon: {
                        Image(systemName: provider.iconName)
                    }
                    .tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!canChangeProvider)
            
            // Provider info
            HStack(spacing: 4) {
                if selectedProvider == .openai && !isOpenAIAvailable {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("API key required in Settings")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: selectedProvider.supportsStreaming ? "waveform" : "cloud")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(selectedProvider == .native ? "Real-time transcription" : "Better accuracy & formatting")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Transcription Area
    
    private var transcriptionArea: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Error message if any
                if case .error(let error) = speechService.state {
                    errorView(error)
                }
                
                // Main content
                if isProcessing {
                    processingView
                } else if isRecording {
                    recordingView
                } else if hasText {
                    transcribedTextView
                } else {
                    idleView
                }
            }
            .padding(24)
        }
    }
    
    /// View shown when idle (not recording, no text yet)
    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle")
                .font(.system(size: 60))
                .foregroundStyle(accentColor.opacity(0.5))
            
            Text(placeholder)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    /// View shown while recording
    private var recordingView: some View {
        VStack(spacing: 16) {
            // Elapsed time display
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                
                Text(formattedElapsedTime)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 4)
            
            VoiceWaveform(
                audioLevel: speechService.audioLevel,
                isActive: true,
                barCount: 7,
                color: accentColor
            )
            .frame(height: 60)
            
            // Duration warning
            if elapsedTime > 60 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("Long recordings may take longer to transcribe")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            }
            
            // For native provider, show real-time transcription
            // For OpenAI, just show "Recording..." indicator
            if selectedProvider == .native && hasText {
                Text(speechService.transcribedText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } else if selectedProvider == .openai {
                Text("Transcription will appear after you stop")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Listening...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    /// Formatted elapsed time string (MM:SS)
    private var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// View shown while processing (OpenAI only)
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Transcribing...")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("This may take a few seconds")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// View shown when we have transcribed text (after stopping)
    private var transcribedTextView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(selectedProvider == .openai ? "Transcription complete" : "Recording complete")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(speechService.transcribedText)
                .font(.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func errorView(_ error: SpeechRecognitionError) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: errorIcon(for: error))
                    .font(.title2)
                    .foregroundStyle(errorColor(for: error))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorTitle(for: error))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let description = error.errorDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
            }
            
            // Action buttons based on error type
            HStack(spacing: 12) {
                if error == .notAuthorized {
                    Button {
                        openSettings()
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else if error == .apiKeyNotConfigured {
                    Button {
                        openSettings()
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button {
                        selectedProvider = .native
                    } label: {
                        Label("Use Native", systemImage: "apple.logo")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Spacer()
            }
        }
        .padding()
        .background(errorColor(for: error).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func errorIcon(for error: SpeechRecognitionError) -> String {
        switch error {
        case .notAuthorized:
            return "lock.shield"
        case .notAvailable:
            return "iphone.slash"
        case .audioEngineError:
            return "speaker.slash"
        case .recognitionFailed:
            return "waveform.slash"
        case .noSpeechDetected:
            return "mic.slash"
        case .apiKeyNotConfigured:
            return "key.slash"
        case .transcriptionFailed:
            return "exclamationmark.triangle"
        }
    }
    
    private func errorTitle(for error: SpeechRecognitionError) -> String {
        switch error {
        case .notAuthorized:
            return "Permission Required"
        case .notAvailable:
            return "Not Available"
        case .audioEngineError:
            return "Audio Error"
        case .recognitionFailed:
            return "Recognition Failed"
        case .noSpeechDetected:
            return "No Speech Detected"
        case .apiKeyNotConfigured:
            return "API Key Required"
        case .transcriptionFailed:
            return "Transcription Failed"
        }
    }
    
    private func errorColor(for error: SpeechRecognitionError) -> Color {
        switch error {
        case .notAuthorized, .apiKeyNotConfigured:
            return .red
        case .notAvailable:
            return .gray
        case .audioEngineError, .recognitionFailed, .transcriptionFailed:
            return .orange
        case .noSpeechDetected:
            return .yellow
        }
    }
    
    // MARK: - Controls Area
    
    private var controlsArea: some View {
        VStack(spacing: 16) {
            // Main record/stop button
            recordButton
            
            // "Use This Text" button - only when we have text and not recording/processing
            if canConfirm {
                Button {
                    onComplete(speechService.transcribedText)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Use This Text")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
            
            // Hint text
            Text(hintText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    /// The main record/stop button
    private var recordButton: some View {
        Button {
            Task {
                if isRecording {
                    await speechService.stopListening()
                } else if !isProcessing {
                    // Check permissions first for native provider
                    if selectedProvider == .native && speechService.authorizationStatus != .authorized {
                        let authorized = await speechService.requestAuthorization()
                        if !authorized {
                            showingPermissionAlert = true
                            return
                        }
                    }
                    await speechService.startListening()
                }
            }
        } label: {
            ZStack {
                // Background pulse animation when recording
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 96, height: 96)
                }
                
                // Main button
                Circle()
                    .fill(isRecording ? Color.red : (isProcessing ? Color.gray : accentColor))
                    .frame(width: 64, height: 64)
                
                // Icon
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                } else {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .accessibilityLabel(isRecording ? "Stop recording" : (isProcessing ? "Processing" : "Start recording"))
    }
    
    private var hintText: String {
        if isProcessing {
            return "Please wait while your audio is being transcribed"
        } else if isRecording {
            return "Tap the stop button when you're done"
        } else if canConfirm {
            return "Tap 'Use This Text' to confirm, or record again"
        } else if case .error = speechService.state {
            return "Tap the microphone to try again"
        } else {
            return "Tap the microphone to start recording"
        }
    }
    
    // MARK: - Actions
    
    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

// MARK: - Sheet Modifier

extension View {
    /// Present a voice input overlay
    func voiceInputOverlay(
        isPresented: Binding<Bool>,
        speechService: SpeechRecognitionService,
        title: String = "Voice Input",
        accentColor: Color = .blue,
        onComplete: @escaping (String) -> Void
    ) -> some View {
        #if os(iOS)
        return self.fullScreenCover(isPresented: isPresented) {
            VoiceInputOverlay(
                speechService: speechService,
                onComplete: { text in
                    isPresented.wrappedValue = false
                    onComplete(text)
                },
                onCancel: {
                    isPresented.wrappedValue = false
                },
                title: title,
                accentColor: accentColor
            )
            .interactiveDismissDisabled(speechService.state.isActive)
        }
        #else
        return self.sheet(isPresented: isPresented) {
            VoiceInputOverlay(
                speechService: speechService,
                onComplete: { text in
                    isPresented.wrappedValue = false
                    onComplete(text)
                },
                onCancel: {
                    isPresented.wrappedValue = false
                },
                title: title,
                accentColor: accentColor
            )
            .interactiveDismissDisabled(speechService.state.isActive)
            .frame(minWidth: 400, minHeight: 500)
        }
        #endif
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showOverlay = true
    
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        Button("Show Voice Input") {
            showOverlay = true
        }
    }
    .sheet(isPresented: $showOverlay) {
        VoiceInputOverlay(
            speechService: SpeechRecognitionService(),
            onComplete: { text in
                print("Completed with: \(text)")
                showOverlay = false
            },
            onCancel: {
                showOverlay = false
            },
            title: "Capture Note"
        )
    }
}

import SwiftUI
import Speech

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
    var placeholder: String = "Start speaking..."
    
    /// Accent color for the UI
    var accentColor: Color = .blue
    
    @State private var showingPermissionAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(colorScheme == .dark ? 0.8 : 0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap while listening
                }
            
            // Main content card
            VStack(spacing: 0) {
                // Header
                header
                
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
        .task {
            await startListeningIfNeeded()
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
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                Task {
                    await speechService.cancelListening()
                    onCancel()
                }
            } label: {
                Text("Cancel")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
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
        switch speechService.state {
        case .listening:
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Recording")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
        case .processing:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Processing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
        case .error:
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Error")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
        default:
            Text("Ready")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                
                // Transcribed text or placeholder
                if speechService.transcribedText.isEmpty {
                    placeholderView
                } else {
                    transcribedTextView
                }
            }
            .padding(24)
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 16) {
            if speechService.state == .listening {
                VoiceWaveform(
                    audioLevel: speechService.audioLevel,
                    isActive: true,
                    barCount: 7,
                    color: accentColor
                )
                .frame(height: 60)
            } else {
                Image(systemName: "mic.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(accentColor.opacity(0.5))
            }
            
            Text(placeholder)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    private var transcribedTextView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Waveform indicator while listening
            if speechService.state == .listening {
                HStack {
                    VoiceWaveform(
                        audioLevel: speechService.audioLevel,
                        isActive: true,
                        barCount: 5,
                        color: accentColor
                    )
                    .frame(height: 24)
                    
                    Spacer()
                }
            }
            
            // Transcribed text
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
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                } else {
                    Button {
                        Task {
                            await speechService.startListening()
                        }
                    } label: {
                        Label("Try Again", systemImage: "arrow.clockwise")
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
        }
    }
    
    private func errorColor(for error: SpeechRecognitionError) -> Color {
        switch error {
        case .notAuthorized:
            return .red
        case .notAvailable:
            return .gray
        case .audioEngineError, .recognitionFailed:
            return .orange
        case .noSpeechDetected:
            return .yellow
        }
    }
    
    // MARK: - Controls Area
    
    private var controlsArea: some View {
        VStack(spacing: 16) {
            // Main action button
            HStack(spacing: 20) {
                // Microphone button
                VoiceInputButton(
                    isListening: speechService.state == .listening,
                    audioLevel: speechService.audioLevel,
                    action: {
                        Task {
                            if speechService.state == .listening {
                                await speechService.stopListening()
                            } else {
                                await speechService.startListening()
                            }
                        }
                    },
                    size: 64,
                    color: accentColor
                )
            }
            
            // Done button (only when we have text)
            if !speechService.transcribedText.isEmpty {
                Button {
                    Task {
                        await speechService.stopListening()
                        onComplete(speechService.transcribedText)
                    }
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
    
    private var hintText: String {
        switch speechService.state {
        case .listening:
            return "Tap the mic to stop recording"
        case .processing:
            return "Processing your speech..."
        case .error:
            return "Tap the mic to try again"
        default:
            if speechService.transcribedText.isEmpty {
                return "Tap the mic to start speaking"
            } else {
                return "Tap 'Use This Text' to confirm or record more"
            }
        }
    }
    
    // MARK: - Actions
    
    private func startListeningIfNeeded() async {
        guard speechService.state == .idle else { return }
        
        // Check if we need to request permissions
        if speechService.authorizationStatus != .authorized {
            let authorized = await speechService.requestAuthorization()
            if !authorized {
                showingPermissionAlert = true
                return
            }
        }
        
        // Start listening automatically
        await speechService.startListening()
    }
    
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


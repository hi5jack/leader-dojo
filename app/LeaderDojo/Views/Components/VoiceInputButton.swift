import SwiftUI

/// A button for initiating voice input with visual feedback
struct VoiceInputButton: View {
    let isListening: Bool
    let audioLevel: Float
    let action: () -> Void
    
    /// Size of the button
    var size: CGFloat = 56
    
    /// Primary color for the button
    var color: Color = .blue
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background pulse animation when listening
                if isListening {
                    // Outer pulse ring (slower, larger)
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: size * 1.6, height: size * 1.6)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                    
                    // Middle pulse ring based on audio level
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(
                            width: size * (1.0 + CGFloat(audioLevel) * 0.4),
                            height: size * (1.0 + CGFloat(audioLevel) * 0.4)
                        )
                        .animation(.easeOut(duration: 0.1), value: audioLevel)
                }
                
                // Main button circle
                Circle()
                    .fill(isListening ? color : color.opacity(0.15))
                    .frame(width: size, height: size)
                
                // Microphone icon
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(isListening ? .white : color)
                    .symbolEffect(.bounce, value: isListening)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isListening ? "Stop recording" : "Start voice input")
        .accessibilityHint(isListening ? "Double tap to stop recording your voice" : "Double tap to start recording your voice")
        .onChange(of: isListening) { _, newValue in
            if newValue {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.15
            pulseOpacity = 0.3
        }
    }
    
    private func stopPulseAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            pulseScale = 1.0
            pulseOpacity = 0.6
        }
    }
}

/// A compact inline voice button for placing next to text fields
struct InlineVoiceButton: View {
    let isListening: Bool
    let action: () -> Void
    
    var color: Color = .blue
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isListening {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
                
                Circle()
                    .fill(isListening ? color : Color.clear)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(isListening ? Color.clear : color.opacity(0.5), lineWidth: 1.5)
                    )
                
                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isListening ? .white : color)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isListening ? "Stop recording" : "Voice input")
    }
}

/// Animated waveform visualization for voice input
struct VoiceWaveform: View {
    let audioLevel: Float
    let isActive: Bool
    let barCount: Int
    let color: Color
    
    init(
        audioLevel: Float,
        isActive: Bool,
        barCount: Int = 5,
        color: Color = .blue
    ) {
        self.audioLevel = audioLevel
        self.isActive = isActive
        self.barCount = barCount
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    audioLevel: audioLevel,
                    index: index,
                    isActive: isActive,
                    color: color
                )
            }
        }
    }
}

private struct WaveformBar: View {
    let audioLevel: Float
    let index: Int
    let isActive: Bool
    let color: Color
    
    @State private var animatedHeight: CGFloat = 0.2
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 4, height: max(8, animatedHeight * 40))
            .onChange(of: audioLevel) { _, newLevel in
                if isActive {
                    // Add some variation based on bar index
                    let variation = sin(Double(index) * 0.8 + Double(newLevel) * 10) * 0.3
                    let targetHeight = CGFloat(newLevel) + CGFloat(variation)
                    
                    withAnimation(.easeOut(duration: 0.08)) {
                        animatedHeight = max(0.2, min(1.0, targetHeight))
                    }
                }
            }
            .onChange(of: isActive) { _, active in
                if !active {
                    withAnimation(.easeOut(duration: 0.3)) {
                        animatedHeight = 0.2
                    }
                }
            }
            .onAppear {
                // Initial random variation
                if isActive {
                    animatedHeight = CGFloat.random(in: 0.3...0.6)
                }
            }
    }
}

/// A view shown when voice input permissions are not granted
struct VoicePermissionPrompt: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("Voice Input Unavailable")
                    .font(.headline)
                
                Text("Please enable microphone and speech recognition access in Settings to use voice input.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button("Not Now") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Open Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews

#Preview("Voice Input Button - Idle") {
    VStack(spacing: 30) {
        VoiceInputButton(
            isListening: false,
            audioLevel: 0,
            action: {}
        )
        
        VoiceInputButton(
            isListening: false,
            audioLevel: 0,
            action: {},
            size: 44,
            color: .purple
        )
    }
    .padding()
}

#Preview("Voice Input Button - Listening") {
    VStack(spacing: 30) {
        VoiceInputButton(
            isListening: true,
            audioLevel: 0.5,
            action: {}
        )
        
        VoiceInputButton(
            isListening: true,
            audioLevel: 0.8,
            action: {},
            color: .indigo
        )
    }
    .padding()
}

#Preview("Inline Voice Button") {
    HStack {
        Text("Notes")
        Spacer()
        InlineVoiceButton(isListening: false, action: {})
        InlineVoiceButton(isListening: true, action: {})
    }
    .padding()
}

#Preview("Voice Waveform") {
    VStack(spacing: 20) {
        VoiceWaveform(audioLevel: 0.3, isActive: true)
        VoiceWaveform(audioLevel: 0.7, isActive: true, color: .purple)
        VoiceWaveform(audioLevel: 0, isActive: false)
    }
    .padding()
}


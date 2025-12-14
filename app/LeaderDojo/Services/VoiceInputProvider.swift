import Foundation
import SwiftUI

/// Voice input provider options for transcription
enum VoiceInputProvider: String, Codable, CaseIterable, Identifiable {
    case native = "native"
    case openai = "openai"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .native:
            return "Native (Apple)"
        case .openai:
            return "OpenAI (Whisper)"
        }
    }
    
    var shortName: String {
        switch self {
        case .native:
            return "Native"
        case .openai:
            return "OpenAI"
        }
    }
    
    var description: String {
        switch self {
        case .native:
            return "On-device speech recognition. Works offline, real-time transcription."
        case .openai:
            return "Cloud-based transcription with better accuracy and auto-formatting. Requires internet."
        }
    }
    
    var iconName: String {
        switch self {
        case .native:
            return "apple.logo"
        case .openai:
            return "cloud"
        }
    }
    
    /// Whether this provider supports real-time streaming transcription
    var supportsStreaming: Bool {
        switch self {
        case .native:
            return true
        case .openai:
            return false
        }
    }
    
    /// Whether this provider requires an API key
    var requiresAPIKey: Bool {
        switch self {
        case .native:
            return false
        case .openai:
            return true
        }
    }
    
    /// Whether this provider requires internet connection
    var requiresInternet: Bool {
        switch self {
        case .native:
            return false
        case .openai:
            return true
        }
    }
}

// MARK: - Settings Storage

/// Manager for voice input settings
@Observable
class VoiceInputSettings {
    static let shared = VoiceInputSettings()
    
    private let defaultProviderKey = "voiceInputDefaultProvider"
    
    /// The default voice input provider set by the user in Settings
    var defaultProvider: VoiceInputProvider {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultProviderKey),
               let provider = VoiceInputProvider(rawValue: rawValue) {
                return provider
            }
            return .native
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultProviderKey)
        }
    }
    
    private init() {}
}








import SwiftUI

/// Leader Dojo Color System
/// Dark & Grounded palette with Premium & Refined aesthetics
enum LeaderDojoColors {
    // MARK: - Foundation Colors (Dark & Grounded)
    
    /// Primary background - Deep black for main canvas
    static let dojoBlack = Color(hex: "0A0A0A")
    
    /// Card backgrounds and elevated surfaces
    static let dojoCharcoal = Color(hex: "1A1A1A")
    
    /// Subtle borders and dividers
    static let dojoDarkGray = Color(hex: "2D2D2D")
    
    /// Secondary text
    static let dojoMediumGray = Color(hex: "6B7280")
    
    /// Tertiary text and hints
    static let dojoLightGray = Color(hex: "9CA3AF")
    
    /// High-contrast text on dark backgrounds
    static let dojoPaper = Color(hex: "F5F5F0")
    
    // MARK: - Accent Colors (Intent-based)
    
    /// Warm, energizing - I Owe commitments, priority items
    static let dojoAmber = Color(hex: "F59E0B")
    
    /// Cool, calm - Waiting For, informational
    static let dojoBlue = Color(hex: "3B82F6")
    
    /// Achievement - completed, success states
    static let dojoGreen = Color(hex: "10B981")
    
    /// Urgency - overdue, critical
    static let dojoRed = Color(hex: "EF4444")
    
    /// Growth - reflections, insights
    static let dojoEmerald = Color(hex: "059669")
    
    // MARK: - Semantic Layers (Z-axis depth)
    
    /// Primary surface level
    static let surfacePrimary = dojoBlack
    
    /// Secondary surface level (elevated)
    static let surfaceSecondary = dojoCharcoal
    
    /// Tertiary surface level (most elevated)
    static let surfaceTertiary = Color(hex: "252525")
    
    // MARK: - Text Hierarchy
    
    /// Primary text color
    static let textPrimary = dojoPaper
    
    /// Secondary text color
    static let textSecondary = dojoLightGray
    
    /// Tertiary text color
    static let textTertiary = dojoMediumGray
    
    // MARK: - Interactive Elements
    
    /// Primary accent for interactive elements
    static let accentPrimary = dojoAmber
    
    /// Secondary accent
    static let accentSecondary = dojoBlue
    
    // MARK: - Legacy Compatibility (Deprecated)
    
    @available(*, deprecated, message: "Use surfacePrimary instead")
    static let background = surfacePrimary
    
    @available(*, deprecated, message: "Use textPrimary instead")
    static let foreground = textPrimary
    
    @available(*, deprecated, message: "Use surfaceSecondary instead")
    static let card = surfaceSecondary
    
    @available(*, deprecated, message: "Use dojoDarkGray instead")
    static let border = dojoDarkGray
    
    @available(*, deprecated, message: "Use dojoAmber instead")
    static let amber = dojoAmber
    
    @available(*, deprecated, message: "Use dojoBlue instead")
    static let blue = dojoBlue
    
    @available(*, deprecated, message: "Use dojoRed instead")
    static let red = dojoRed
    
    @available(*, deprecated, message: "Use dojoGreen instead")
    static let green = dojoGreen
    
    @available(*, deprecated, message: "Use dojoRed instead")
    static let warning = dojoRed
    
    @available(*, deprecated, message: "Use dojoMediumGray instead")
    static let muted = dojoMediumGray
    
    @available(*, deprecated, message: "Use dojoAmber instead")
    static let primaryAction = dojoAmber
    
    @available(*, deprecated, message: "Use dojoPaper instead")
    static let primaryActionDark = dojoPaper
}

// MARK: - Color Utilities

extension Color {
    /// Initialize a Color from a hex string
    /// Supports 3, 6, and 8 character hex codes
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Create a gradient background for cards
    static func dojoCardGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                LeaderDojoColors.dojoCharcoal,
                LeaderDojoColors.surfaceTertiary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Create an amber glow for priority items
    static func dojoAmberGlow() -> Color {
        LeaderDojoColors.dojoAmber.opacity(0.3)
    }
}

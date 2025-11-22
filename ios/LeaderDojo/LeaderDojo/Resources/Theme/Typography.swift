import SwiftUI

/// Leader Dojo Typography System
/// Premium & Refined type scale with proper hierarchy
enum LeaderDojoTypography {
    // MARK: - Display (Onboarding, Empty States, Hero Sections)
    
    /// Large display text - 40pt bold
    static let displayLarge = Font.system(size: 40, weight: .bold, design: .default)
    
    /// Medium display text - 34pt bold
    static let displayMedium = Font.system(size: 34, weight: .bold, design: .default)
    
    // MARK: - Headings (Section Headers, Card Titles)
    
    /// Extra large heading - 28pt bold with tight spacing
    static let headingXL: Font = {
        return Font.system(size: 28, weight: .bold, design: .default)
    }()
    
    /// Large heading - 24pt semibold
    static let headingLarge = Font.system(size: 24, weight: .semibold, design: .default)
    
    /// Medium heading - 20pt semibold
    static let headingMedium = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body Text (Primary Content)
    
    /// Large body text - 17pt regular with comfortable line height
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Medium body text - 15pt regular
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    
    // MARK: - Captions (Secondary Content, Metadata)
    
    /// Large caption - 14pt medium
    static let captionLarge = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Regular caption - 13pt regular
    static let captionRegular = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Labels (Badges, Tags, Small UI Elements)
    
    /// Label text - 11pt semibold uppercase
    static let label = Font.system(size: 11, weight: .semibold, design: .default)
    
    // MARK: - Monospace (Code, Technical Content)
    
    /// Monospace text - 15pt regular
    static let monospace = Font.system(size: 15, weight: .regular, design: .monospaced)
    
    // MARK: - Legacy Compatibility (Deprecated)
    
    @available(*, deprecated, message: "Use headingXL instead")
    static let heading = headingXL
    
    @available(*, deprecated, message: "Use headingMedium instead")
    static let subheading = headingMedium
    
    @available(*, deprecated, message: "Use bodyLarge instead")
    static let body = bodyLarge
    
    @available(*, deprecated, message: "Use captionLarge instead")
    static let caption = captionLarge
}

// MARK: - Typography Modifiers

extension View {
    /// Apply display large typography with primary text color
    func dojoDisplayLarge() -> some View {
        self
            .font(LeaderDojoTypography.displayLarge)
            .foregroundStyle(LeaderDojoColors.textPrimary)
    }
    
    /// Apply display medium typography with primary text color
    func dojoDisplayMedium() -> some View {
        self
            .font(LeaderDojoTypography.displayMedium)
            .foregroundStyle(LeaderDojoColors.textPrimary)
    }
    
    /// Apply heading XL typography with primary text color
    func dojoHeadingXL() -> some View {
        self
            .font(LeaderDojoTypography.headingXL)
            .foregroundStyle(LeaderDojoColors.textPrimary)
            .tracking(-0.5)
    }
    
    /// Apply heading large typography with primary text color
    func dojoHeadingLarge() -> some View {
        self
            .font(LeaderDojoTypography.headingLarge)
            .foregroundStyle(LeaderDojoColors.textPrimary)
    }
    
    /// Apply heading medium typography with primary text color
    func dojoHeadingMedium() -> some View {
        self
            .font(LeaderDojoTypography.headingMedium)
            .foregroundStyle(LeaderDojoColors.textPrimary)
    }
    
    /// Apply body large typography with primary text color and comfortable line spacing
    func dojoBodyLarge() -> some View {
        self
            .font(LeaderDojoTypography.bodyLarge)
            .foregroundStyle(LeaderDojoColors.textPrimary)
            .lineSpacing(4)
    }
    
    /// Apply body medium typography with primary text color
    func dojoBodyMedium() -> some View {
        self
            .font(LeaderDojoTypography.bodyMedium)
            .foregroundStyle(LeaderDojoColors.textPrimary)
    }
    
    /// Apply caption large typography with secondary text color
    func dojoCaptionLarge() -> some View {
        self
            .font(LeaderDojoTypography.captionLarge)
            .foregroundStyle(LeaderDojoColors.textSecondary)
    }
    
    /// Apply caption regular typography with secondary text color
    func dojoCaptionRegular() -> some View {
        self
            .font(LeaderDojoTypography.captionRegular)
            .foregroundStyle(LeaderDojoColors.textSecondary)
    }
    
    /// Apply label typography (uppercase) with tertiary text color
    func dojoLabel() -> some View {
        self
            .font(LeaderDojoTypography.label)
            .foregroundStyle(LeaderDojoColors.textTertiary)
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

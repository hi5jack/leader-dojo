import SwiftUI

/// Leader Dojo Spacing System
/// Based on 4px grid for consistent alignment
enum LeaderDojoSpacing {
    // MARK: - Base Spacing Scale (4px increments)
    
    /// 4px - Micro spacing
    static let xs: CGFloat = 4
    
    /// 8px - Small spacing
    static let s: CGFloat = 8
    
    /// 12px - Compact spacing
    static let sm: CGFloat = 12
    
    /// 16px - Medium spacing (default)
    static let m: CGFloat = 16
    
    /// 20px - Comfortable spacing
    static let ml: CGFloat = 20
    
    /// 24px - Large spacing
    static let l: CGFloat = 24
    
    /// 32px - Extra large spacing
    static let xl: CGFloat = 32
    
    /// 40px - 2X large spacing
    static let xxl: CGFloat = 40
    
    /// 48px - 3X large spacing
    static let xxxl: CGFloat = 48
    
    /// 64px - 4X large spacing
    static let xxxxl: CGFloat = 64
    
    /// 80px - 5X large spacing
    static let xxxxxl: CGFloat = 80
    
    // MARK: - Edge Insets Presets
    
    /// Compact padding - 12px all sides
    static let compact = EdgeInsets(top: sm, leading: sm, bottom: sm, trailing: sm)
    
    /// Comfortable padding - 16px all sides
    static let comfortable = EdgeInsets(top: m, leading: m, bottom: m, trailing: m)
    
    /// Spacious padding - 24px all sides
    static let spacious = EdgeInsets(top: l, leading: l, bottom: l, trailing: l)
    
    /// Screen edges - 20px horizontal, 16px vertical
    static let screenEdges = EdgeInsets(top: m, leading: ml, bottom: m, trailing: ml)
    
    /// Card padding - 16px horizontal, 20px vertical
    static let cardPadding = EdgeInsets(top: ml, leading: m, bottom: ml, trailing: m)
    
    // MARK: - Corner Radius
    
    /// Small corner radius - 8px
    static let cornerRadiusSmall: CGFloat = 8
    
    /// Medium corner radius - 12px (compact cards)
    static let cornerRadiusMedium: CGFloat = 12
    
    /// Large corner radius - 16px (standard cards)
    static let cornerRadiusLarge: CGFloat = 16
    
    /// Extra large corner radius - 24px (modals, sheets)
    static let cornerRadiusXL: CGFloat = 24
    
    /// Pill shape corner radius
    static let cornerRadiusPill: CGFloat = 999
    
    // MARK: - Shadow & Depth
    
    /// Shadow radius for elevated cards
    static let shadowRadius: CGFloat = 16
    
    /// Shadow offset for elevated cards
    static let shadowOffset: CGSize = CGSize(width: 0, height: 4)
    
    // MARK: - Interactive Elements
    
    /// Minimum tap target size (44x44)
    static let minTapTarget: CGFloat = 44
    
    /// Button height (standard)
    static let buttonHeight: CGFloat = 48
    
    /// Button height (compact)
    static let buttonHeightCompact: CGFloat = 40
    
    /// Icon size (small)
    static let iconSmall: CGFloat = 16
    
    /// Icon size (medium)
    static let iconMedium: CGFloat = 20
    
    /// Icon size (large)
    static let iconLarge: CGFloat = 24
    
    /// Icon size (extra large)
    static let iconXL: CGFloat = 32
    
    /// Icon size (2x large)
    static let iconXXL: CGFloat = 40
}

// MARK: - Spacing Modifiers

extension View {
    /// Apply compact padding
    func dojoCompactPadding() -> some View {
        self.padding(LeaderDojoSpacing.compact)
    }
    
    /// Apply comfortable padding
    func dojoComfortablePadding() -> some View {
        self.padding(LeaderDojoSpacing.comfortable)
    }
    
    /// Apply spacious padding
    func dojoSpaciousPadding() -> some View {
        self.padding(LeaderDojoSpacing.spacious)
    }
    
    /// Apply screen edge padding
    func dojoScreenEdges() -> some View {
        self.padding(LeaderDojoSpacing.screenEdges)
    }
    
    /// Apply card padding
    func dojoCardPadding() -> some View {
        self.padding(LeaderDojoSpacing.cardPadding)
    }
}

import SwiftUI

// MARK: - Card Styles

extension View {
    /// Legacy card style (deprecated - use dojoCard instead)
    @available(*, deprecated, message: "Use dojoCard() instead")
    func cardStyle() -> some View {
        self.dojoCard()
    }
    
    /// Standard elevated card with gradient background
    func dojoCard() -> some View {
        self
            .dojoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                LeaderDojoColors.dojoCharcoal,
                                LeaderDojoColors.surfaceTertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                LeaderDojoColors.dojoDarkGray.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.3),
                radius: LeaderDojoSpacing.shadowRadius,
                x: 0,
                y: LeaderDojoSpacing.shadowOffset.height
            )
    }
    
    /// Highlighted card with amber glow for priority items
    func dojoHighlightCard() -> some View {
        self
            .dojoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                LeaderDojoColors.dojoCharcoal,
                                LeaderDojoColors.surfaceTertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(
                        LeaderDojoColors.dojoAmber.opacity(0.5),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: LeaderDojoColors.dojoAmber.opacity(0.2),
                radius: 20,
                x: 0,
                y: 4
            )
            .shadow(
                color: Color.black.opacity(0.3),
                radius: LeaderDojoSpacing.shadowRadius,
                x: 0,
                y: LeaderDojoSpacing.shadowOffset.height
            )
    }
    
    /// Flat card with minimal styling for less important content
    func dojoFlatCard() -> some View {
        self
            .dojoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous)
                    .fill(LeaderDojoColors.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(LeaderDojoColors.dojoDarkGray, lineWidth: 0.5)
            )
    }
    
    /// Glass card with blur effect for overlays and modals
    func dojoGlassCard() -> some View {
        self
            .dojoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                    .fill(LeaderDojoColors.dojoCharcoal.opacity(0.8))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(
                        LeaderDojoColors.dojoDarkGray.opacity(0.5),
                        lineWidth: 1
                    )
            )
    }
    
    /// Card with colored left border (for status/priority indication)
    func dojoCardWithBorder(color: Color, width: CGFloat = 4) -> some View {
        self
            .dojoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                LeaderDojoColors.dojoCharcoal,
                                LeaderDojoColors.surfaceTertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous)
                        .fill(color)
                        .frame(width: width)
                    Spacer()
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous))
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Section Headers

extension View {
    /// Dojo section header with title and subtitle
    func dojoSectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
            Text(title)
                .dojoHeadingMedium()
            Text(subtitle)
                .dojoCaptionRegular()
        }
    }
}

// MARK: - Empty State

struct DojoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: LeaderDojoSpacing.l) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(LeaderDojoColors.textTertiary)
            
            VStack(spacing: LeaderDojoSpacing.s) {
                Text(title)
                    .dojoHeadingLarge()
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .dojoCaptionLarge()
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.dojoPrimary)
                    .frame(maxWidth: 280)
            }
        }
        .padding(LeaderDojoSpacing.xl)
    }
}

// MARK: - Loading State

struct DojoLoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: LeaderDojoSpacing.m) {
            ProgressView()
                .tint(LeaderDojoColors.dojoAmber)
                .scaleEffect(1.2)
            
            Text(message)
                .dojoCaptionLarge()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LeaderDojoColors.surfacePrimary)
    }
}

// MARK: - Error State

struct DojoErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: LeaderDojoSpacing.l) {
            Image(systemName: DojoIcons.error)
                .font(.system(size: 50))
                .foregroundStyle(LeaderDojoColors.dojoRed)
            
            Text(message)
                .dojoBodyLarge()
                .multilineTextAlignment(.center)
            
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.dojoSecondary)
                    .frame(maxWidth: 200)
            }
        }
        .padding(LeaderDojoSpacing.xl)
    }
}

// MARK: - Divider

extension View {
    /// Dojo-styled divider
    func dojoDivider() -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        LeaderDojoColors.dojoDarkGray,
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

import SwiftUI

/// Leader Dojo Button Styles
/// Premium button styles for consistent interactions

// MARK: - Primary Button Style

struct DojoPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LeaderDojoTypography.bodyLarge)
            .fontWeight(.semibold)
            .foregroundStyle(LeaderDojoColors.dojoBlack)
            .frame(maxWidth: .infinity)
            .frame(height: LeaderDojoSpacing.buttonHeight)
            .background(
                LinearGradient(
                    colors: [
                        LeaderDojoColors.dojoAmber,
                        LeaderDojoColors.dojoAmber.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous))
            .shadow(
                color: LeaderDojoColors.dojoAmber.opacity(0.3),
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(LeaderDojoAnimation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct DojoSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LeaderDojoTypography.bodyLarge)
            .fontWeight(.medium)
            .foregroundStyle(LeaderDojoColors.dojoAmber)
            .frame(maxWidth: .infinity)
            .frame(height: LeaderDojoSpacing.buttonHeight)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(LeaderDojoColors.dojoAmber, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(LeaderDojoAnimation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style

struct DojoGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LeaderDojoTypography.bodyMedium)
            .fontWeight(.medium)
            .foregroundStyle(LeaderDojoColors.textSecondary)
            .padding(.horizontal, LeaderDojoSpacing.m)
            .padding(.vertical, LeaderDojoSpacing.s)
            .background(
                configuration.isPressed ?
                    LeaderDojoColors.dojoDarkGray.opacity(0.5) :
                    Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusSmall, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(LeaderDojoAnimation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

struct DojoDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LeaderDojoTypography.bodyLarge)
            .fontWeight(.semibold)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: LeaderDojoSpacing.buttonHeight)
            .background(LeaderDojoColors.dojoRed)
            .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(LeaderDojoAnimation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Compact Button Style

struct DojoCompactButtonStyle: ButtonStyle {
    let color: Color
    @Environment(\.isEnabled) private var isEnabled
    
    init(color: Color = LeaderDojoColors.dojoAmber) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LeaderDojoTypography.captionLarge)
            .fontWeight(.semibold)
            .foregroundStyle(LeaderDojoColors.dojoBlack)
            .padding(.horizontal, LeaderDojoSpacing.m)
            .frame(height: LeaderDojoSpacing.buttonHeightCompact)
            .background(color)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(LeaderDojoAnimation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style

struct DojoIconButtonStyle: ButtonStyle {
    let size: CGFloat
    @Environment(\.isEnabled) private var isEnabled
    
    init(size: CGFloat = 44) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: LeaderDojoSpacing.iconMedium))
            .foregroundStyle(LeaderDojoColors.textPrimary)
            .frame(width: size, height: size)
            .background(
                configuration.isPressed ?
                    LeaderDojoColors.dojoDarkGray :
                    LeaderDojoColors.dojoCharcoal
            )
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(LeaderDojoAnimation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == DojoPrimaryButtonStyle {
    static var dojoPrimary: DojoPrimaryButtonStyle {
        DojoPrimaryButtonStyle()
    }
}

extension ButtonStyle where Self == DojoSecondaryButtonStyle {
    static var dojoSecondary: DojoSecondaryButtonStyle {
        DojoSecondaryButtonStyle()
    }
}

extension ButtonStyle where Self == DojoGhostButtonStyle {
    static var dojoGhost: DojoGhostButtonStyle {
        DojoGhostButtonStyle()
    }
}

extension ButtonStyle where Self == DojoDestructiveButtonStyle {
    static var dojoDestructive: DojoDestructiveButtonStyle {
        DojoDestructiveButtonStyle()
    }
}

extension ButtonStyle where Self == DojoCompactButtonStyle {
    static var dojoCompact: DojoCompactButtonStyle {
        DojoCompactButtonStyle()
    }
    
    static func dojoCompact(color: Color) -> DojoCompactButtonStyle {
        DojoCompactButtonStyle(color: color)
    }
}

extension ButtonStyle where Self == DojoIconButtonStyle {
    static var dojoIcon: DojoIconButtonStyle {
        DojoIconButtonStyle()
    }
    
    static func dojoIcon(size: CGFloat) -> DojoIconButtonStyle {
        DojoIconButtonStyle(size: size)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: LeaderDojoSpacing.l) {
        Button("Primary Button") {}
            .buttonStyle(.dojoPrimary)
        
        Button("Secondary Button") {}
            .buttonStyle(.dojoSecondary)
        
        Button("Ghost Button") {}
            .buttonStyle(.dojoGhost)
        
        Button("Destructive Button") {}
            .buttonStyle(.dojoDestructive)
        
        HStack(spacing: LeaderDojoSpacing.m) {
            Button("Compact") {}
                .buttonStyle(.dojoCompact)
            
            Button("Compact Blue") {}
                .buttonStyle(.dojoCompact(color: LeaderDojoColors.dojoBlue))
        }
        
        HStack(spacing: LeaderDojoSpacing.m) {
            Button {
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.dojoIcon)
            
            Button {
            } label: {
                Image(systemName: "heart.fill")
            }
            .buttonStyle(.dojoIcon)
        }
    }
    .padding(LeaderDojoSpacing.l)
    .background(LeaderDojoColors.dojoBlack)
}


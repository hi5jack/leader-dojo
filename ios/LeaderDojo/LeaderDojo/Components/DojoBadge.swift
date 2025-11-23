import SwiftUI

/// Leader Dojo Badge Component
/// Color-coded badges and tags for status, priority, and categories
struct DojoBadge: View {
    let text: String
    let style: BadgeStyle
    let size: BadgeSize
    let icon: String?
    
    init(
        _ text: String,
        style: BadgeStyle = .default,
        size: BadgeSize = .regular,
        icon: String? = nil
    ) {
        self.text = text
        self.style = style
        self.size = size
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: size.spacing) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize))
            }
            Text(text)
                .font(size.font)
                .textCase(size.textCase)
                .tracking(size.tracking)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .foregroundStyle(style.foregroundColor)
        .background(style.backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(style.borderColor, lineWidth: style.borderWidth)
        )
    }
}

// MARK: - Badge Style

extension DojoBadge {
    enum BadgeStyle {
        case `default`
        case priority(Int)
        case direction(String)
        case status(String)
        case type(String)
        case success
        case warning
        case error
        case info
        case custom(background: Color, foreground: Color, border: Color?)
        
        var backgroundColor: Color {
            switch self {
            case .default:
                return LeaderDojoColors.dojoDarkGray.opacity(0.5)
            case .priority(let level):
                return priorityColor(level).opacity(0.2)
            case .direction(let dir):
                return directionColor(dir).opacity(0.2)
            case .status(let status):
                return statusColor(status).opacity(0.2)
            case .type:
                return LeaderDojoColors.dojoBlue.opacity(0.2)
            case .success:
                return LeaderDojoColors.dojoGreen.opacity(0.2)
            case .warning:
                return LeaderDojoColors.dojoAmber.opacity(0.2)
            case .error:
                return LeaderDojoColors.dojoRed.opacity(0.2)
            case .info:
                return LeaderDojoColors.dojoBlue.opacity(0.2)
            case .custom(let bg, _, _):
                return bg
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .default:
                return LeaderDojoColors.textSecondary
            case .priority(let level):
                return priorityColor(level)
            case .direction(let dir):
                return directionColor(dir)
            case .status(let status):
                return statusColor(status)
            case .type:
                return LeaderDojoColors.dojoBlue
            case .success:
                return LeaderDojoColors.dojoGreen
            case .warning:
                return LeaderDojoColors.dojoAmber
            case .error:
                return LeaderDojoColors.dojoRed
            case .info:
                return LeaderDojoColors.dojoBlue
            case .custom(_, let fg, _):
                return fg
            }
        }
        
        var borderColor: Color {
            switch self {
            case .custom(_, _, let border):
                return border ?? .clear
            default:
                return .clear
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .custom(_, _, let border):
                return border != nil ? 1 : 0
            default:
                return 0
            }
        }
        
        private func statusColor(_ status: String) -> Color {
            switch status.lowercased() {
            case "done", "completed":
                return LeaderDojoColors.dojoGreen
            case "in_progress", "inprogress":
                return LeaderDojoColors.dojoAmber
            case "cancelled":
                return LeaderDojoColors.dojoRed
            default:
                return LeaderDojoColors.textSecondary
            }
        }
    }
}

// MARK: - Badge Size

extension DojoBadge {
    enum BadgeSize {
        case compact
        case regular
        case large
        
        var font: Font {
            switch self {
            case .compact:
                return LeaderDojoTypography.label
            case .regular:
                return LeaderDojoTypography.captionRegular
            case .large:
                return LeaderDojoTypography.captionLarge
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .compact:
                return LeaderDojoSpacing.s
            case .regular:
                return LeaderDojoSpacing.sm
            case .large:
                return LeaderDojoSpacing.m
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .compact:
                return LeaderDojoSpacing.xs
            case .regular:
                return LeaderDojoSpacing.xs
            case .large:
                return LeaderDojoSpacing.s
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .compact:
                return 10
            case .regular:
                return 12
            case .large:
                return 14
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .compact:
                return LeaderDojoSpacing.xs
            case .regular:
                return LeaderDojoSpacing.xs
            case .large:
                return LeaderDojoSpacing.s
            }
        }
        
        var textCase: Text.Case? {
            switch self {
            case .compact:
                return .uppercase
            case .regular, .large:
                return nil
            }
        }
        
        var tracking: CGFloat {
            switch self {
            case .compact:
                return 1.2
            case .regular, .large:
                return 0
            }
        }
    }
}

// MARK: - Convenience Initializers

extension DojoBadge {
    /// Create a priority badge
    static func priority(_ level: Int, size: BadgeSize = .regular) -> some View {
        let text = "Priority \(level)"
        return DojoBadge(text, style: .priority(level), size: size, icon: "flag.fill")
    }
    
    /// Create a direction badge (I Owe / Waiting For)
    static func direction(_ direction: String, size: BadgeSize = .regular) -> some View {
        let text = direction == "i_owe" ? "I Owe" : "Waiting For"
        let icon = direction == "i_owe" ? DojoIcons.iOwe : DojoIcons.waitingFor
        return DojoBadge(text, style: .direction(direction), size: size, icon: icon)
    }
    
    /// Create a status badge
    static func status(_ status: String, size: BadgeSize = .regular) -> some View {
        let text = status.replacingOccurrences(of: "_", with: " ").capitalized
        let icon = commitmentStatusIcon(status)
        return DojoBadge(text, style: .status(status), size: size, icon: icon)
    }
    
    /// Create a type badge
    static func type(_ type: String, size: BadgeSize = .regular) -> some View {
        let text = type.capitalized
        let icon = projectTypeIcon(type)
        return DojoBadge(text, style: .type(type), size: size, icon: icon)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: LeaderDojoSpacing.m) {
        // Sizes
        HStack(spacing: LeaderDojoSpacing.s) {
            DojoBadge("Compact", size: .compact)
            DojoBadge("Regular", size: .regular)
            DojoBadge("Large", size: .large)
        }
        
        // Styles
        VStack(spacing: LeaderDojoSpacing.s) {
            DojoBadge.priority(5)
            DojoBadge.priority(3)
            DojoBadge.direction("i_owe")
            DojoBadge.direction("waiting_for")
            DojoBadge.status("done")
            DojoBadge.status("in_progress")
            DojoBadge.type("startup")
        }
    }
    .padding()
    .background(LeaderDojoColors.dojoBlack)
}




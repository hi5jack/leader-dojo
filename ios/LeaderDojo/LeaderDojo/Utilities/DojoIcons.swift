import SwiftUI

/// Leader Dojo Icon System
/// Semantic SF Symbol mappings for consistent iconography
enum DojoIcons {
    // MARK: - Navigation & Structure
    
    static let dashboard = "house.fill"
    static let projects = "folder.fill"
    static let commitments = "checkmark.circle.fill"
    static let reflections = "book.pages.fill"
    static let capture = "plus.circle.fill"
    
    // MARK: - Entry Types
    
    static let meeting = "person.2.fill"
    static let update = "arrow.up.circle.fill"
    static let selfNote = "note.text"
    static let decision = "diamond.fill"
    static let other = "doc.text.fill"
    
    // MARK: - Commitment Directions
    
    static let iOwe = "arrow.forward.circle.fill"
    static let waitingFor = "arrow.backward.circle.fill"
    
    // MARK: - Status Indicators
    
    static let statusOpen = "circle"
    static let statusInProgress = "circle.lefthalf.filled"
    static let statusDone = "checkmark.circle.fill"
    static let statusCancelled = "xmark.circle.fill"
    
    // MARK: - Project Types
    
    static let startup = "lightbulb.fill"
    static let internalOrg = "building.2.fill"
    static let client = "person.crop.circle.fill"
    static let investment = "dollarsign.circle.fill"
    
    // MARK: - Priority & Importance
    
    static let priorityHigh = "exclamationmark.3"
    static let priorityMedium = "exclamationmark.2"
    static let priorityLow = "exclamationmark"
    static let star = "star.fill"
    static let starOutline = "star"
    
    // MARK: - Actions
    
    static let add = "plus"
    static let edit = "pencil"
    static let delete = "trash.fill"
    static let refresh = "arrow.clockwise"
    static let filter = "line.3.horizontal.decrease.circle"
    static let search = "magnifyingglass"
    static let sort = "arrow.up.arrow.down"
    static let share = "square.and.arrow.up"
    static let more = "ellipsis.circle.fill"
    
    // MARK: - Time & Calendar
    
    static let calendar = "calendar"
    static let clock = "clock.fill"
    static let overdue = "clock.badge.exclamationmark.fill"
    static let today = "star.circle.fill"
    
    // MARK: - Communication
    
    static let chat = "bubble.left.and.bubble.right.fill"
    static let email = "envelope.fill"
    static let call = "phone.fill"
    
    // MARK: - Feedback & States
    
    static let success = "checkmark.circle.fill"
    static let error = "exclamationmark.triangle.fill"
    static let warning = "exclamationmark.circle.fill"
    static let info = "info.circle.fill"
    
    // MARK: - Empty States
    
    static let emptyBox = "tray.fill"
    static let emptySearch = "magnifyingglass.circle"
    static let emptyProjects = "folder.badge.plus"
    static let emptyCommitments = "checkmark.circle.badge.xmark"
    
    // MARK: - Contextual Actions
    
    static let prep = "doc.text.magnifyingglass"
    static let reconnect = "arrow.triangle.2.circlepath"
    static let archive = "archivebox.fill"
    static let bookmark = "bookmark.fill"
    
    // MARK: - Growth & Reflection
    
    static let insight = "lightbulb.max.fill"
    static let growth = "chart.line.uptrend.xyaxis"
    static let pattern = "sparkles"
}

// MARK: - Icon Style Modifiers

extension View {
    /// Apply dojo icon style (size + color)
    func dojoIconStyle(size: CGFloat = LeaderDojoSpacing.iconMedium, color: Color = LeaderDojoColors.textSecondary) -> some View {
        self
            .font(.system(size: size))
            .foregroundStyle(color)
    }
    
    /// Apply small icon style
    func dojoIconSmall(color: Color = LeaderDojoColors.textSecondary) -> some View {
        self.dojoIconStyle(size: LeaderDojoSpacing.iconSmall, color: color)
    }
    
    /// Apply medium icon style
    func dojoIconMedium(color: Color = LeaderDojoColors.textSecondary) -> some View {
        self.dojoIconStyle(size: LeaderDojoSpacing.iconMedium, color: color)
    }
    
    /// Apply large icon style
    func dojoIconLarge(color: Color = LeaderDojoColors.textPrimary) -> some View {
        self.dojoIconStyle(size: LeaderDojoSpacing.iconLarge, color: color)
    }
    
    /// Apply extra large icon style
    func dojoIconXL(color: Color = LeaderDojoColors.textPrimary) -> some View {
        self.dojoIconStyle(size: LeaderDojoSpacing.iconXL, color: color)
    }
    
    /// Apply double extra large icon style (hero moments)
    func dojoIconXXL(color: Color = LeaderDojoColors.textPrimary) -> some View {
        self.dojoIconStyle(size: LeaderDojoSpacing.iconXXL, color: color)
    }
}

// MARK: - Icon Components

/// Icon for entry kind
func entryKindIcon(_ kind: String) -> String {
    switch kind.lowercased() {
    case "meeting":
        return DojoIcons.meeting
    case "update":
        return DojoIcons.update
    case "note":
        return DojoIcons.selfNote
    case "decision":
        return DojoIcons.decision
    default:
        return DojoIcons.other
    }
}

/// Icon for project type
func projectTypeIcon(_ type: String) -> String {
    switch type.lowercased() {
    case "startup":
        return DojoIcons.startup
    case "internal":
        return DojoIcons.internalOrg
    case "client":
        return DojoIcons.client
    case "investment":
        return DojoIcons.investment
    default:
        return DojoIcons.projects
    }
}

/// Icon for commitment status
func commitmentStatusIcon(_ status: String) -> String {
    switch status.lowercased() {
    case "open":
        return DojoIcons.statusOpen
    case "in_progress", "inprogress":
        return DojoIcons.statusInProgress
    case "done", "completed":
        return DojoIcons.statusDone
    case "cancelled":
        return DojoIcons.statusCancelled
    default:
        return DojoIcons.statusOpen
    }
}

/// Color for priority level
func priorityColor(_ priority: Int) -> Color {
    switch priority {
    case 5:
        return LeaderDojoColors.dojoRed
    case 4:
        return LeaderDojoColors.dojoAmber
    case 3:
        return LeaderDojoColors.dojoBlue
    case 2:
        return LeaderDojoColors.dojoMediumGray
    case 1:
        return LeaderDojoColors.dojoLightGray
    default:
        return LeaderDojoColors.textSecondary
    }
}

/// Color for commitment direction
func directionColor(_ direction: String) -> Color {
    switch direction.lowercased() {
    case "i_owe", "iowe":
        return LeaderDojoColors.dojoAmber
    case "waiting_for", "waitingfor":
        return LeaderDojoColors.dojoBlue
    default:
        return LeaderDojoColors.textSecondary
    }
}


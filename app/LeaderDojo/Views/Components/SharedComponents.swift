import SwiftUI

// MARK: - Badge

/// A small capsule badge with an icon and text
struct Badge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - Section Header

/// A styled section header with icon
struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(color)
    }
}

// MARK: - Empty State Card

/// A card shown when a section has no content
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Action Button

/// A quick action button for project detail views
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 72)
            .padding(.vertical, 12)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Commitment Row

/// A compact commitment row for inline display with optional toggle action
struct MiniCommitmentRow: View {
    let commitment: Commitment
    var onToggle: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            // Toggle button
            if let onToggle = onToggle {
                Button(action: onToggle) {
                    Image(systemName: commitment.status == .done ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(commitment.status == .done ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(commitment.title)
                .font(.caption)
                .lineLimit(1)
                .strikethrough(commitment.status == .done)
                .foregroundStyle(commitment.status == .done ? .secondary : .primary)
            
            Spacer()
            
            // Person indicator
            if let person = commitment.person {
                Text(person.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            if let due = commitment.dueDate {
                Text(due, style: .date)
                    .font(.caption2)
                    .foregroundStyle(commitment.isOverdue ? .red : .secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Participant Avatars Row

/// A horizontal row of participant avatar circles for displaying people in entries
struct ParticipantAvatarsRow: View {
    let participants: [Person]
    var maxDisplay: Int = 3
    var size: CGFloat = 24
    
    var body: some View {
        if participants.isEmpty { 
            EmptyView()
        } else {
            HStack(spacing: -6) {
                ForEach(Array(participants.prefix(maxDisplay).enumerated()), id: \.element.id) { index, person in
                    PersonAvatarCircle(person: person, size: size)
                        .zIndex(Double(maxDisplay - index))
                }
                
                if participants.count > maxDisplay {
                    Text("+\(participants.count - maxDisplay)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Circle().fill(.secondary.opacity(0.15)))
                }
            }
        }
    }
}

// MARK: - Entry Row View

/// A row displaying an entry in a list
struct EntryRowView: View {
    let entry: Entry
    
    private var participants: [Person] {
        entry.participants ?? []
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Kind icon with decision indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: entry.kind.icon)
                    .font(.title3)
                    .foregroundStyle(kindColor)
                    .frame(width: 32)
                
                // Decision badge overlay
                if entry.isDecisionEntry && entry.kind != .decision {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.purple)
                        .offset(x: 4, y: 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Decision outcome badge
                    if entry.isDecisionEntry {
                        decisionStatusBadge
                    }
                }
                
                if !entry.displayContent.isEmpty {
                    Text(entry.displayContent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    Text(entry.occurredAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    // Participants avatars
                    if !participants.isEmpty {
                        ParticipantAvatarsRow(participants: participants, maxDisplay: 3, size: 18)
                    }
                    
                    // Review indicator for decisions
                    if entry.needsDecisionReview {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text("Needs review")
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var decisionStatusBadge: some View {
        if let outcome = entry.decisionOutcome, outcome != .pending {
            HStack(spacing: 2) {
                Image(systemName: outcome.icon)
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(outcomeColor(outcome).opacity(0.2), in: Capsule())
            .foregroundStyle(outcomeColor(outcome))
        }
    }
    
    private var kindColor: Color {
        switch entry.kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        }
    }
    
    private func outcomeColor(_ outcome: DecisionOutcome) -> Color {
        switch outcome {
        case .pending: return .gray
        case .validated: return .green
        case .invalidated: return .red
        case .mixed: return .yellow
        case .superseded: return .blue
        }
    }
}

// MARK: - macOS Components

#if os(macOS)
/// A styled text editor for macOS with placeholder support
struct MacTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(4)
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}

/// A styled card container for macOS forms
struct MacFormCard<Content: View>: View {
    let title: String?
    let icon: String?
    let iconColor: Color
    @ViewBuilder let content: () -> Content
    
    init(
        title: String? = nil,
        icon: String? = nil,
        iconColor: Color = .secondary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                if let icon = icon {
                    Label(title, systemImage: icon)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(iconColor)
                } else {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(iconColor)
                }
            }
            
            content()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

/// Styled form field for macOS
struct MacFormField: View {
    let label: String
    
    var body: some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
#endif

// MARK: - Commitment Balance Indicator

/// Visual indicator showing the balance between I Owe and Waiting For commitments
struct CommitmentBalanceIndicator: View {
    let iOweCount: Int
    let waitingForCount: Int
    var showLabels: Bool = true
    var compact: Bool = false
    
    private var balance: Double {
        let total = Double(iOweCount + waitingForCount)
        guard total > 0 else { return 0 }
        return Double(waitingForCount - iOweCount) / total
    }
    
    private var balanceText: String {
        if abs(balance) < 0.2 { return "Balanced" }
        return balance > 0 ? "They owe more" : "You owe more"
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }
    
    private var compactView: some View {
        HStack(spacing: 4) {
            // I Owe indicator
            HStack(spacing: 2) {
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                Text("\(iOweCount)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.orange)
            
            Text("/")
                .foregroundStyle(.secondary)
                .font(.caption)
            
            // Waiting For indicator
            HStack(spacing: 2) {
                Text("\(waitingForCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "arrow.down.left")
                    .font(.caption2)
            }
            .foregroundStyle(.blue)
        }
    }
    
    private var fullView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Balance bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // I Owe portion
                    let total = iOweCount + waitingForCount
                    let iOweWidth = total > 0 ? CGFloat(iOweCount) / CGFloat(total) : 0.5
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * iOweWidth)
                    
                    // Waiting For portion
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * (1 - iOweWidth))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 8)
            
            if showLabels {
                // Legend
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange).frame(width: 6, height: 6)
                        Text("I Owe: \(iOweCount)")
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    Text(balanceText)
                        .font(.caption2)
                        .foregroundStyle(abs(balance) > 0.5 ? .yellow : .green)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Waiting: \(waitingForCount)")
                            .font(.caption2)
                        Circle().fill(Color.blue).frame(width: 6, height: 6)
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Relationship Health Badge

/// A badge showing relationship health status with color coding
struct RelationshipHealthBadge: View {
    let status: RelationshipHealthStatus
    var showLabel: Bool = true
    var size: BadgeSize = .regular
    
    enum BadgeSize {
        case small, regular, large
        
        var iconFont: Font {
            switch self {
            case .small: return .caption2
            case .regular: return .caption
            case .large: return .body
            }
        }
        
        var textFont: Font {
            switch self {
            case .small: return .caption2
            case .regular: return .caption
            case .large: return .subheadline
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .regular: return 6
            case .large: return 8
            }
        }
    }
    
    private var color: Color {
        switch status {
        case .healthy: return .green
        case .needsAttention: return .yellow
        case .atRisk: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(size.iconFont)
            
            if showLabel {
                Text(status.displayName)
                    .font(size.textFont)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, size.padding * 1.5)
        .padding(.vertical, size.padding)
        .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Person Avatar Circle

/// A circular avatar with initials for a person
struct PersonAvatarCircle: View {
    let person: Person
    var size: CGFloat = 32
    var showHealthIndicator: Bool = false
    
    private var initials: String {
        let components = person.name.components(separatedBy: " ")
        return components.prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
    }
    
    private var avatarColor: Color {
        switch person.relationshipType?.groupName {
        case "Internal": return .blue
        case "Investment & Advisory": return .purple
        case "External": return .green
        default: return .gray
        }
    }
    
    private var healthColor: Color {
        switch person.healthStatus {
        case .healthy: return .green
        case .needsAttention: return .yellow
        case .atRisk: return .red
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.2))
                    .frame(width: size, height: size)
                
                Text(initials)
                    .font(.system(size: size * 0.4))
                    .fontWeight(.semibold)
                    .foregroundStyle(avatarColor)
            }
            
            if showHealthIndicator {
                Circle()
                    .fill(healthColor)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 1.5)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - Previews

#Preview("Badge") {
    HStack {
        Badge(text: "Active", icon: "checkmark.circle.fill", color: .green)
        Badge(text: "Meeting", icon: "person.2.fill", color: .blue)
        Badge(text: "P3", icon: "flag.fill", color: .orange)
    }
    .padding()
}

#Preview("Section Header") {
    SectionHeader(title: "Commitments", icon: "checklist", color: .indigo)
        .padding()
}

#Preview("Empty State Card") {
    EmptyStateCard(
        icon: "doc.text",
        title: "No Entries",
        message: "Start by adding your first entry."
    )
    .padding()
}




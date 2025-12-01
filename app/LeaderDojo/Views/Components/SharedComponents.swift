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
            .frame(maxWidth: .infinity)
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

// MARK: - Entry Row View

/// A row displaying an entry in a list
struct EntryRowView: View {
    let entry: Entry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Kind icon
            Image(systemName: entry.kind.icon)
                .font(.title3)
                .foregroundStyle(kindColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !entry.displayContent.isEmpty {
                    Text(entry.displayContent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Text(entry.occurredAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var kindColor: Color {
        switch entry.kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note, ._legacyCommitment: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
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




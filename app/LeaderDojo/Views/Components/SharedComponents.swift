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

/// A compact commitment row for inline display
struct MiniCommitmentRow: View {
    let commitment: Commitment
    
    var body: some View {
        HStack {
            Text(commitment.title)
                .font(.caption)
                .lineLimit(1)
            
            Spacer()
            
            if let due = commitment.dueDate {
                Text(due, style: .date)
                    .font(.caption2)
                    .foregroundStyle(commitment.isOverdue ? .red : .secondary)
            }
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
        case .note: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        case .commitment: return .indigo
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



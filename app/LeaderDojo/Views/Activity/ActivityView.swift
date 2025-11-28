import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Entry.occurredAt, order: .reverse) private var allEntries: [Entry]
    @Query(sort: \Project.name) private var projects: [Project]
    
    @State private var selectedProjectId: UUID?
    @State private var selectedKind: EntryKind?
    
    /// Entry kinds available for filtering (excludes commitment)
    private let filterableKinds: [EntryKind] = [.meeting, .update, .decision, .note, .prep, .reflection]
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
            .navigationTitle("Activity")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
    
    // MARK: - Filtered Entries
    
    private var filteredEntries: [Entry] {
        allEntries.filter { entry in
            // Exclude soft-deleted entries
            guard !entry.isDeleted else { return false }
            
            // Exclude commitment-type entries (matching web behavior)
            guard entry.kind != .commitment else { return false }
            
            // Filter by project if selected
            if let projectId = selectedProjectId {
                guard entry.project?.id == projectId else { return false }
            }
            
            // Filter by kind if selected
            if let kind = selectedKind {
                guard entry.kind == kind else { return false }
            }
            
            return true
        }
    }
    
    private var hasFilters: Bool {
        selectedProjectId != nil || selectedKind != nil
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            filterBar
            
            Spacer()
            
            ContentUnavailableView {
                Label(
                    hasFilters ? "No Matching Entries" : "No Activity Yet",
                    systemImage: hasFilters ? "line.3.horizontal.decrease.circle" : "clock.arrow.circlepath"
                )
            } description: {
                Text(hasFilters
                    ? "Try adjusting your filters or clear them to see all entries."
                    : "Start by creating a project and adding your first entry."
                )
            } actions: {
                if hasFilters {
                    Button("Clear Filters") {
                        clearFilters()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Activity List
    
    private var activityList: some View {
        List {
            // Filter section
            Section {
                filterBar
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Grouped entries by date
            ForEach(groupedEntries, id: \.0) { dateGroup, entries in
                Section {
                    ForEach(entries) { entry in
                        NavigationLink {
                            EntryDetailView(entry: entry)
                        } label: {
                            ActivityEntryRowView(entry: entry)
                        }
                    }
                } header: {
                    Text(dateGroup)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Project filter
                Menu {
                    Button("All Projects") {
                        selectedProjectId = nil
                    }
                    Divider()
                    ForEach(projects) { project in
                        Button(project.name) {
                            selectedProjectId = project.id
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text(selectedProjectName)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                
                // Kind filter
                Menu {
                    Button("All Types") {
                        selectedKind = nil
                    }
                    Divider()
                    ForEach(filterableKinds, id: \.self) { kind in
                        Button {
                            selectedKind = kind
                        } label: {
                            Label(kind.displayName, systemImage: kind.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "tag")
                        Text(selectedKind?.displayName ?? "All Types")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                
                Spacer()
                
                // Clear filters button
                if hasFilters {
                    Button {
                        clearFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Entry count
            HStack {
                Spacer()
                Text("\(filteredEntries.count) \(filteredEntries.count == 1 ? "entry" : "entries")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var selectedProjectName: String {
        if let projectId = selectedProjectId,
           let project = projects.first(where: { $0.id == projectId }) {
            return project.name
        }
        return "All Projects"
    }
    
    // MARK: - Date Grouping
    
    private var groupedEntries: [(String, [Entry])] {
        let grouped = Dictionary(grouping: filteredEntries) { entry -> String in
            getDateGroup(for: entry.occurredAt)
        }
        
        // Sort groups: Today, Yesterday, This Week, then by date descending
        let sortOrder = ["Today", "Yesterday", "This Week"]
        
        return grouped.sorted { lhs, rhs in
            let lhsIndex = sortOrder.firstIndex(of: lhs.key)
            let rhsIndex = sortOrder.firstIndex(of: rhs.key)
            
            if let li = lhsIndex, let ri = rhsIndex {
                return li < ri
            } else if lhsIndex != nil {
                return true
            } else if rhsIndex != nil {
                return false
            } else {
                // Both are specific dates, sort descending
                return lhs.key > rhs.key
            }
        }
    }
    
    private func getDateGroup(for date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if isDateInThisWeek(date) {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func isDateInThisWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }
        
        return date >= weekStart && date < weekEnd
    }
    
    // MARK: - Actions
    
    private func clearFilters() {
        withAnimation {
            selectedProjectId = nil
            selectedKind = nil
        }
    }
}

// MARK: - Activity Entry Row View

struct ActivityEntryRowView: View {
    let entry: Entry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Kind icon with color
            Image(systemName: entry.kind.icon)
                .font(.title3)
                .foregroundStyle(kindColor)
                .frame(width: 32, height: 32)
                .background(kindColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                // Project badge and type
                HStack(spacing: 8) {
                    if let project = entry.project {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.caption2)
                            Text(project.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(.secondary)
                    }
                    
                    Text(entry.kind.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Content preview
                if !entry.displayContent.isEmpty {
                    Text(entry.displayContent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Time
            Text(entry.occurredAt, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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

#Preview {
    ActivityView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}



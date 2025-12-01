import SwiftUI
import SwiftData

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Entry.occurredAt, order: .reverse) private var allEntries: [Entry]
    @Query(sort: \Project.name) private var projects: [Project]
    
    @State private var selectedProjectId: UUID?
    @State private var selectedKind: EntryKind?
    @State private var searchText: String = ""
    @State private var selectedEntry: Entry? = nil
    
    /// Entry kinds available for filtering (excludes commitment)
    private let filterableKinds: [EntryKind] = [.meeting, .update, .decision, .note, .prep, .reflection]
    
    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadLayout
        } else {
            iPhoneLayout
        }
        #else
        macLayout
        #endif
    }
    
    // MARK: - iPhone Layout
    
    #if os(iOS)
    private var iPhoneLayout: some View {
        NavigationStack {
            activityContent
        }
    }
    
    private var activityContent: some View {
        Group {
            if filteredEntries.isEmpty {
                emptyState
            } else {
                activityList
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search entries")
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                filterMenu
            }
        }
    }
    
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
        .listStyle(.insetGrouped)
    }
    #endif
    
    // MARK: - iPad Layout
    
    #if os(iOS)
    private var iPadLayout: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filter bar
                iPadFilterBar
                
                // Timeline list
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    iPadActivityList
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
        } detail: {
            if let entry = selectedEntry {
                EntryDetailView(entry: entry)
            } else {
                ContentUnavailableView {
                    Label("Select an Entry", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Choose an entry from the timeline to view its details.")
                }
            }
        }
    }
    
    private var iPadFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Project filter
                Menu {
                    Button("All Projects") { selectedProjectId = nil }
                    Divider()
                    ForEach(projects) { project in
                        Button(project.name) { selectedProjectId = project.id }
                    }
                } label: {
                    FilterChip(
                        title: selectedProjectName,
                        icon: "folder",
                        isActive: selectedProjectId != nil
                    )
                }
                
                // Type filter
                Menu {
                    Button("All Types") { selectedKind = nil }
                    Divider()
                    ForEach(filterableKinds, id: \.self) { kind in
                        Button {
                            selectedKind = kind
                        } label: {
                            Label(kind.displayName, systemImage: kind.icon)
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedKind?.displayName ?? "All Types",
                        icon: selectedKind?.icon ?? "tag",
                        isActive: selectedKind != nil
                    )
                }
                
                if hasFilters {
                    Button {
                        clearFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }
    
    private var iPadActivityList: some View {
        List(selection: $selectedEntry) {
            ForEach(groupedEntries, id: \.0) { dateGroup, entries in
                Section {
                    ForEach(entries) { entry in
                        iPadTimelineRow(entry: entry)
                            .tag(entry)
                    }
                } header: {
                    HStack {
                        Text(dateGroup)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(entries.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func iPadTimelineRow(entry: Entry) -> some View {
        HStack(spacing: 12) {
            // Timeline dot
            ZStack {
                Circle()
                    .fill(kindColor(for: entry.kind).opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: entry.kind.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(kindColor(for: entry.kind))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let project = entry.project {
                        Text(project.name)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    Text(entry.kind.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(entry.occurredAt, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macLayout: some View {
        HSplitView {
            // Left: Timeline
            VStack(spacing: 0) {
                macToolbar
                
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    macTimelineView
                }
            }
            .frame(minWidth: 380)
            
            // Right: Detail
            Group {
                if let entry = selectedEntry {
                    ScrollView {
                        EntryDetailView(entry: entry)
                    }
                } else {
                    macEmptyDetailView
                }
            }
            .frame(minWidth: 400, idealWidth: 500)
        }
        .navigationTitle("Activity")
    }
    
    private var macToolbar: some View {
        VStack(spacing: 0) {
            // Search and filters
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search entries...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 220)
                
                // Project filter
                Menu {
                    Button("All Projects") { selectedProjectId = nil }
                    Divider()
                    ForEach(projects) { project in
                        Button(project.name) { selectedProjectId = project.id }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text(selectedProjectName)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedProjectId != nil ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor), in: Capsule())
                }
                .buttonStyle(.plain)
                
                // Type filter
                Menu {
                    Button("All Types") { selectedKind = nil }
                    Divider()
                    ForEach(filterableKinds, id: \.self) { kind in
                        Button {
                            selectedKind = kind
                        } label: {
                            Label(kind.displayName, systemImage: kind.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedKind?.icon ?? "tag")
                        Text(selectedKind?.displayName ?? "All Types")
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedKind != nil ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor), in: Capsule())
                }
                .buttonStyle(.plain)
                
                if hasFilters {
                    Button {
                        clearFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Entry count
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(.bar)
    }
    
    private var macTimelineView: some View {
        List(selection: $selectedEntry) {
            ForEach(groupedEntries, id: \.0) { dateGroup, entries in
                Section {
                    ForEach(entries) { entry in
                        MacTimelineRow(entry: entry)
                            .tag(entry)
                            .contextMenu {
                                entryContextMenu(for: entry)
                            }
                    }
                } header: {
                    HStack {
                        Text(dateGroup)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(entries.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2), in: Capsule())
                    }
                }
            }
        }
        .listStyle(.inset)
    }
    
    private var macEmptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("Select an Entry")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Choose an entry from the timeline to view and edit its details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    @ViewBuilder
    private func entryContextMenu(for entry: Entry) -> some View {
        Button {
            // Edit action would go here
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            entry.softDelete()
            if selectedEntry?.id == entry.id {
                selectedEntry = nil
            }
            try? modelContext.save()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    #endif
    
    // MARK: - Shared Components
    
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
    
    private var filterMenu: some View {
        Menu {
            Section("Project") {
                Button("All Projects") { selectedProjectId = nil }
                ForEach(projects) { project in
                    Button(project.name) { selectedProjectId = project.id }
                }
            }
            
            Section("Type") {
                Button("All Types") { selectedKind = nil }
                ForEach(filterableKinds, id: \.self) { kind in
                    Button {
                        selectedKind = kind
                    } label: {
                        Label(kind.displayName, systemImage: kind.icon)
                    }
                }
            }
            
            if hasFilters {
                Divider()
                Button("Clear Filters") { clearFilters() }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            if hasFilters {
                filterBar
            }
            
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
    
    // MARK: - Filtered Entries
    
    private var filteredEntries: [Entry] {
        allEntries.filter { entry in
            // Exclude soft-deleted entries
            guard !entry.isDeleted else { return false }
            
            // Filter by project if selected
            if let projectId = selectedProjectId {
                guard entry.project?.id == projectId else { return false }
            }
            
            // Filter by kind if selected
            if let kind = selectedKind {
                guard entry.kind == kind else { return false }
            }
            
            // Search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let titleMatch = entry.title.lowercased().contains(searchLower)
                let contentMatch = entry.rawContent?.lowercased().contains(searchLower) ?? false
                let summaryMatch = entry.aiSummary?.lowercased().contains(searchLower) ?? false
                guard titleMatch || contentMatch || summaryMatch else { return false }
            }
            
            return true
        }
    }
    
    private var hasFilters: Bool {
        selectedProjectId != nil || selectedKind != nil
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
    
    private func kindColor(for kind: EntryKind) -> Color {
        switch kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        }
    }
    
    // MARK: - Actions
    
    private func clearFilters() {
        withAnimation {
            selectedProjectId = nil
            selectedKind = nil
        }
    }
}

// MARK: - Activity Entry Row View (iPhone)

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
        }
    }
}

// MARK: - Mac Timeline Row

#if os(macOS)
struct MacTimelineRow: View {
    let entry: Entry
    
    var body: some View {
        HStack(spacing: 12) {
            // Timeline indicator with connecting line effect
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(kindColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: entry.kind.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(kindColor)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if entry.isDecision {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
                
                HStack(spacing: 8) {
                    // Type badge
                    Text(entry.kind.displayName)
                        .font(.caption)
                        .foregroundStyle(kindColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(kindColor.opacity(0.1), in: Capsule())
                    
                    // Project badge
                    if let project = entry.project {
                        HStack(spacing: 3) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 9))
                            Text(project.name)
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: Capsule())
                    }
                    
                    Spacer()
                }
                
                // Content preview
                if !entry.displayContent.isEmpty {
                    Text(entry.displayContent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Time and indicators
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.occurredAt, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                if let commitments = entry.commitments, !commitments.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "checklist")
                            .font(.caption2)
                        Text("\(commitments.count)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 8)
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
}
#endif

#Preview {
    ActivityView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}

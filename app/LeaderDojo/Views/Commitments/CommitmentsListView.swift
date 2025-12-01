import SwiftUI
import SwiftData

// MARK: - View Mode
enum CommitmentsViewMode: String, CaseIterable {
    case list = "List"
    case board = "Board"
    
    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .board: return "rectangle.split.3x1"
        }
    }
}

struct CommitmentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Commitment.dueDate) private var commitments: [Commitment]
    
    @State private var selectedDirection: CommitmentDirection = .iOwe
    @State private var selectedStatus: CommitmentStatus? = .open
    @State private var selectedProject: Project? = nil
    @State private var showingNewCommitment: Bool = false
    @State private var sortOrder: SortOrder = .dueDate
    @State private var viewMode: CommitmentsViewMode = .list
    @State private var selectedCommitment: Commitment? = nil
    @State private var searchText: String = ""
    
    @Query
    private var allProjects: [Project]
    
    private var activeProjects: [Project] {
        allProjects.filter { $0.status == .active }
    }
    
    enum SortOrder: String, CaseIterable {
        case dueDate = "Due Date"
        case importance = "Importance"
        case project = "Project"
        case person = "Person"
        case created = "Created"
        
        var icon: String {
            switch self {
            case .dueDate: return "calendar"
            case .importance: return "flag.fill"
            case .project: return "folder"
            case .person: return "person.2"
            case .created: return "clock"
            }
        }
    }
    
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
            VStack(spacing: 0) {
                directionTabs
                
                if filteredCommitments.isEmpty {
                    emptyState
                } else {
                    iPhoneCommitmentsList
                }
            }
            .navigationTitle("Commitments")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search commitments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewCommitment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showingNewCommitment) {
                NewCommitmentView(project: nil, person: nil, sourceEntry: nil, preselectedDirection: selectedDirection)
            }
        }
    }
    
    private var iPhoneCommitmentsList: some View {
        List {
            ForEach(groupedCommitments, id: \.0) { group, items in
                Section(group) {
                    ForEach(items) { commitment in
                        NavigationLink {
                            CommitmentDetailView(commitment: commitment)
                        } label: {
                            CommitmentRowView(commitment: commitment) {
                                toggleStatus(commitment)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                toggleStatus(commitment)
                            } label: {
                                Label(
                                    commitment.status == .done ? "Reopen" : "Done",
                                    systemImage: commitment.status == .done ? "arrow.uturn.backward" : "checkmark"
                                )
                            }
                            .tint(commitment.status == .done ? .orange : .green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteCommitment(commitment)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
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
                // Direction selector
                directionTabs
                
                // Filter bar
                iPadFilterBar
                
                // List
                if filteredCommitments.isEmpty {
                    emptyState
                } else {
                    iPadCommitmentsList
                }
            }
            .navigationTitle("Commitments")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewCommitment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            if let commitment = selectedCommitment {
                CommitmentDetailView(commitment: commitment)
            } else {
                ContentUnavailableView {
                    Label("Select a Commitment", systemImage: "checklist")
                } description: {
                    Text("Choose a commitment from the list to view its details.")
                }
            }
        }
        .sheet(isPresented: $showingNewCommitment) {
            NewCommitmentView(project: nil, person: nil, sourceEntry: nil, preselectedDirection: selectedDirection)
        }
    }
    
    private var iPadFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Status filter chips
                FilterChip(
                    title: selectedStatus?.displayName ?? "All Status",
                    icon: selectedStatus?.icon ?? "circle.grid.2x2",
                    isActive: selectedStatus != nil
                ) {
                    // Cycle through statuses
                    if selectedStatus == nil {
                        selectedStatus = .open
                    } else if selectedStatus == .open {
                        selectedStatus = .done
                    } else {
                        selectedStatus = nil
                    }
                }
                
                // Project filter
                Menu {
                    Button("All Projects") { selectedProject = nil }
                    Divider()
                    ForEach(activeProjects) { project in
                        Button(project.name) { selectedProject = project }
                    }
                } label: {
                    FilterChip(
                        title: selectedProject?.name ?? "All Projects",
                        icon: "folder",
                        isActive: selectedProject != nil
                    )
                }
                
                // Sort order
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : order.icon)
                        }
                    }
                } label: {
                    FilterChip(
                        title: "Sort: \(sortOrder.rawValue)",
                        icon: "arrow.up.arrow.down",
                        isActive: false
                    )
                }
                
                Spacer()
                
                // Count badge
                Text("\(filteredCommitments.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
    
    private var iPadCommitmentsList: some View {
        List(selection: $selectedCommitment) {
            ForEach(groupedCommitments, id: \.0) { group, items in
                Section {
                    ForEach(items) { commitment in
                        CommitmentRowView(commitment: commitment) {
                            toggleStatus(commitment)
                        }
                        .tag(commitment)
                        .contextMenu {
                            commitmentContextMenu(for: commitment)
                        }
                    }
                } header: {
                    HStack {
                        Text(group)
                        Spacer()
                        Text("\(items.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macLayout: some View {
        HSplitView {
            // Left: List/Board View
            VStack(spacing: 0) {
                macToolbar
                
                if viewMode == .board {
                    macBoardView
                } else {
                    macListView
                }
            }
            .frame(minWidth: 400)
            
            // Right: Detail View
            Group {
                if let commitment = selectedCommitment {
                    ScrollView {
                        CommitmentDetailView(commitment: commitment)
                    }
                } else {
                    macEmptyDetailView
                }
            }
            .frame(minWidth: 350, idealWidth: 450)
        }
        .navigationTitle("Commitments")
        .sheet(isPresented: $showingNewCommitment) {
            NewCommitmentView(project: nil, person: nil, sourceEntry: nil, preselectedDirection: selectedDirection)
        }
        .onDeleteCommand {
            if let commitment = selectedCommitment {
                deleteCommitment(commitment)
            }
        }
    }
    
    private var macToolbar: some View {
        VStack(spacing: 0) {
            // Direction tabs + view mode
            HStack(spacing: 16) {
                // Direction Picker
                Picker("Direction", selection: $selectedDirection) {
                    ForEach(CommitmentDirection.allCases, id: \.self) { direction in
                        Label(direction.displayName, systemImage: direction.icon)
                            .tag(direction)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                
                Spacer()
                
                // View mode toggle
                Picker("View", selection: $viewMode) {
                    ForEach(CommitmentsViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                
                // Add button
                Button {
                    showingNewCommitment = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Filter bar
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search commitments...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 200)
                
                // Status filter
                Menu {
                    Button("All Status") { selectedStatus = nil }
                    Divider()
                    ForEach(CommitmentStatus.allCases, id: \.self) { status in
                        Button {
                            selectedStatus = status
                        } label: {
                            Label(status.displayName, systemImage: status.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedStatus?.icon ?? "circle.grid.2x2")
                        Text(selectedStatus?.displayName ?? "All Status")
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedStatus != nil ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor), in: Capsule())
                }
                .buttonStyle(.plain)
                
                // Project filter
                Menu {
                    Button("All Projects") { selectedProject = nil }
                    Divider()
                    ForEach(activeProjects) { project in
                        Button(project.name) { selectedProject = project }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text(selectedProject?.name ?? "All Projects")
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedProject != nil ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor), in: Capsule())
                }
                .buttonStyle(.plain)
                
                // Sort order
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            if sortOrder == order {
                                Label(order.rawValue, systemImage: "checkmark")
                            } else {
                                Text(order.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Count
                Text("\(filteredCommitments.count) commitments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
        }
        .background(.bar)
    }
    
    private var macListView: some View {
        Group {
            if filteredCommitments.isEmpty {
                emptyState
            } else {
                List(selection: $selectedCommitment) {
                    ForEach(groupedCommitments, id: \.0) { group, items in
                        Section {
                            ForEach(items) { commitment in
                                MacCommitmentRow(commitment: commitment) {
                                    toggleStatus(commitment)
                                }
                                .tag(commitment)
                                .contextMenu {
                                    commitmentContextMenu(for: commitment)
                                }
                            }
                        } header: {
                            HStack {
                                Text(group)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(items.count)")
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
        }
    }
    
    private var macBoardView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 16) {
                // Kanban columns based on due date grouping
                let columns = kanbanColumns
                ForEach(columns, id: \.0) { title, items, color in
                    KanbanColumn(
                        title: title,
                        items: items,
                        accentColor: color,
                        selectedCommitment: $selectedCommitment,
                        onToggle: toggleStatus,
                        onDelete: deleteCommitment
                    )
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var kanbanColumns: [(String, [Commitment], Color)] {
        let filtered = filteredCommitments
        
        let overdue = filtered.filter { $0.isOverdue }
        let today = filtered.filter { !$0.isOverdue && $0.dueDate != nil && Calendar.current.isDateInToday($0.dueDate!) }
        let thisWeek = filtered.filter {
            guard !$0.isOverdue, let due = $0.dueDate, !Calendar.current.isDateInToday(due) else { return false }
            if let days = $0.daysUntilDue { return days > 0 && days <= 7 }
            return false
        }
        let later = filtered.filter {
            guard let due = $0.dueDate, let days = $0.daysUntilDue else { return false }
            return days > 7
        }
        let noDue = filtered.filter { $0.dueDate == nil }
        
        var columns: [(String, [Commitment], Color)] = []
        if !overdue.isEmpty { columns.append(("Overdue", overdue, .red)) }
        if !today.isEmpty { columns.append(("Today", today, .orange)) }
        if !thisWeek.isEmpty { columns.append(("This Week", thisWeek, .blue)) }
        if !later.isEmpty { columns.append(("Later", later, .green)) }
        if !noDue.isEmpty { columns.append(("No Due Date", noDue, .gray)) }
        
        return columns
    }
    
    private var macEmptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("Select a Commitment")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Choose a commitment from the list to view and edit its details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    #endif
    
    // MARK: - Shared Components
    
    private var directionTabs: some View {
        Picker("Direction", selection: $selectedDirection) {
            ForEach(CommitmentDirection.allCases, id: \.self) { direction in
                Text(direction.displayName)
                    .tag(direction)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var filterMenu: some View {
        Menu {
            Section("Sort by") {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        if sortOrder == order {
                            Label(order.rawValue, systemImage: "checkmark")
                        } else {
                            Text(order.rawValue)
                        }
                    }
                }
            }
            
            Section("Status") {
                Button {
                    selectedStatus = nil
                } label: {
                    if selectedStatus == nil {
                        Label("All", systemImage: "checkmark")
                    } else {
                        Text("All")
                    }
                }
                
                ForEach(CommitmentStatus.allCases, id: \.self) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        if selectedStatus == status {
                            Label(status.displayName, systemImage: "checkmark")
                        } else {
                            Label(status.displayName, systemImage: status.icon)
                        }
                    }
                }
            }
            
            Section("Project") {
                Button {
                    selectedProject = nil
                } label: {
                    if selectedProject == nil {
                        Label("All Projects", systemImage: "checkmark")
                    } else {
                        Text("All Projects")
                    }
                }
                
                ForEach(activeProjects) { project in
                    Button {
                        selectedProject = project
                    } label: {
                        if selectedProject?.id == project.id {
                            Label(project.name, systemImage: "checkmark")
                        } else {
                            Text(project.name)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    @ViewBuilder
    private func commitmentContextMenu(for commitment: Commitment) -> some View {
        Button {
            toggleStatus(commitment)
        } label: {
            Label(
                commitment.status == .done ? "Reopen" : "Mark Done",
                systemImage: commitment.status == .done ? "arrow.uturn.backward" : "checkmark.circle"
            )
        }
        
        if commitment.status != .blocked {
            Button {
                commitment.status = .blocked
                commitment.updatedAt = Date()
                try? modelContext.save()
            } label: {
                Label("Mark Blocked", systemImage: "xmark.circle")
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteCommitment(commitment)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                selectedDirection == .iOwe ? "No I Owe Items" : "No Waiting For Items",
                systemImage: selectedDirection.icon
            )
        } description: {
            Text(selectedDirection == .iOwe
                 ? "You don't have any open commitments."
                 : "You're not waiting on anything."
            )
        } actions: {
            Button("Add Commitment") {
                showingNewCommitment = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredCommitments: [Commitment] {
        var result = commitments.filter { $0.direction == selectedDirection }
        
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }
        
        if let project = selectedProject {
            result = result.filter { $0.project?.id == project.id }
        }
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { commitment in
                commitment.title.localizedCaseInsensitiveContains(searchText) ||
                (commitment.person?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (commitment.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sort
        switch sortOrder {
        case .dueDate:
            result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .importance:
            result.sort { $0.importance > $1.importance }
        case .project:
            result.sort { ($0.project?.name ?? "") < ($1.project?.name ?? "") }
        case .person:
            result.sort { ($0.person?.name ?? "zzz") < ($1.person?.name ?? "zzz") }
        case .created:
            result.sort { $0.createdAt > $1.createdAt }
        }
        
        return result
    }
    
    private var groupedCommitments: [(String, [Commitment])] {
        let grouped = Dictionary(grouping: filteredCommitments) { commitment -> String in
            switch sortOrder {
            case .dueDate:
                guard let dueDate = commitment.dueDate else { return "No Due Date" }
                if commitment.isOverdue { return "Overdue" }
                if Calendar.current.isDateInToday(dueDate) { return "Today" }
                if Calendar.current.isDateInTomorrow(dueDate) { return "Tomorrow" }
                if let days = commitment.daysUntilDue, days <= 7 { return "This Week" }
                return "Later"
            case .importance:
                switch commitment.importance {
                case 5: return "Critical"
                case 4: return "High"
                case 3: return "Medium"
                case 2: return "Low"
                default: return "Minimal"
                }
            case .project:
                return commitment.project?.name ?? "No Project"
            case .person:
                return commitment.person?.name ?? "No Person"
            case .created:
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: commitment.createdAt)
            }
        }
        
        let sortedKeys: [String]
        switch sortOrder {
        case .dueDate:
            let order = ["Overdue", "Today", "Tomorrow", "This Week", "Later", "No Due Date"]
            sortedKeys = grouped.keys.sorted { order.firstIndex(of: $0) ?? 99 < order.firstIndex(of: $1) ?? 99 }
        case .importance:
            let order = ["Critical", "High", "Medium", "Low", "Minimal"]
            sortedKeys = grouped.keys.sorted { order.firstIndex(of: $0) ?? 99 < order.firstIndex(of: $1) ?? 99 }
        case .person:
            // Put "No Person" at the end
            sortedKeys = grouped.keys.sorted { a, b in
                if a == "No Person" { return false }
                if b == "No Person" { return true }
                return a < b
            }
        default:
            sortedKeys = grouped.keys.sorted()
        }
        
        return sortedKeys.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return (key, items)
        }
    }
    
    // MARK: - Actions
    
    private func toggleStatus(_ commitment: Commitment) {
        if commitment.status == .done {
            commitment.reopen()
        } else {
            commitment.markDone()
        }
        try? modelContext.save()
    }
    
    private func deleteCommitment(_ commitment: Commitment) {
        if selectedCommitment?.id == commitment.id {
            selectedCommitment = nil
        }
        modelContext.delete(commitment)
        try? modelContext.save()
    }
}

// MARK: - Filter Chip Component

struct FilterChip<Content: View>: View {
    let title: String
    let icon: String
    let isActive: Bool
    var action: (() -> Void)? = nil
    var content: (() -> Content)? = nil
    
    init(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) where Content == EmptyView {
        self.title = title
        self.icon = icon
        self.isActive = isActive
        self.action = action
        self.content = nil
    }
    
    init(title: String, icon: String, isActive: Bool) where Content == EmptyView {
        self.title = title
        self.icon = icon
        self.isActive = isActive
        self.action = nil
        self.content = nil
    }
    
    var body: some View {
        if let action = action {
            Button(action: action) {
                chipContent
            }
            .buttonStyle(.plain)
        } else {
            chipContent
        }
    }
    
    private var chipContent: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1), in: Capsule())
        .foregroundStyle(isActive ? .primary : .secondary)
    }
}

// MARK: - Commitment Row View

struct CommitmentRowView: View {
    let commitment: Commitment
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status toggle
            Button(action: onToggle) {
                Image(systemName: commitment.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(commitment.status == .done ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(commitment.title)
                    .font(.subheadline)
                    .strikethrough(commitment.status == .done)
                    .foregroundStyle(commitment.status == .done ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    if let project = commitment.project {
                        Text(project.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let person = commitment.person {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(person.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let dueDate = commitment.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(commitment.isOverdue ? .red : .secondary)
                }
                
                // Priority indicator
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Circle()
                            .fill(i <= commitment.importance ? priorityColor : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch commitment.importance {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
}

// MARK: - Mac Commitment Row (Enhanced)

#if os(macOS)
struct MacCommitmentRow: View {
    let commitment: Commitment
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status toggle
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(statusColor, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if commitment.status == .done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.green)
                    } else if commitment.status == .blocked {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.red)
                    }
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(commitment.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(commitment.status == .done)
                        .foregroundStyle(commitment.status == .done ? .secondary : .primary)
                        .lineLimit(1)
                    
                    if commitment.aiGenerated {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                }
                
                HStack(spacing: 6) {
                    if let project = commitment.project {
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
                    
                    if let person = commitment.person {
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                            Text(person.name)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Due date with visual indicator
            if let dueDate = commitment.dueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDueDate(dueDate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(dueDateColor)
                    
                    if let days = commitment.daysUntilDue {
                        Text(formatDaysRemaining(days))
                            .font(.caption2)
                            .foregroundStyle(dueDateColor.opacity(0.8))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(dueDateColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            
            // Priority indicator
            PriorityIndicator(importance: commitment.importance, urgency: commitment.urgency)
        }
        .padding(.vertical, 6)
    }
    
    private var statusColor: Color {
        switch commitment.status {
        case .open: return .secondary
        case .done: return .green
        case .blocked: return .red
        case .dropped: return .gray
        }
    }
    
    private var dueDateColor: Color {
        if commitment.isOverdue { return .red }
        guard let days = commitment.daysUntilDue else { return .secondary }
        if days == 0 { return .orange }
        if days <= 3 { return .yellow }
        return .secondary
    }
    
    private func formatDueDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatDaysRemaining(_ days: Int) -> String {
        if days < 0 { return "\(abs(days))d overdue" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "In \(days) days"
    }
}

struct PriorityIndicator: View {
    let importance: Int
    let urgency: Int
    
    var body: some View {
        HStack(spacing: 4) {
            // Importance stars
            HStack(spacing: 1) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= mappedImportance ? "star.fill" : "star")
                        .font(.system(size: 8))
                        .foregroundStyle(i <= mappedImportance ? .yellow : .secondary.opacity(0.3))
                }
            }
            
            // Urgency bolts
            HStack(spacing: 1) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= mappedUrgency ? "bolt.fill" : "bolt")
                        .font(.system(size: 8))
                        .foregroundStyle(i <= mappedUrgency ? .orange : .secondary.opacity(0.3))
                }
            }
        }
    }
    
    private var mappedImportance: Int {
        switch importance {
        case 5: return 3
        case 4: return 2
        case 3: return 2
        case 2: return 1
        default: return 1
        }
    }
    
    private var mappedUrgency: Int {
        switch urgency {
        case 5: return 3
        case 4: return 2
        case 3: return 2
        case 2: return 1
        default: return 1
        }
    }
}
#endif

// MARK: - Kanban Column

#if os(macOS)
struct KanbanColumn: View {
    let title: String
    let items: [Commitment]
    let accentColor: Color
    @Binding var selectedCommitment: Commitment?
    let onToggle: (Commitment) -> Void
    let onDelete: (Commitment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.2), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(accentColor.opacity(0.1))
            
            // Items
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items) { commitment in
                        KanbanCard(
                            commitment: commitment,
                            isSelected: selectedCommitment?.id == commitment.id,
                            onTap: { selectedCommitment = commitment },
                            onToggle: { onToggle(commitment) }
                        )
                        .contextMenu {
                            Button {
                                onToggle(commitment)
                            } label: {
                                Label(
                                    commitment.status == .done ? "Reopen" : "Mark Done",
                                    systemImage: commitment.status == .done ? "arrow.uturn.backward" : "checkmark.circle"
                                )
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                onDelete(commitment)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct KanbanCard: View {
    let commitment: Commitment
    let isSelected: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Button(action: onToggle) {
                    Image(systemName: commitment.status == .done ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(commitment.status == .done ? .green : .secondary)
                }
                .buttonStyle(.plain)
                
                Text(commitment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(commitment.status == .done)
                    .foregroundStyle(commitment.status == .done ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            HStack(spacing: 6) {
                if let project = commitment.project {
                    HStack(spacing: 2) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 8))
                        Text(project.name)
                    }
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1), in: Capsule())
                }
                
                if let person = commitment.person {
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 8))
                        Text(person.name)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Mini priority indicator
                HStack(spacing: 1) {
                    ForEach(1...commitment.importance, id: \.self) { _ in
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
    }
    
    private var priorityColor: Color {
        switch commitment.importance {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }
}
#endif

#Preview {
    CommitmentsListView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Person.self], inMemory: true)
}

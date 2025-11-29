import SwiftUI
import SwiftData

struct CommitmentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Commitment.dueDate) private var commitments: [Commitment]
    
    @State private var selectedDirection: CommitmentDirection = .iOwe
    @State private var selectedStatus: CommitmentStatus? = .open
    @State private var selectedProject: Project? = nil
    @State private var showingNewCommitment: Bool = false
    @State private var sortOrder: SortOrder = .dueDate
    
    @Query
    private var allProjects: [Project]
    
    private var activeProjects: [Project] {
        allProjects.filter { $0.status == .active }
    }
    
    enum SortOrder: String, CaseIterable {
        case dueDate = "Due Date"
        case importance = "Importance"
        case project = "Project"
        case created = "Created"
    }
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            commitmentsContent
        }
        #else
        commitmentsContent
        #endif
    }
    
    private var commitmentsContent: some View {
        VStack(spacing: 0) {
            // Direction Tabs
            directionTabs
            
            // Content
            if filteredCommitments.isEmpty {
                emptyState
            } else {
                commitmentsList
            }
        }
        .navigationTitle("Commitments")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
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
            NewCommitmentView(project: nil, sourceEntry: nil, preselectedDirection: selectedDirection)
        }
    }
    
    // MARK: - Direction Tabs
    
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
    
    // MARK: - Filter Menu
    
    private var filterMenu: some View {
        Menu {
            // Sort options
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
            
            // Status filter
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
            
            // Project filter
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
    
    // MARK: - Commitments List
    
    private var commitmentsList: some View {
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
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
    
    // MARK: - Empty State
    
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
        
        // Apply sort
        switch sortOrder {
        case .dueDate:
            result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .importance:
            result.sort { $0.importance > $1.importance }
        case .project:
            result.sort { ($0.project?.name ?? "") < ($1.project?.name ?? "") }
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
            case .created:
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: commitment.createdAt)
            }
        }
        
        // Sort groups
        let sortedKeys: [String]
        switch sortOrder {
        case .dueDate:
            let order = ["Overdue", "Today", "Tomorrow", "This Week", "Later", "No Due Date"]
            sortedKeys = grouped.keys.sorted { order.firstIndex(of: $0) ?? 99 < order.firstIndex(of: $1) ?? 99 }
        case .importance:
            let order = ["Critical", "High", "Medium", "Low", "Minimal"]
            sortedKeys = grouped.keys.sorted { order.firstIndex(of: $0) ?? 99 < order.firstIndex(of: $1) ?? 99 }
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
        modelContext.delete(commitment)
        try? modelContext.save()
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
                    
                    if let counterparty = commitment.counterparty {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(counterparty)
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

#Preview {
    CommitmentsListView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


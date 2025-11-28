import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.priority, order: .reverse) private var projects: [Project]
    
    @State private var searchText: String = ""
    @State private var selectedStatus: ProjectStatus? = nil
    @State private var selectedType: ProjectType? = nil
    @State private var showingNewProject: Bool = false
    @State private var sortOrder: SortOrder = .priority
    
    enum SortOrder: String, CaseIterable {
        case priority = "Priority"
        case lastActive = "Last Active"
        case name = "Name"
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredProjects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        ProjectRowView(project: project)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteProject(project)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            archiveProject(project)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search projects")
            .navigationTitle("Projects")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
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
                        Section("Filter by Status") {
                            Button {
                                selectedStatus = nil
                            } label: {
                                if selectedStatus == nil {
                                    Label("All", systemImage: "checkmark")
                                } else {
                                    Text("All")
                                }
                            }
                            
                            ForEach(ProjectStatus.allCases, id: \.self) { status in
                                Button {
                                    selectedStatus = status
                                } label: {
                                    if selectedStatus == status {
                                        Label(status.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(status.displayName)
                                    }
                                }
                            }
                        }
                        
                        // Type filter
                        Section("Filter by Type") {
                            Button {
                                selectedType = nil
                            } label: {
                                if selectedType == nil {
                                    Label("All", systemImage: "checkmark")
                                } else {
                                    Text("All")
                                }
                            }
                            
                            ForEach(ProjectType.allCases, id: \.self) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    if selectedType == type {
                                        Label(type.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(type.displayName)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectView()
            }
            .overlay {
                if filteredProjects.isEmpty {
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "folder")
                    } description: {
                        Text("Create your first project to get started.")
                    } actions: {
                        Button("New Project") {
                            showingNewProject = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredProjects: [Project] {
        var result = projects
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                (project.projectDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }
        
        // Apply type filter
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        
        // Apply sort
        switch sortOrder {
        case .priority:
            result.sort { $0.priority > $1.priority }
        case .lastActive:
            result.sort { ($0.lastActiveAt ?? .distantPast) > ($1.lastActiveAt ?? .distantPast) }
        case .name:
            result.sort { $0.name < $1.name }
        }
        
        return result
    }
    
    // MARK: - Actions
    
    private func deleteProject(_ project: Project) {
        modelContext.delete(project)
        try? modelContext.save()
    }
    
    private func archiveProject(_ project: Project) {
        project.status = .archived
        project.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Project Row View

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                    
                    Image(systemName: project.type.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 8) {
                    Label(project.status.displayName, systemImage: project.status.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let days = project.daysSinceLastActive {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("\(days)d ago")
                            .font(.caption)
                            .foregroundStyle(project.needsAttention ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // Commitment counts
            VStack(alignment: .trailing, spacing: 2) {
                if project.openIOweCount > 0 {
                    HStack(spacing: 2) {
                        Text("\(project.openIOweCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
                
                if project.openWaitingForCount > 0 {
                    HStack(spacing: 2) {
                        Text("\(project.openWaitingForCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.down.left")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch project.priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
}

// MARK: - New Project View

struct NewProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var type: ProjectType = .project
    @State private var priority: Int = 3
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $name)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(ProjectType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(1...5, id: \.self) { level in
                            Text("\(level) - \(priorityLabel(level))")
                                .tag(level)
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func priorityLabel(_ level: Int) -> String {
        switch level {
        case 5: return "Critical"
        case 4: return "High"
        case 3: return "Medium"
        case 2: return "Low"
        default: return "Minimal"
        }
    }
    
    private func createProject() {
        let project = Project(
            name: name,
            projectDescription: description.isEmpty ? nil : description,
            type: type,
            priority: priority
        )
        
        modelContext.insert(project)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ProjectsListView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}




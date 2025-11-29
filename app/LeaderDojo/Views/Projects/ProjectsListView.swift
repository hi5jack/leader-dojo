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
    @State private var viewMode: ViewMode = .grid
    
    enum SortOrder: String, CaseIterable {
        case priority = "Priority"
        case lastActive = "Last Active"
        case name = "Name"
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - iOS Layout
    
    #if os(iOS)
    private var iOSLayout: some View {
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectView()
            }
            .overlay {
                if filteredProjects.isEmpty {
                    emptyStateView
                }
            }
        }
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            macOSToolbar
            
            // Content
            if filteredProjects.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    if viewMode == .grid {
                        projectsGrid
                    } else {
                        projectsList
                    }
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Projects")
        .sheet(isPresented: $showingNewProject) {
            NewProjectView()
        }
    }
    
    private var macOSToolbar: some View {
        VStack(spacing: 12) {
            // Top row: Title, search, actions
            HStack(spacing: 16) {
                // Title & count
                VStack(alignment: .leading, spacing: 2) {
                    Text("Projects")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(filteredProjects.count) project\(filteredProjects.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .frame(width: 220)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                
                // View mode toggle
                Picker("", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                
                // Sort menu
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
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                }
                .menuStyle(.borderlessButton)
                
                // New project button
                Button {
                    showingNewProject = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Filter pills
            HStack(spacing: 8) {
                // Status filters
                ForEach([nil] + ProjectStatus.allCases.map { Optional($0) }, id: \.self) { status in
                    FilterPill(
                        title: status?.displayName ?? "All",
                        isSelected: selectedStatus == status,
                        color: status == nil ? .primary : statusColor(status!)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedStatus = status
                        }
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Type filters
                ForEach([nil] + ProjectType.allCases.map { Optional($0) }, id: \.self) { type in
                    FilterPill(
                        title: type?.displayName ?? "All Types",
                        icon: type?.icon,
                        isSelected: selectedType == type,
                        color: .secondary
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var projectsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(filteredProjects) { project in
                #if os(macOS)
                NavigationLink(value: AppRoute.project(project.persistentModelID)) {
                    ProjectCardView(project: project)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    projectContextMenu(for: project)
                }
                #else
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    ProjectCardView(project: project)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    projectContextMenu(for: project)
                }
                #endif
            }
        }
        .padding(24)
    }
    
    private var projectsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredProjects) { project in
                #if os(macOS)
                NavigationLink(value: AppRoute.project(project.persistentModelID)) {
                    ProjectListRowView(project: project)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    projectContextMenu(for: project)
                }
                #else
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    ProjectListRowView(project: project)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    projectContextMenu(for: project)
                }
                #endif
            }
        }
        .padding(24)
    }
    
    @ViewBuilder
    private func projectContextMenu(for project: Project) -> some View {
        Button {
            archiveProject(project)
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteProject(project)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
    #endif
    
    // MARK: - Shared Components
    
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
    
    private var emptyStateView: some View {
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

// MARK: - Project Row View (iOS)

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

// MARK: - Project Card View (macOS Grid)

#if os(macOS)
struct ProjectCardView: View {
    let project: Project
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Priority bar at top
            Rectangle()
                .fill(priorityColor.gradient)
                .frame(height: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                // Header: Icon, Name, Status
                HStack(alignment: .top) {
                    // Type icon
                    Image(systemName: project.type.icon)
                        .font(.title2)
                        .foregroundStyle(priorityColor)
                        .frame(width: 36, height: 36)
                        .background(priorityColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Text(project.status.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor.opacity(0.15), in: Capsule())
                                .foregroundStyle(statusColor)
                            
                            if project.needsAttention {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Priority badge
                    Text("P\(project.priority)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(priorityColor)
                }
                
                // Description if exists
                if let description = project.projectDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Divider()
                
                // Stats row
                HStack(spacing: 16) {
                    // I Owe
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(.orange)
                        Text("\(project.openIOweCount)")
                            .fontWeight(.medium)
                        Text("owe")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    
                    // Waiting for
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundStyle(.blue)
                        Text("\(project.openWaitingForCount)")
                            .fontWeight(.medium)
                        Text("waiting")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    // Last active
                    if let days = project.daysSinceLastActive {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(days == 0 ? "Today" : "\(days)d ago")
                        }
                        .font(.caption)
                        .foregroundStyle(project.needsAttention ? .red : .secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: .black.opacity(isHovered ? 0.12 : 0.06),
            radius: isHovered ? 12 : 8,
            y: isHovered ? 4 : 2
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
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
    
    private var statusColor: Color {
        switch project.status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}

// MARK: - Project List Row View (macOS List)

struct ProjectListRowView: View {
    let project: Project
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor.gradient)
                .frame(width: 4, height: 44)
            
            // Type icon
            Image(systemName: project.type.icon)
                .font(.title3)
                .foregroundStyle(priorityColor)
                .frame(width: 32, height: 32)
                .background(priorityColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            
            // Name & Status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(project.name)
                        .font(.headline)
                    
                    if project.needsAttention {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(project.status.displayName)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                    
                    if let days = project.daysSinceLastActive {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(days == 0 ? "Active today" : "\(days)d ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 20) {
                // I Owe
                VStack(spacing: 2) {
                    Text("\(project.openIOweCount)")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("Owe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 44)
                
                // Waiting
                VStack(spacing: 2) {
                    Text("\(project.openWaitingForCount)")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("Wait")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 44)
                
                // Priority
                Text("P\(project.priority)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor, in: Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor) : .clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
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
    
    private var statusColor: Color {
        switch project.status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? color.opacity(0.15)
                    : Color(nsColor: .controlBackgroundColor),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : .clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
    }
}
#endif

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
            #if os(macOS)
            macOSLayout
            #else
            iOSLayout
            #endif
        }
    }
    
    // MARK: - iOS Layout
    
    #if os(iOS)
    private var iOSLayout: some View {
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
        .navigationBarTitleDisplayMode(.inline)
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
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Header
            macOSHeader
            
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info Card
                    basicInfoCard
                    
                    // Settings Card
                    settingsCard
                }
                .padding(24)
                .frame(maxWidth: 600)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("New Project")
    }
    
    private var macOSHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("New Project")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create a new project to track your work")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create Project") {
                    createProject()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Project Details", systemImage: "folder.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Project name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    MacTextEditor(text: $description, placeholder: "Optional description for this project...")
                        .frame(minHeight: 80)
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Settings", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 16) {
                // Type Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Type")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $type) {
                        ForEach(ProjectType.allCases, id: \.self) { projectType in
                            Label(projectType.displayName, systemImage: projectType.icon)
                                .tag(projectType)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // Priority Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                priority = level
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(level)")
                                        .font(.headline)
                                    Text(priorityLabel(level))
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    priority == level
                                        ? priorityColor(level).opacity(0.2)
                                        : Color(nsColor: .controlBackgroundColor),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            priority == level ? priorityColor(level) : .clear,
                                            lineWidth: 2
                                        )
                                )
                                .foregroundStyle(priority == level ? priorityColor(level) : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private func priorityColor(_ level: Int) -> Color {
        switch level {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
    #endif
    
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




import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    
    @State private var showingNewEntry: Bool = false
    @State private var showingPrepBriefing: Bool = false
    @State private var showingEditProject: Bool = false
    @State private var showingNewCommitment: Bool = false
    @State private var selectedEntryKind: EntryKind? = nil
    @State private var selectedCommitmentDirection: CommitmentDirection = .iOwe
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Project Header / Snapshot
                projectHeader
                
                // Quick Actions
                quickActions
                
                // Commitments Panel
                commitmentsPanel
                
                // Timeline
                timelineSection
            }
            .padding()
        }
        .navigationTitle(project.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingNewEntry = true
                    } label: {
                        Label("Add Entry", systemImage: "plus.circle")
                    }
                    
                    Button {
                        showingPrepBriefing = true
                    } label: {
                        Label("Prep Briefing", systemImage: "doc.text.fill")
                    }
                    
                    Divider()
                    
                    Button {
                        showingEditProject = true
                    } label: {
                        Label("Edit Project", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            NewEntryView(project: project, preselectedKind: selectedEntryKind)
        }
        .sheet(isPresented: $showingPrepBriefing) {
            PrepBriefingView(project: project)
        }
        .sheet(isPresented: $showingEditProject) {
            EditProjectView(project: project)
        }
        .sheet(isPresented: $showingNewCommitment) {
            NewCommitmentView(
                project: project,
                person: nil,
                sourceEntry: nil,
                preselectedDirection: selectedCommitmentDirection
            )
        }
    }
    
    // MARK: - Project Header
    
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status and Type badges
            HStack(spacing: 8) {
                Badge(text: project.status.displayName, icon: project.status.icon, color: statusColor)
                Badge(text: project.type.displayName, icon: project.type.icon, color: .secondary)
                Badge(text: "P\(project.priority)", icon: "flag.fill", color: priorityColor)
            }
            
            // Owner Notes
            if let notes = project.ownerNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    MarkdownText(notes, font: .subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Last Active
            if let lastActive = project.lastActiveAt {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Last active \(lastActive, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionButton(title: "Meeting", icon: "person.2.fill", color: .blue) {
                    selectedEntryKind = .meeting
                    showingNewEntry = true
                }
                
                QuickActionButton(title: "Note", icon: "note.text", color: .orange) {
                    selectedEntryKind = .note
                    showingNewEntry = true
                }
                
                QuickActionButton(title: "Decision", icon: "checkmark.seal.fill", color: .purple) {
                    selectedEntryKind = .decision
                    showingNewEntry = true
                }
                
                QuickActionButton(title: "Commitment", icon: "checkmark.circle", color: .indigo) {
                    selectedCommitmentDirection = .iOwe
                    showingNewCommitment = true
                }
                
                QuickActionButton(title: "Prep", icon: "doc.text.fill", color: .cyan) {
                    showingPrepBriefing = true
                }
            }
        }
    }
    
    // MARK: - Commitments Panel
    
    private var commitmentsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with add button
            HStack {
                Label("Commitments", systemImage: "checklist")
                    .font(.headline)
                    .foregroundStyle(.indigo)
                
                Spacer()
                
                Menu {
                    Button {
                        selectedCommitmentDirection = .iOwe
                        showingNewCommitment = true
                    } label: {
                        Label("I Owe", systemImage: "arrow.up.right.circle")
                    }
                    
                    Button {
                        selectedCommitmentDirection = .waitingFor
                        showingNewCommitment = true
                    } label: {
                        Label("Waiting For", systemImage: "arrow.down.left.circle")
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.indigo)
                }
            }
            
            let iOwe = project.commitments?.filter { $0.direction == .iOwe && $0.status.isActive } ?? []
            let waitingFor = project.commitments?.filter { $0.direction == .waitingFor && $0.status.isActive } ?? []
            
            if iOwe.isEmpty && waitingFor.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.circle",
                    title: "No Active Commitments",
                    message: "Tap + to add a commitment, or add entries to generate suggestions."
                )
            } else {
                // I Owe section
                if !iOwe.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("I Owe (\(iOwe.count))", systemImage: "arrow.up.right")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        
                        ForEach(iOwe.prefix(3)) { commitment in
                            #if os(macOS)
                            NavigationLink(value: AppRoute.commitment(commitment.persistentModelID)) {
                                MiniCommitmentRow(commitment: commitment) {
                                    toggleCommitment(commitment)
                                }
                            }
                            .buttonStyle(.plain)
                            #else
                            NavigationLink {
                                CommitmentDetailView(commitment: commitment)
                            } label: {
                                MiniCommitmentRow(commitment: commitment) {
                                    toggleCommitment(commitment)
                                }
                            }
                            .buttonStyle(.plain)
                            #endif
                        }
                    }
                }
                
                // Waiting For section
                if !waitingFor.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Waiting For (\(waitingFor.count))", systemImage: "arrow.down.left")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        
                        ForEach(waitingFor.prefix(3)) { commitment in
                            #if os(macOS)
                            NavigationLink(value: AppRoute.commitment(commitment.persistentModelID)) {
                                MiniCommitmentRow(commitment: commitment) {
                                    toggleCommitment(commitment)
                                }
                            }
                            .buttonStyle(.plain)
                            #else
                            NavigationLink {
                                CommitmentDetailView(commitment: commitment)
                            } label: {
                                MiniCommitmentRow(commitment: commitment) {
                                    toggleCommitment(commitment)
                                }
                            }
                            .buttonStyle(.plain)
                            #endif
                        }
                    }
                }
            }
        }
    }
    
    private func toggleCommitment(_ commitment: Commitment) {
        if commitment.status == .done {
            commitment.reopen()
        } else {
            commitment.markDone()
        }
        try? modelContext.save()
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Timeline", icon: "clock.fill", color: .green)
            
            let entries = (project.entries ?? [])
                .filter { $0.deletedAt == nil }
                .sorted { $0.occurredAt > $1.occurredAt }
            
            if entries.isEmpty {
                EmptyStateCard(
                    icon: "doc.text",
                    title: "No Entries Yet",
                    message: "Record meetings, notes, and decisions to build your timeline."
                )
            } else {
                ForEach(entries.prefix(10)) { entry in
                    #if os(macOS)
                    NavigationLink(value: AppRoute.entry(entry.persistentModelID)) {
                        EntryRowView(entry: entry)
                    }
                    .buttonStyle(.plain)
                    #else
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        EntryRowView(entry: entry)
                    }
                    .buttonStyle(.plain)
                    #endif
                }
                
                if entries.count > 10 {
                    #if os(macOS)
                    NavigationLink(value: AppRoute.projectEntries(project.persistentModelID)) {
                        Text("View all \(entries.count) entries")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    #else
                    NavigationLink {
                        ProjectEntriesListView(project: project)
                    } label: {
                        Text("View all \(entries.count) entries")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    #endif
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch project.status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
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
}

// MARK: - Edit Project View

struct EditProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    
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
                TextField("Name", text: $project.name)
                
                TextField("Description", text: Binding(
                    get: { project.projectDescription ?? "" },
                    set: { project.projectDescription = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            }
            
            Section {
                Picker("Type", selection: $project.type) {
                    ForEach(ProjectType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                
                Picker("Status", selection: $project.status) {
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        Label(status.displayName, systemImage: status.icon)
                            .tag(status)
                    }
                }
                
                Picker("Priority", selection: $project.priority) {
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)")
                            .tag(level)
                    }
                }
            }
            
            Section("My Notes") {
                TextEditor(text: Binding(
                    get: { project.ownerNotes ?? "" },
                    set: { project.ownerNotes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
        }
        .navigationTitle("Edit Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    project.updatedAt = Date()
                    try? modelContext.save()
                    dismiss()
                }
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
                HStack(alignment: .top, spacing: 24) {
                    // Left Column - Main Content
                    VStack(spacing: 20) {
                        basicInfoCard
                        notesCard
                    }
                    .frame(minWidth: 350, maxWidth: .infinity)
                    
                    // Right Column - Settings
                    VStack(spacing: 20) {
                        settingsCard
                        metadataCard
                    }
                    .frame(width: 260)
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Edit Project")
    }
    
    private var macOSHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Project")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(project.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save Changes") {
                    project.updatedAt = Date()
                    try? modelContext.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
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
                    
                    TextField("Project name", text: $project.name)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    MacTextEditor(
                        text: Binding(
                            get: { project.projectDescription ?? "" },
                            set: { project.projectDescription = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "Optional description for this project..."
                    )
                    .frame(minHeight: 80)
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("My Notes", systemImage: "note.text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
            
            MacTextEditor(
                text: Binding(
                    get: { project.ownerNotes ?? "" },
                    set: { project.ownerNotes = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "Personal notes, context, reminders..."
            )
            .frame(minHeight: 120)
        }
        .padding(20)
        .background(.orange.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Settings", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 14) {
                // Type Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Type")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $project.type) {
                        ForEach(ProjectType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // Status Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $project.status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Label(status.displayName, systemImage: status.icon)
                                .tag(status)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // Priority Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Priority")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $project.priority) {
                        ForEach(1...5, id: \.self) { level in
                            HStack {
                                Circle()
                                    .fill(priorityColor(level))
                                    .frame(width: 8, height: 8)
                                Text("\(level) - \(priorityLabel(level))")
                            }
                            .tag(level)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Info", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Created") {
                    Text(project.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .font(.caption)
                
                LabeledContent("Updated") {
                    Text(project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .font(.caption)
                
                if let lastActive = project.lastActiveAt {
                    LabeledContent("Last Active") {
                        Text(lastActive.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                    .font(.caption)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
    
    private func priorityLabel(_ level: Int) -> String {
        switch level {
        case 5: return "Critical"
        case 4: return "High"
        case 3: return "Medium"
        case 2: return "Low"
        default: return "Minimal"
        }
    }
    #endif
}

// MARK: - Project Entries List View

struct ProjectEntriesListView: View {
    let project: Project
    @State private var selectedKind: EntryKind? = nil
    
    var body: some View {
        List {
            ForEach(filteredEntries) { entry in
                NavigationLink {
                    EntryDetailView(entry: entry)
                } label: {
                    EntryRowView(entry: entry)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("All Entries")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button {
                        selectedKind = nil
                    } label: {
                        if selectedKind == nil {
                            Label("All Types", systemImage: "checkmark")
                        } else {
                            Text("All Types")
                        }
                    }
                    
                    ForEach(EntryKind.allCases, id: \.self) { kind in
                        Button {
                            selectedKind = kind
                        } label: {
                            if selectedKind == kind {
                                Label(kind.displayName, systemImage: "checkmark")
                            } else {
                                Label(kind.displayName, systemImage: kind.icon)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
    
    private var filteredEntries: [Entry] {
        var entries = (project.entries ?? []).filter { $0.deletedAt == nil }
        
        if let kind = selectedKind {
            entries = entries.filter { $0.kind == kind }
        }
        
        return entries.sorted { $0.occurredAt > $1.occurredAt }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(name: "Sample Project"))
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


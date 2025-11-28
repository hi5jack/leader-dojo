import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project
    
    @State private var showingNewEntry: Bool = false
    @State private var showingPrepBriefing: Bool = false
    @State private var showingEditProject: Bool = false
    @State private var selectedEntryKind: EntryKind? = nil
    
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
                    Text(notes)
                        .font(.subheadline)
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
            
            QuickActionButton(title: "Prep", icon: "doc.text.fill", color: .cyan) {
                showingPrepBriefing = true
            }
        }
    }
    
    // MARK: - Commitments Panel
    
    private var commitmentsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Commitments", icon: "checklist", color: .indigo)
            
            let iOwe = project.commitments?.filter { $0.direction == .iOwe && $0.status.isActive } ?? []
            let waitingFor = project.commitments?.filter { $0.direction == .waitingFor && $0.status.isActive } ?? []
            
            if iOwe.isEmpty && waitingFor.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.circle",
                    title: "No Active Commitments",
                    message: "Add entries to generate commitment suggestions."
                )
            } else {
                // I Owe section
                if !iOwe.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("I Owe (\(iOwe.count))", systemImage: "arrow.up.right")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        
                        ForEach(iOwe.prefix(3)) { commitment in
                            MiniCommitmentRow(commitment: commitment)
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
                            MiniCommitmentRow(commitment: commitment)
                        }
                    }
                }
            }
        }
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
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        EntryRowView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
                
                if entries.count > 10 {
                    NavigationLink {
                        ProjectEntriesListView(project: project)
                    } label: {
                        Text("View all \(entries.count) entries")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
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
                    Button("Save") {
                        project.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
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


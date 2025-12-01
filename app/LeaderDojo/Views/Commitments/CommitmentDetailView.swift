import SwiftUI
import SwiftData

struct CommitmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var commitment: Commitment
    
    @State private var showingEditCommitment: Bool = false
    @State private var showingDeleteAlert: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Header
                commitmentHeader
                
                // Status Actions
                statusActions
                
                // Details
                detailsSection
                
                // Notes
                if let notes = commitment.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                
                // Related Items
                relatedItemsSection
                
                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Commitment")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditCommitment = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditCommitment) {
            EditCommitmentView(commitment: commitment)
        }
        .alert("Delete Commitment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(commitment)
                try? modelContext.save()
            }
        } message: {
            Text("Are you sure you want to delete this commitment?")
        }
    }
    
    // MARK: - Header
    
    private var commitmentHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(commitment.title)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Badge(
                    text: commitment.direction.displayName,
                    icon: commitment.direction.icon,
                    color: commitment.direction == .iOwe ? .orange : .blue
                )
                
                Badge(
                    text: commitment.status.displayName,
                    icon: commitment.status.icon,
                    color: statusColor
                )
                
                if commitment.isOverdue {
                    Badge(text: "Overdue", icon: "exclamationmark.triangle.fill", color: .red)
                }
            }
        }
    }
    
    // MARK: - Status Actions
    
    private var statusActions: some View {
        HStack(spacing: 12) {
            ForEach(CommitmentStatus.allCases, id: \.self) { status in
                Button {
                    updateStatus(to: status)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: status.icon)
                            .font(.title2)
                        Text(status.displayName)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        commitment.status == status
                            ? statusButtonColor(status).opacity(0.2)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                commitment.status == status
                                    ? statusButtonColor(status)
                                    : Color.secondary.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .foregroundStyle(
                        commitment.status == status
                            ? statusButtonColor(status)
                            : .secondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Due Date
            HStack {
                Label("Due Date", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let dueDate = commitment.dueDate {
                    Text(dueDate, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(commitment.isOverdue ? .red : .primary)
                } else {
                    Text("Not set")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Person
            HStack {
                Label("Person", systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let person = commitment.person {
                    Text(person.displayName)
                        .font(.subheadline)
                } else {
                    Text("Not specified")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Importance
            HStack {
                Label("Importance", systemImage: "flag.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= commitment.importance ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(i <= commitment.importance ? .yellow : .secondary)
                    }
                }
            }
            
            // Urgency
            HStack {
                Label("Urgency", systemImage: "bolt.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= commitment.urgency ? "bolt.fill" : "bolt")
                            .font(.caption)
                            .foregroundStyle(i <= commitment.urgency ? .orange : .secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Notes Section
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            MarkdownText(notes)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Related Items Section
    
    private var relatedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Project
            if let project = commitment.project {
                #if os(macOS)
                NavigationLink(value: AppRoute.project(project.persistentModelID)) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        Text(project.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                #else
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        Text(project.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                #endif
            }
            
            // Source Entry
            if let entry = commitment.sourceEntry {
                #if os(macOS)
                NavigationLink(value: AppRoute.entry(entry.persistentModelID)) {
                    HStack {
                        Image(systemName: entry.kind.icon)
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading) {
                            Text("Source Entry")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.title)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                #else
                NavigationLink {
                    EntryDetailView(entry: entry)
                } label: {
                    HStack {
                        Image(systemName: entry.kind.icon)
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading) {
                            Text("Source Entry")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.title)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                #endif
            }
            
            if commitment.project == nil && commitment.sourceEntry == nil {
                Text("No related items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            LabeledContent("Created", value: commitment.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
            
            LabeledContent("Updated", value: commitment.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
            
            if let completedAt = commitment.completedAt {
                LabeledContent("Completed", value: completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
            }
            
            if commitment.aiGenerated {
                HStack {
                    Image(systemName: "sparkles")
                    Text("AI Generated")
                }
                .font(.caption)
                .foregroundStyle(.purple)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Actions
    
    private func updateStatus(to status: CommitmentStatus) {
        if status == .done {
            commitment.markDone()
        } else {
            commitment.status = status
            commitment.completedAt = nil
        }
        commitment.updatedAt = Date()
        try? modelContext.save()
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch commitment.status {
        case .open: return .blue
        case .done: return .green
        case .blocked: return .red
        case .dropped: return .gray
        }
    }
    
    private func statusButtonColor(_ status: CommitmentStatus) -> Color {
        switch status {
        case .open: return .blue
        case .done: return .green
        case .blocked: return .red
        case .dropped: return .gray
        }
    }
}

// MARK: - New Commitment View

struct NewCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let project: Project?
    let person: Person?
    let sourceEntry: Entry?
    var preselectedDirection: CommitmentDirection = .iOwe
    
    @State private var title: String = ""
    @State private var direction: CommitmentDirection = .iOwe
    @State private var selectedPerson: Person? = nil
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var importance: Int = 3
    @State private var urgency: Int = 3
    @State private var notes: String = ""
    @State private var selectedProject: Project?
    @State private var showingValidationError: Bool = false
    
    @Query(sort: \Project.name)
    private var allProjects: [Project]
    
    @Query(sort: \Person.name)
    private var allPeople: [Person]
    
    private var activeProjects: [Project] {
        allProjects.filter { $0.status == .active }
    }
    
    /// Whether the form has required context (project or person)
    private var hasRequiredContext: Bool {
        (project != nil || selectedProject != nil) || (person != nil || selectedPerson != nil)
    }
    
    /// Whether the form can be saved
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasRequiredContext
    }
    
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
                TextField("What's the commitment?", text: $title)
                
                Picker("Direction", selection: $direction) {
                    ForEach(CommitmentDirection.allCases, id: \.self) { dir in
                        Label(dir.displayName, systemImage: dir.icon)
                            .tag(dir)
                    }
                }
            }
            
            Section {
                if person != nil {
                    // Person is locked from context
                    HStack {
                        Text("Person")
                        Spacer()
                        Text(person?.displayName ?? "")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    PersonPicker(
                        selection: $selectedPerson,
                        label: "",
                        placeholder: "Select person"
                    )
                }
            }
            
            Section {
                if project == nil {
                    Picker("Project", selection: $selectedProject) {
                        Text("None").tag(nil as Project?)
                        ForEach(activeProjects) { proj in
                            Text(proj.name).tag(proj as Project?)
                        }
                    }
                } else {
                    // Project is locked from context
                    HStack {
                        Text("Project")
                        Spacer()
                        Text(project?.name ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Toggle("Set Due Date", isOn: $hasDueDate)
                
                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            
            // Validation hint
            if !hasRequiredContext {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("A commitment requires either a project or a person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Priority") {
                Stepper("Importance: \(importance)", value: $importance, in: 1...5)
                Stepper("Urgency: \(urgency)", value: $urgency, in: 1...5)
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle("New Commitment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    createCommitment()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            direction = preselectedDirection
            selectedProject = project
            selectedPerson = person
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
                        commitmentInfoCard
                        notesCard
                    }
                    .frame(minWidth: 350, maxWidth: .infinity)
                    
                    // Right Column - Settings
                    VStack(spacing: 20) {
                        contextCard
                        priorityCard
                        
                        // Validation hint
                        if !hasRequiredContext {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("A commitment requires either a project or a person")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .frame(width: 260)
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("New Commitment")
        .onAppear {
            direction = preselectedDirection
            selectedProject = project
            selectedPerson = person
        }
    }
    
    private var macOSHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("New Commitment")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let projectName = project?.name ?? selectedProject?.name {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                        Text(projectName)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                } else if let personName = person?.displayName ?? selectedPerson?.displayName {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text(personName)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create Commitment") {
                    createCommitment()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var commitmentInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Commitment", systemImage: "checkmark.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.indigo)
            
            VStack(alignment: .leading, spacing: 14) {
                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("What's the commitment?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Describe the commitment...", text: $title)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                
                Divider()
                
                // Direction
                VStack(alignment: .leading, spacing: 8) {
                    Text("Direction")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(CommitmentDirection.allCases, id: \.self) { dir in
                            Button {
                                direction = dir
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: dir.icon)
                                    Text(dir.displayName)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    direction == dir
                                        ? (dir == .iOwe ? Color.orange : Color.blue).opacity(0.2)
                                        : Color(nsColor: .controlBackgroundColor),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            direction == dir ? (dir == .iOwe ? Color.orange : Color.blue) : .clear,
                                            lineWidth: 2
                                        )
                                )
                                .foregroundStyle(direction == dir ? (dir == .iOwe ? .orange : .blue) : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Person
                if person != nil {
                    // Person is locked from context
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                            Text(person?.displayName ?? "")
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    PersonPicker(
                        selection: $selectedPerson,
                        label: "Person",
                        placeholder: "Select person"
                    )
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Notes", systemImage: "note.text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            MacTextEditor(text: $notes, placeholder: "Additional context or details...")
                .frame(minHeight: 100)
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Context", systemImage: "link")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 14) {
                // Project Picker (if not preset)
                if project == nil {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $selectedProject) {
                            Text("None").tag(nil as Project?)
                            ForEach(activeProjects) { proj in
                                Text(proj.name).tag(proj as Project?)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    
                    Divider()
                } else {
                    // Project is locked from context
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(project?.name ?? "")
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Divider()
                }
                
                // Due Date
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $hasDueDate) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Due Date")
                                .font(.subheadline)
                            if !hasDueDate {
                                Text("No deadline set")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                    
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Priority", systemImage: "flag.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 14) {
                // Importance
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Importance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(importance)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.yellow)
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                importance = i
                            } label: {
                                Image(systemName: i <= importance ? "star.fill" : "star")
                                    .font(.body)
                                    .foregroundStyle(i <= importance ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Urgency
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Urgency")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(urgency)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                urgency = i
                            } label: {
                                Image(systemName: i <= urgency ? "bolt.fill" : "bolt")
                                    .font(.body)
                                    .foregroundStyle(i <= urgency ? .orange : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    #endif
    
    private func createCommitment() {
        let commitment = Commitment(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            direction: direction,
            dueDate: hasDueDate ? dueDate : nil,
            importance: importance,
            urgency: urgency,
            notes: notes.isEmpty ? nil : notes
        )
        
        commitment.project = project ?? selectedProject
        commitment.sourceEntry = sourceEntry
        commitment.person = person ?? selectedPerson
        
        modelContext.insert(commitment)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Edit Commitment View

struct EditCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var commitment: Commitment
    
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    
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
                TextField("Title", text: $commitment.title)
                
                Picker("Direction", selection: $commitment.direction) {
                    ForEach(CommitmentDirection.allCases, id: \.self) { dir in
                        Label(dir.displayName, systemImage: dir.icon)
                            .tag(dir)
                    }
                }
            }
            
            Section {
                PersonPicker(
                    selection: $commitment.person,
                    label: "",
                    placeholder: "Select person (optional)"
                )
            }
            
            Section {
                Toggle("Set Due Date", isOn: $hasDueDate)
                
                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            
            Section("Priority") {
                Stepper("Importance: \(commitment.importance)", value: $commitment.importance, in: 1...5)
                Stepper("Urgency: \(commitment.urgency)", value: $commitment.urgency, in: 1...5)
            }
            
            Section("Notes") {
                TextEditor(text: Binding(
                    get: { commitment.notes ?? "" },
                    set: { commitment.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 80)
            }
        }
        .navigationTitle("Edit Commitment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    commitment.dueDate = hasDueDate ? dueDate : nil
                    commitment.updatedAt = Date()
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .onAppear {
            hasDueDate = commitment.dueDate != nil
            dueDate = commitment.dueDate ?? Date()
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
                        commitmentInfoCard
                        notesCard
                    }
                    .frame(minWidth: 350, maxWidth: .infinity)
                    
                    // Right Column - Settings
                    VStack(spacing: 20) {
                        contextCard
                        priorityCard
                        metadataCard
                    }
                    .frame(width: 260)
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Edit Commitment")
        .onAppear {
            hasDueDate = commitment.dueDate != nil
            dueDate = commitment.dueDate ?? Date()
        }
    }
    
    private var macOSHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Commitment")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let projectName = commitment.project?.name {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                        Text(projectName)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save Changes") {
                    commitment.dueDate = hasDueDate ? dueDate : nil
                    commitment.updatedAt = Date()
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
    
    private var commitmentInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Commitment", systemImage: "checkmark.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.indigo)
            
            VStack(alignment: .leading, spacing: 14) {
                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Describe the commitment...", text: $commitment.title)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                
                Divider()
                
                // Direction
                VStack(alignment: .leading, spacing: 8) {
                    Text("Direction")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(CommitmentDirection.allCases, id: \.self) { dir in
                            Button {
                                commitment.direction = dir
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: dir.icon)
                                    Text(dir.displayName)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    commitment.direction == dir
                                        ? (dir == .iOwe ? Color.orange : Color.blue).opacity(0.2)
                                        : Color(nsColor: .controlBackgroundColor),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            commitment.direction == dir ? (dir == .iOwe ? Color.orange : Color.blue) : .clear,
                                            lineWidth: 2
                                        )
                                )
                                .foregroundStyle(commitment.direction == dir ? (dir == .iOwe ? .orange : .blue) : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Person
                PersonPicker(
                    selection: $commitment.person,
                    label: "Person",
                    placeholder: "Select person (optional)"
                )
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Notes", systemImage: "note.text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            MacTextEditor(
                text: Binding(
                    get: { commitment.notes ?? "" },
                    set: { commitment.notes = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "Additional context or details..."
            )
            .frame(minHeight: 100)
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Due Date", systemImage: "calendar")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $hasDueDate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Has Deadline")
                            .font(.subheadline)
                        if !hasDueDate {
                            Text("No deadline set")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
                
                if hasDueDate {
                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Priority", systemImage: "flag.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 14) {
                // Importance
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Importance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(commitment.importance)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.yellow)
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                commitment.importance = i
                            } label: {
                                Image(systemName: i <= commitment.importance ? "star.fill" : "star")
                                    .font(.body)
                                    .foregroundStyle(i <= commitment.importance ? .yellow : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Urgency
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Urgency")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(commitment.urgency)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                commitment.urgency = i
                            } label: {
                                Image(systemName: i <= commitment.urgency ? "bolt.fill" : "bolt")
                                    .font(.body)
                                    .foregroundStyle(i <= commitment.urgency ? .orange : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                    Text(commitment.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .font(.caption)
                
                LabeledContent("Updated") {
                    Text(commitment.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .font(.caption)
                
                if let completedAt = commitment.completedAt {
                    LabeledContent("Completed") {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                    .font(.caption)
                }
                
                if commitment.aiGenerated {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("AI Generated")
                    }
                    .font(.caption)
                    .foregroundStyle(.purple)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    #endif
}

#Preview {
    NavigationStack {
        CommitmentDetailView(commitment: Commitment(title: "Review proposal"))
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


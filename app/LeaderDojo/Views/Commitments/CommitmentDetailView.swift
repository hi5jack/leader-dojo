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
            
            // Counterparty
            HStack {
                Label("Counterparty", systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(commitment.counterparty ?? "Not specified")
                    .font(.subheadline)
                    .foregroundStyle(commitment.counterparty != nil ? .primary : .secondary)
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
            
            Text(notes)
                .font(.body)
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
            }
            
            // Source Entry
            if let entry = commitment.sourceEntry {
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
    let sourceEntry: Entry?
    var preselectedDirection: CommitmentDirection = .iOwe
    
    @State private var title: String = ""
    @State private var direction: CommitmentDirection = .iOwe
    @State private var counterparty: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var importance: Int = 3
    @State private var urgency: Int = 3
    @State private var notes: String = ""
    @State private var selectedProject: Project?
    
    @Query(sort: \Project.name)
    private var allProjects: [Project]
    
    private var activeProjects: [Project] {
        allProjects.filter { $0.status == .active }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What's the commitment?", text: $title)
                    
                    Picker("Direction", selection: $direction) {
                        ForEach(CommitmentDirection.allCases, id: \.self) { dir in
                            Label(dir.displayName, systemImage: dir.icon)
                                .tag(dir)
                        }
                    }
                    
                    TextField("Counterparty (optional)", text: $counterparty)
                }
                
                Section {
                    if project == nil {
                        Picker("Project", selection: $selectedProject) {
                            Text("None").tag(nil as Project?)
                            ForEach(activeProjects) { proj in
                                Text(proj.name).tag(proj as Project?)
                            }
                        }
                    }
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
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
                        createCommitment()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                direction = preselectedDirection
                selectedProject = project
            }
        }
    }
    
    private func createCommitment() {
        let commitment = Commitment(
            title: title,
            direction: direction,
            counterparty: counterparty.isEmpty ? nil : counterparty,
            dueDate: hasDueDate ? dueDate : nil,
            importance: importance,
            urgency: urgency,
            notes: notes.isEmpty ? nil : notes
        )
        
        commitment.project = project ?? selectedProject
        commitment.sourceEntry = sourceEntry
        
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
            Form {
                Section {
                    TextField("Title", text: $commitment.title)
                    
                    Picker("Direction", selection: $commitment.direction) {
                        ForEach(CommitmentDirection.allCases, id: \.self) { dir in
                            Label(dir.displayName, systemImage: dir.icon)
                                .tag(dir)
                        }
                    }
                    
                    TextField("Counterparty", text: Binding(
                        get: { commitment.counterparty ?? "" },
                        set: { commitment.counterparty = $0.isEmpty ? nil : $0 }
                    ))
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
    }
}

#Preview {
    NavigationStack {
        CommitmentDetailView(commitment: Commitment(title: "Review proposal"))
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


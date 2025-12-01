import SwiftUI
import SwiftData

/// What type of item to capture
enum CaptureMode: String, CaseIterable {
    case entry = "Entry"
    case commitment = "Commitment"
    
    var icon: String {
        switch self {
        case .entry: return "doc.text"
        case .commitment: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .entry: return .blue
        case .commitment: return .indigo
        }
    }
}

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Project.lastActiveAt, order: .reverse)
    private var allProjects: [Project]
    
    @Query(sort: \Person.name)
    private var allPeople: [Person]
    
    private var activeProjects: [Project] {
        allProjects.filter { $0.status == .active }
    }
    
    // Shared state
    @State private var captureMode: CaptureMode = .entry
    @State private var selectedProject: Project?
    @State private var isSaving: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    // Entry-specific state
    @State private var selectedEntryKind: EntryKind = .note
    @State private var entryTitle: String = ""
    @State private var noteContent: String = ""
    @State private var selectedParticipants: [Person] = []
    
    // Commitment-specific state
    @State private var commitmentTitle: String = ""
    @State private var commitmentDirection: CommitmentDirection = .iOwe
    @State private var selectedPerson: Person? = nil
    @State private var commitmentNotes: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    
    @FocusState private var isTextEditorFocused: Bool
    
    /// Entry kinds available for quick capture
    private var captureEntryKinds: [EntryKind] {
        [.note, .meeting, .update, .decision, .reflection, .prep]
    }
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            captureContent
        }
        #else
        captureContent
        #endif
    }
    
    private var captureContent: some View {
        VStack(spacing: 0) {
            // Content area
            ScrollView {
                VStack(spacing: 24) {
                    // Capture mode selector
                    captureModeSelector
                    
                    // Project selector (always shown)
                    projectSelector
                    
                    if captureMode == .entry {
                        // Entry-specific fields
                        entryTypeSelector
                        
                        // Participants picker (for meetings and updates)
                        if selectedEntryKind == .meeting || selectedEntryKind == .update {
                            participantsSelector
                        }
                        
                        // Title input
                        titleInput
                        
                        // Text input
                        textInput
                        
                        // Quick tips
                        quickTips
                    } else {
                        // Commitment-specific fields
                        commitmentDirectionSelector
                        
                        commitmentPersonSelector
                        
                        commitmentTitleInput
                        
                        commitmentDueDateSelector
                        
                        commitmentNotesInput
                        
                        commitmentTips
                    }
                }
                .padding()
            }
            
            // Save button (fixed at bottom)
            saveButton
        }
        .navigationTitle("Quick Capture")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear {
            // Auto-select most recent project
            if selectedProject == nil {
                selectedProject = activeProjects.first
            }
        }
        .overlay(alignment: .top) {
            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Capture Mode Selector
    
    private var captureModeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Capture Type")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(CaptureMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            captureMode = mode
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: mode.icon)
                            Text(mode.rawValue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            captureMode == mode
                                ? mode.color.opacity(0.2)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    captureMode == mode ? mode.color : Color.secondary.opacity(0.3),
                                    lineWidth: captureMode == mode ? 2 : 1
                                )
                        )
                        .foregroundStyle(captureMode == mode ? mode.color : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Project Selector
    
    private var projectSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(activeProjects) { project in
                    Button {
                        selectedProject = project
                    } label: {
                        HStack {
                            Text(project.name)
                            if selectedProject?.id == project.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                NavigationLink {
                    NewProjectView()
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            } label: {
                HStack {
                    if let project = selectedProject {
                        Image(systemName: project.type.icon)
                            .foregroundStyle(.secondary)
                        Text(project.name)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Select a project")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Entry Type Selector
    
    private var entryTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entry Type")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(captureEntryKinds, id: \.self) { kind in
                    Button {
                        selectedEntryKind = kind
                    } label: {
                        HStack {
                            Label(kind.displayName, systemImage: kind.icon)
                            if selectedEntryKind == kind {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedEntryKind.icon)
                        .foregroundStyle(entryKindColor(selectedEntryKind))
                    Text(selectedEntryKind.displayName)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
    
    private func entryKindColor(_ kind: EntryKind) -> Color {
        switch kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note, ._legacyCommitment: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        }
    }
    
    // MARK: - Participants Selector
    
    private var participantsSelector: some View {
        MultiPersonPicker(
            selection: $selectedParticipants,
            label: "Participants",
            placeholder: "Add participants (optional)"
        )
    }
    
    // MARK: - Title Input
    
    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("Brief title for this entry", text: $entryTitle)
                .textFieldStyle(.plain)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Text Input
    
    private var textInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(contentLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(noteContent.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            TextEditor(text: $noteContent)
                .focused($isTextEditorFocused)
                .frame(minHeight: 200)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if noteContent.isEmpty {
                        Text(contentPlaceholder)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 28)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    private var contentLabel: String {
        "Content"
    }
    
    private var contentPlaceholder: String {
        switch selectedEntryKind {
        case .meeting: return "Meeting notes and key takeaways..."
        case .update: return "What's the latest update?"
        case .decision: return "What was decided and why?"
        case .reflection: return "Your thoughts and reflections..."
        case .prep: return "What do you need to prepare?"
        case .note, ._legacyCommitment: return "What's on your mind? Quick thoughts, observations, follow-ups..."
        }
    }
    
    // MARK: - Quick Tips
    
    private var quickTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tips")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "lightbulb.fill", text: "Capture thoughts immediately after conversations")
                tipRow(icon: "arrow.up.right", text: "Use \"I need to...\" to track your commitments")
                tipRow(icon: "arrow.down.left", text: "Use \"Waiting on...\" to track what others owe you")
                tipRow(icon: "checkmark.seal", text: "Note any decisions made for future reference")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Commitment Direction Selector
    
    private var commitmentDirectionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direction")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(CommitmentDirection.allCases, id: \.self) { dir in
                    Button {
                        commitmentDirection = dir
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: dir.icon)
                            Text(dir.displayName)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            commitmentDirection == dir
                                ? (dir == .iOwe ? Color.orange : Color.blue).opacity(0.2)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    commitmentDirection == dir
                                        ? (dir == .iOwe ? Color.orange : Color.blue)
                                        : Color.secondary.opacity(0.3),
                                    lineWidth: commitmentDirection == dir ? 2 : 1
                                )
                        )
                        .foregroundStyle(commitmentDirection == dir ? (dir == .iOwe ? .orange : .blue) : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Commitment Person Selector
    
    private var commitmentPersonSelector: some View {
        PersonPicker(
            selection: $selectedPerson,
            label: "Person",
            placeholder: "Select person (optional if project selected)"
        )
    }
    
    // MARK: - Commitment Title Input
    
    private var commitmentTitleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's the commitment?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("Describe the commitment...", text: $commitmentTitle)
                .textFieldStyle(.plain)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Commitment Due Date Selector
    
    private var commitmentDueDateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $hasDueDate) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Set Due Date")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            if hasDueDate {
                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Commitment Notes Input
    
    private var commitmentNotesInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $commitmentNotes)
                .focused($isTextEditorFocused)
                .frame(minHeight: 100)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if commitmentNotes.isEmpty {
                        Text("Additional context or details...")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 28)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    // MARK: - Commitment Tips
    
    private var commitmentTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commitment Tips")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "arrow.up.right.circle.fill", text: "\"I Owe\" = things you promised to do")
                tipRow(icon: "arrow.down.left.circle.fill", text: "\"Waiting For\" = things others promised you")
                tipRow(icon: "person.fill", text: "Associate with a person for better tracking")
                tipRow(icon: "calendar", text: "Set due dates to stay accountable")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                if captureMode == .entry {
                    saveEntry()
                } else {
                    saveCommitment()
                }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: captureMode == .entry ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                    Text(isSaving ? "Saving..." : saveButtonLabel)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? captureMode.color : Color.gray, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(!canSave || isSaving)
            .padding()
        }
        .background(.ultraThinMaterial)
    }
    
    private var saveButtonLabel: String {
        if captureMode == .entry {
            return "Capture \(selectedEntryKind.displayName)"
        } else {
            return "Create Commitment"
        }
    }
    
    // MARK: - Toast View
    
    private var toastView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(toastMessage)
                .font(.subheadline)
        }
        .padding()
        .background(.ultraThickMaterial, in: Capsule())
        .shadow(radius: 10)
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        if captureMode == .entry {
            return selectedProject != nil && !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            // Commitment requires title and (project OR person)
            let hasTitle = !commitmentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasContext = selectedProject != nil || selectedPerson != nil
            return hasTitle && hasContext
        }
    }
    
    // MARK: - Actions
    
    private func saveEntry() {
        guard let project = selectedProject else { return }
        
        isSaving = true
        isTextEditorFocused = false
        
        // Create the entry
        let entry = Entry(
            kind: selectedEntryKind,
            title: generateTitle(),
            occurredAt: Date(),
            rawContent: noteContent
        )
        entry.project = project
        
        // Add participants if any
        if !selectedParticipants.isEmpty {
            entry.participants = selectedParticipants
        }
        
        modelContext.insert(entry)
        
        // Update project's last active timestamp
        project.markActive()
        
        do {
            try modelContext.save()
            
            // Show success toast
            toastMessage = "\(selectedEntryKind.displayName) saved to \(project.name)"
            withAnimation {
                showToast = true
            }
            
            // Clear the form
            entryTitle = ""
            noteContent = ""
            selectedEntryKind = .note
            selectedParticipants = []
            
            // Hide toast after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showToast = false
                }
            }
        } catch {
            toastMessage = "Failed to save"
            withAnimation {
                showToast = true
            }
        }
        
        isSaving = false
    }
    
    private func saveCommitment() {
        isSaving = true
        isTextEditorFocused = false
        
        // Create the commitment
        let commitment = Commitment(
            title: commitmentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            direction: commitmentDirection,
            dueDate: hasDueDate ? dueDate : nil,
            importance: 3, // Default importance
            urgency: 3,    // Default urgency
            notes: commitmentNotes.isEmpty ? nil : commitmentNotes
        )
        commitment.project = selectedProject
        commitment.person = selectedPerson
        
        modelContext.insert(commitment)
        
        // Update project's last active timestamp if applicable
        selectedProject?.markActive()
        
        do {
            try modelContext.save()
            
            // Show success toast
            let contextName = selectedProject?.name ?? selectedPerson?.name ?? "your list"
            toastMessage = "Commitment saved to \(contextName)"
            withAnimation {
                showToast = true
            }
            
            // Clear the form
            commitmentTitle = ""
            commitmentDirection = .iOwe
            selectedPerson = nil
            commitmentNotes = ""
            hasDueDate = false
            dueDate = Date()
            
            // Hide toast after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showToast = false
                }
            }
        } catch {
            toastMessage = "Failed to save"
            withAnimation {
                showToast = true
            }
        }
        
        isSaving = false
    }
    
    private func generateTitle() -> String {
        // Use provided title if available
        let trimmedTitle = entryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }
        
        // Generate a title from the first line or first few words
        let firstLine = noteContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""
        
        let words = firstLine.components(separatedBy: .whitespaces).prefix(8)
        var title = words.joined(separator: " ")
        
        if title.count > 50 {
            title = String(title.prefix(47)) + "..."
        } else if title.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            title = "\(selectedEntryKind.displayName) - \(formatter.string(from: Date()))"
        }
        
        return title
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Person.self], inMemory: true)
}


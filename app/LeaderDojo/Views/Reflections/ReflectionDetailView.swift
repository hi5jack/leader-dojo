import SwiftUI
import SwiftData

struct ReflectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var reflection: Reflection
    
    @Query private var allEntries: [Entry]
    @Query private var allCommitments: [Commitment]
    
    @State private var isEditing: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var showingNewCommitment: Bool = false
    @State private var newCommitmentTitle: String = ""
    @State private var newCommitmentDirection: CommitmentDirection = .iOwe
    @State private var commitmentSourceQuestion: String = ""
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Header
                reflectionHeader
                
                // Mood (if set)
                if let mood = reflection.mood {
                    moodSection(mood)
                }
                
                // Linked entries (if any)
                if reflection.hasLinkedEntries {
                    linkedEntriesSection
                }
                
                // Stats (if available)
                if let stats = reflection.stats {
                    statsSection(stats)
                }
                
                // Tags/themes
                if !reflection.tags.isEmpty {
                    tagsSection
                }
                
                // Questions and Answers
                questionsSection
                
                // Generated commitments
                if reflection.hasGeneratedCommitments {
                    generatedCommitmentsSection
                }
            }
            .padding()
        }
        .navigationTitle(reflection.shortTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Label(isEditing ? "Done Editing" : "Edit Answers", systemImage: "pencil")
                    }
                    
                    Button {
                        showingNewCommitment = true
                        newCommitmentTitle = ""
                        commitmentSourceQuestion = ""
                    } label: {
                        Label("Add Commitment", systemImage: "plus.circle")
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
        .alert("Delete Reflection", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(reflection)
                try? modelContext.save()
            }
        } message: {
            Text("Are you sure you want to delete this reflection?")
        }
        .sheet(isPresented: $showingNewCommitment) {
            newCommitmentSheet
        }
    }
    
    // MARK: - Header
    
    private var reflectionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type and status badges
            HStack(spacing: 8) {
                Badge(text: reflection.reflectionType.displayName, icon: reflection.reflectionType.icon, color: reflectionTypeColor)
                
                if let periodType = reflection.periodType {
                    Badge(text: periodType.displayName, icon: periodType.icon, color: periodColor)
                }
                
                if reflection.isComplete {
                    Badge(text: "Complete", icon: "checkmark.circle.fill", color: .green)
                } else {
                    Badge(text: "In Progress", icon: "circle.dashed", color: .orange)
                }
            }
            
            // Title/context
            Text(reflection.periodDisplay)
                .font(.title2)
                .fontWeight(.bold)
            
            // Period dates (for periodic reflections)
            if let periodStart = reflection.periodStart, let periodEnd = reflection.periodEnd {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("\(periodStart, style: .date) - \(periodEnd, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Project/Person context
            if let project = reflection.project {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.indigo)
                    Text(project.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let person = reflection.person {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.pink)
                    Text(person.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Created \(reflection.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Mood Section
    
    private func moodSection(_ mood: ReflectionMood) -> some View {
        HStack {
            Text(mood.emoji)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Mood")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(mood.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Linked Entries Section
    
    private var linkedEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Linked Events", systemImage: "link")
                .font(.headline)
            
            let linkedEntries = getLinkedEntries()
            
            if linkedEntries.isEmpty {
                Text("No linked entries found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(linkedEntries) { entry in
                    linkedEntryRow(entry)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func linkedEntryRow(_ entry: Entry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.icon)
                .foregroundStyle(entryKindColor(entry.kind))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack {
                    Text(entry.kind.displayName)
                    Text("•")
                    Text(entry.occurredAt, style: .date)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if entry.isDecision {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.purple)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Stats Section
    
    private func statsSection(_ stats: ReflectionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Period Statistics", systemImage: "chart.bar.fill")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MiniStatView(title: "Entries", value: stats.entriesCreated, icon: "doc.text.fill", color: .blue)
                MiniStatView(title: "Meetings", value: stats.meetingsHeld, icon: "person.2.fill", color: .green)
                MiniStatView(title: "Decisions", value: stats.decisionsRecorded, icon: "checkmark.seal.fill", color: .purple)
                MiniStatView(title: "Created", value: stats.commitmentsCreated, icon: "plus.circle.fill", color: .orange)
                MiniStatView(title: "Completed", value: stats.commitmentsCompleted, icon: "checkmark.circle.fill", color: .green)
                MiniStatView(title: "Open", value: stats.iOweOpen, icon: "circle", color: .red)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Themes", systemImage: "tag.fill")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(reflection.tags, id: \.self) { tag in
                    Text(tag.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1), in: Capsule())
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Questions Section
    
    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Reflections", systemImage: "brain.head.profile")
                    .font(.headline)
                
                Spacer()
                
                Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(Array(reflection.questionsAnswers.enumerated()), id: \.element.id) { index, qa in
                qaCard(qa: qa, index: index)
            }
        }
    }
    
    // MARK: - QA Card
    
    private func qaCard(qa: ReflectionQA, index: Int) -> some View {
        let answerBinding = Binding<String>(
            get: { qa.answer },
            set: { newValue in
                var updatedQA = reflection.questionsAnswers
                updatedQA[index].answer = newValue
                reflection.questionsAnswers = updatedQA
            }
        )
        
        let hasAnswer = !qa.answer.isEmpty
        let backgroundColor: Color = hasAnswer
            ? Color.purple.opacity(0.05)
            : Color.orange.opacity(0.05)
        let borderColor: Color = hasAnswer
            ? Color.purple.opacity(0.2)
            : Color.orange.opacity(0.2)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("\(index + 1).")
                    .font(.headline)
                    .foregroundStyle(.purple)
                    .frame(width: 24, alignment: .leading)
                
                Text(qa.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Add commitment from this answer
                if hasAnswer && !isEditing {
                    Button {
                        commitmentSourceQuestion = qa.question
                        newCommitmentTitle = ""
                        showingNewCommitment = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.purple.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Show linked entry context if available
            if let linkedEntryId = qa.linkedEntryId,
               let linkedEntry = allEntries.first(where: { $0.id == linkedEntryId }) {
                HStack {
                    Image(systemName: linkedEntry.kind.icon)
                        .font(.caption2)
                    Text(linkedEntry.title)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            
            if isEditing {
                TextEditor(text: answerBinding)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        Color.gray.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            } else {
                if hasAnswer {
                    MarkdownText(qa.answer)
                } else {
                    Text("No answer provided")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            backgroundColor,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Generated Commitments Section
    
    private var generatedCommitmentsSection: some View {
        let commitments = getGeneratedCommitments()
        
        return VStack(alignment: .leading, spacing: 12) {
            Label("Commitments from Reflection", systemImage: "checkmark.circle")
                .font(.headline)
                .foregroundStyle(.indigo)
            
            if commitments.isEmpty {
                Text("No commitments found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(commitments) { commitment in
                    commitmentRow(commitment)
                }
            }
        }
        .padding()
        .background(.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func commitmentRow(_ commitment: Commitment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: commitment.status == .done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(commitment.status == .done ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(commitment.title)
                    .font(.subheadline)
                    .strikethrough(commitment.status == .done)
                
                HStack {
                    Label(commitment.direction.displayName, systemImage: commitment.direction.icon)
                        .font(.caption2)
                        .foregroundStyle(commitment.direction == .iOwe ? .orange : .blue)
                    
                    if let person = commitment.person {
                        Text("• \(person.name)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - New Commitment Sheet
    
    private var newCommitmentSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you commit to?", text: $newCommitmentTitle)
                    
                    Picker("Direction", selection: $newCommitmentDirection) {
                        ForEach(CommitmentDirection.allCases, id: \.self) { direction in
                            Label(direction.displayName, systemImage: direction.icon)
                                .tag(direction)
                        }
                    }
                } header: {
                    Text("New Commitment")
                } footer: {
                    if !commitmentSourceQuestion.isEmpty {
                        Text("From reflection: \"\(commitmentSourceQuestion)\"")
                    }
                }
            }
            .navigationTitle("Add Commitment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNewCommitment = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        createCommitmentFromReflection()
                    }
                    .disabled(newCommitmentTitle.isEmpty)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
    
    // MARK: - Actions
    
    private func createCommitmentFromReflection() {
        let commitment = Commitment(
            title: newCommitmentTitle,
            direction: newCommitmentDirection
        )
        commitment.project = reflection.project
        commitment.notes = "Created from reflection: \(commitmentSourceQuestion)"
        
        modelContext.insert(commitment)
        
        // Track that this commitment came from this reflection
        reflection.addGeneratedCommitment(commitment.id)
        
        try? modelContext.save()
        showingNewCommitment = false
    }
    
    // MARK: - Helper Methods
    
    private func getLinkedEntries() -> [Entry] {
        var entries: [Entry] = []
        
        // Get source entry if quick reflection
        if let sourceEntry = reflection.sourceEntry {
            entries.append(sourceEntry)
        }
        
        // Get entries by ID
        let linkedIds = reflection.linkedEntryIds
        let linkedById = allEntries.filter { linkedIds.contains($0.id) }
        entries.append(contentsOf: linkedById)
        
        // Dedupe and sort
        let uniqueEntries = Array(Set(entries))
        return uniqueEntries.sorted { $0.occurredAt > $1.occurredAt }
    }
    
    private func getGeneratedCommitments() -> [Commitment] {
        let commitmentIds = reflection.generatedCommitmentIds
        return allCommitments.filter { commitmentIds.contains($0.id) }
    }
    
    private func entryKindColor(_ kind: EntryKind) -> Color {
        switch kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        }
    }
    
    // MARK: - Computed Properties
    
    private var reflectionTypeColor: Color {
        switch reflection.reflectionType {
        case .quick: return .orange
        case .periodic: return .blue
        case .project: return .indigo
        case .relationship: return .pink
        }
    }
    
    private var periodColor: Color {
        switch reflection.periodType {
        case .week: return .blue
        case .month: return .purple
        case .quarter: return .cyan
        case .none: return .gray
        }
    }
}

#Preview {
    let reflection = Reflection(
        reflectionType: .periodic,
        periodType: .week,
        periodStart: Date(),
        periodEnd: Date(),
        mood: .confident,
        questionsAnswers: [
            ReflectionQA(question: "What was your biggest win?", answer: "Closed the deal with Company X"),
            ReflectionQA(question: "What would you do differently?", answer: "")
        ],
        tags: ["delegation", "communication"]
    )
    
    return NavigationStack {
        ReflectionDetailView(reflection: reflection)
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}

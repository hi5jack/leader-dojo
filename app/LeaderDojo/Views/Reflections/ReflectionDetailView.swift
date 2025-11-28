import SwiftUI
import SwiftData

struct ReflectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var reflection: Reflection
    
    @State private var isEditing: Bool = false
    @State private var showingDeleteAlert: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Header
                reflectionHeader
                
                // Stats (if available)
                if let stats = reflection.stats {
                    statsSection(stats)
                }
                
                // Questions and Answers
                questionsSection
            }
            .padding()
        }
        .navigationTitle(reflection.periodDisplay)
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
    }
    
    // MARK: - Header
    
    private var reflectionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let periodType = reflection.periodType {
                    Badge(text: periodType.displayName, icon: periodType.icon, color: periodColor)
                }
                
                if reflection.isComplete {
                    Badge(text: "Complete", icon: "checkmark.circle.fill", color: .green)
                } else {
                    Badge(text: "In Progress", icon: "circle.dashed", color: .orange)
                }
            }
            
            if let periodStart = reflection.periodStart, let periodEnd = reflection.periodEnd {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("\(periodStart, style: .date) - \(periodEnd, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Created \(reflection.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
                    Text(qa.answer)
                        .font(.body)
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
    
    // MARK: - Computed Properties
    
    private var periodColor: Color {
        switch reflection.periodType {
        case .week: return .blue
        case .month: return .purple
        case .quarter: return .orange
        case .none: return .gray
        }
    }
}

#Preview {
    let reflection = Reflection(
        periodType: .week,
        periodStart: Date(),
        periodEnd: Date(),
        questionsAnswers: [
            ReflectionQA(question: "What was your biggest win?", answer: "Closed the deal with Company X"),
            ReflectionQA(question: "What would you do differently?", answer: "")
        ]
    )
    
    return NavigationStack {
        ReflectionDetailView(reflection: reflection)
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}


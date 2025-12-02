import SwiftUI
import SwiftData

/// A lightweight sheet for quick post-event reflections
/// Appears after completing an entry marked as key decision or meeting
struct QuickReflectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let entry: Entry
    let onDismiss: () -> Void
    
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var mood: ReflectionMood? = nil
    @State private var isLoadingQuestion: Bool = true
    @State private var isSaving: Bool = false
    @State private var confidenceLevel: Int = 3 // 1-5 scale
    
    /// Quick mood options for fast selection
    private let quickMoods: [ReflectionMood] = [.confident, .uncertain, .energized, .drained, .neutral]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with time estimate
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Entry context
                        entryContextCard
                        
                        // Question
                        questionSection
                        
                        // Quick mood/confidence selector
                        moodSelector
                        
                        // Optional thought
                        optionalThoughtSection
                    }
                    .padding()
                }
                
                // Action buttons
                actionButtons
            }
            .navigationTitle("Quick Reflection")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .task {
                await loadQuestion()
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.purple)
            
            Text("30 seconds")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("Quick Reflection")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.purple)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    // MARK: - Entry Context
    
    private var entryContextCard: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.icon)
                .font(.title2)
                .foregroundStyle(kindColor)
                .frame(width: 40, height: 40)
                .background(kindColor.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.kind.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var kindColor: Color {
        switch entry.kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoadingQuestion {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating question...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Text(question)
                    .font(.title3)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Mood Selector
    
    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How did it go?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(quickMoods, id: \.self) { moodOption in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            mood = moodOption
                        }
                        // Haptic feedback
                        #if os(iOS)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        #endif
                    } label: {
                        VStack(spacing: 4) {
                            Text(moodOption.emoji)
                                .font(.title)
                            Text(moodOption.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            mood == moodOption ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(mood == moodOption ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Optional Thought
    
    private var optionalThoughtSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Add a thought")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            TextField("What's on your mind?", text: $answer, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding()
                .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                Button {
                    onDismiss()
                    dismiss()
                } label: {
                    Text("Not now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    saveQuickReflection()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Save")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(mood == nil || isSaving || isLoadingQuestion)
            }
            .padding()
        }
        .background(.bar)
    }
    
    // MARK: - Actions
    
    private func loadQuestion() async {
        isLoadingQuestion = true
        
        do {
            let generatedQuestion = try await AIService.shared.generateQuickReflectionQuestion(entry: entry)
            await MainActor.run {
                question = generatedQuestion
                isLoadingQuestion = false
            }
        } catch {
            // Guardrail: Fall back to default question
            await MainActor.run {
                question = defaultQuestionForEntry()
                isLoadingQuestion = false
            }
        }
    }
    
    private func defaultQuestionForEntry() -> String {
        switch entry.kind {
        case .meeting:
            return "How confident are you in the outcomes from this meeting?"
        case .decision:
            return "Looking back, how do you feel about this decision?"
        case .update:
            return "What's the most important takeaway from this update?"
        case .note:
            return "What made this worth noting?"
        case .prep:
            return "How prepared do you feel after this?"
        case .reflection:
            return "What insight stands out to you?"
        }
    }
    
    private func saveQuickReflection() {
        guard let selectedMood = mood else { return }
        
        isSaving = true
        
        // Create the quick reflection
        let reflection = Reflection(
            quickReflectionFor: entry,
            mood: selectedMood,
            question: question,
            answer: answer
        )
        
        modelContext.insert(reflection)
        
        do {
            try modelContext.save()
            
            // Haptic feedback for success
            #if os(iOS)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            #endif
            
            isSaving = false
            onDismiss()
            dismiss()
        } catch {
            isSaving = false
        }
    }
}

// MARK: - Quick Reflection Trigger

/// Determines whether to show a quick reflection prompt
struct QuickReflectionTrigger {
    /// Maximum number of quick reflection prompts per day (Guardrail: Prompting strategy)
    static let maxPromptsPerDay = 3
    
    /// Entry types that should trigger quick reflection prompts
    static let triggerEntryKinds: Set<EntryKind> = [.meeting, .decision]
    
    /// Check if we should prompt for a quick reflection after saving this entry
    static func shouldPrompt(for entry: Entry, existingReflectionsToday: Int) -> Bool {
        // Don't exceed daily limit
        guard existingReflectionsToday < maxPromptsPerDay else { return false }
        
        // Only prompt for significant entry types
        guard triggerEntryKinds.contains(entry.kind) || entry.isDecision else { return false }
        
        // Don't prompt for very short entries
        let contentLength = (entry.rawContent?.count ?? 0) + entry.title.count
        guard contentLength > 20 else { return false }
        
        return true
    }
    
    /// Count of quick reflections created today
    static func quickReflectionsToday(from reflections: [Reflection]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return reflections.filter { reflection in
            reflection.reflectionType == .quick &&
            calendar.isDate(reflection.createdAt, inSameDayAs: today)
        }.count
    }
}

// MARK: - Preview

#Preview {
    let entry = Entry(
        kind: .meeting,
        title: "Weekly sync with product team",
        occurredAt: Date(),
        rawContent: "Discussed Q4 roadmap priorities and resource allocation."
    )
    
    return QuickReflectionSheet(entry: entry) {
        print("Dismissed")
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}



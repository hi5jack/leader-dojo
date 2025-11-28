import SwiftUI
import SwiftData

struct NewReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let periodType: ReflectionPeriodType
    
    @State private var isLoadingQuestions: Bool = true
    @State private var questionsAnswers: [ReflectionQA] = []
    @State private var stats: ReflectionStats = ReflectionStats()
    @State private var error: String? = nil
    @State private var currentQuestionIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoadingQuestions {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if questionsAnswers.isEmpty {
                    noQuestionsView
                } else {
                    questionAnswerView
                }
            }
            .navigationTitle("\(periodType.displayName) Reflection")
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
                        saveReflection()
                    }
                    .disabled(isLoadingQuestions)
                }
            }
            .task {
                await loadQuestionsAndStats()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            
            Text("Analyzing your activity...")
                .font(.headline)
            
            Text("Generating personalized reflection questions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Couldn't generate questions")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Use Default Questions") {
                useDefaultQuestions()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Try Again") {
                Task {
                    await loadQuestionsAndStats()
                }
            }
        }
        .padding()
    }
    
    // MARK: - No Questions View
    
    private var noQuestionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No questions generated")
                .font(.headline)
            
            Button("Use Default Questions") {
                useDefaultQuestions()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Question Answer View
    
    private var questionAnswerView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats Summary
                statsSummary
                
                // Progress indicator
                progressIndicator
                
                // Questions
                ForEach($questionsAnswers) { $qa in
                    questionCard(qa: $qa)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Stats Summary
    
    private var statsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your \(periodType.displayName) Activity", systemImage: "chart.bar.fill")
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
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(answeredCount)/\(questionsAnswers.count) answered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: Double(answeredCount), total: Double(questionsAnswers.count))
                .tint(.purple)
        }
    }
    
    // MARK: - Question Card
    
    private func questionCard(qa: Binding<ReflectionQA>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.purple)
                
                Text(qa.wrappedValue.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            TextEditor(text: qa.answer)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    
    private var answeredCount: Int {
        questionsAnswers.filter { !$0.answer.isEmpty }.count
    }
    
    // MARK: - Actions
    
    private func loadQuestionsAndStats() async {
        isLoadingQuestions = true
        error = nil
        
        // Calculate stats
        await calculateStats()
        
        // Generate AI questions
        do {
            let questions = try await AIService.shared.generateReflectionQuestions(
                periodType: periodType,
                stats: stats
            )
            
            await MainActor.run {
                questionsAnswers = questions.map { ReflectionQA(question: $0) }
                isLoadingQuestions = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoadingQuestions = false
            }
        }
    }
    
    private func calculateStats() async {
        // This would need to query the model context for actual stats
        // For now, using placeholder logic
        await MainActor.run {
            stats = ReflectionStats(
                entriesCreated: 0,
                commitmentsCreated: 0,
                commitmentsCompleted: 0,
                iOweOpen: 0,
                waitingForOpen: 0,
                projectsActive: 0,
                meetingsHeld: 0,
                decisionsRecorded: 0
            )
        }
    }
    
    private func useDefaultQuestions() {
        let defaultQuestions: [String]
        switch periodType {
        case .week:
            defaultQuestions = [
                "What was your biggest win this week?",
                "What commitment did you struggle to keep? Why?",
                "Which conversation or decision would you handle differently?",
                "What pattern do you notice in how you spent your time?",
                "What's one thing you want to do better next week?"
            ]
        case .month:
            defaultQuestions = [
                "What progress did you make on your most important projects?",
                "Which relationships received the most attention? Which were neglected?",
                "What decisions are you most and least confident about?",
                "What feedback have you received and how have you acted on it?",
                "What's the most important lesson you learned this month?"
            ]
        case .quarter:
            defaultQuestions = [
                "Looking at your projects, what themes emerge in where you invested time?",
                "How has your leadership style evolved this quarter?",
                "What commitments did you consistently keep or break?",
                "What were the three most impactful decisions you made?",
                "What do you want to be different about next quarter?"
            ]
        }
        
        questionsAnswers = defaultQuestions.map { ReflectionQA(question: $0) }
        isLoadingQuestions = false
        error = nil
    }
    
    private func saveReflection() {
        let (periodStart, periodEnd) = calculatePeriodDates()
        
        let reflection = Reflection(
            periodType: periodType,
            periodStart: periodStart,
            periodEnd: periodEnd,
            questionsAnswers: questionsAnswers
        )
        reflection.stats = stats
        
        modelContext.insert(reflection)
        try? modelContext.save()
        dismiss()
    }
    
    private func calculatePeriodDates() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch periodType {
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            return (startOfMonth, endOfMonth)
        case .quarter:
            let month = calendar.component(.month, from: now)
            let quarterStart = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStart
            components.day = 1
            let startOfQuarter = calendar.date(from: components)!
            let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter)!
            return (startOfQuarter, endOfQuarter)
        }
    }
}

// MARK: - Mini Stat View

struct MiniStatView: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NewReflectionView(periodType: .week)
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}


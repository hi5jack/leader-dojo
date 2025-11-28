import SwiftUI
import SwiftData

struct NewReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allEntries: [Entry]
    @Query private var allCommitments: [Commitment]
    @Query private var allProjects: [Project]
    
    let periodType: ReflectionPeriodType
    
    @State private var isLoadingQuestions: Bool = true
    @State private var questionsAnswers: [ReflectionQA] = []
    @State private var suggestions: [String] = []
    @State private var stats: ReflectionStats = ReflectionStats()
    @State private var error: String? = nil
    @State private var currentQuestionIndex: Int = 0
    @State private var periodStart: Date = Date()
    @State private var showingDatePicker: Bool = false
    
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
                // Period Selection
                periodSelection
                
                // Stats Summary
                statsSummary
                
                // AI Suggestions (if any)
                if !suggestions.isEmpty {
                    suggestionsSection
                }
                
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
    
    // MARK: - Period Selection
    
    private var periodSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Period Start", systemImage: "calendar")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(periodStart, style: .date)
                        .font(.body)
                    if let endDate = periodEndDate {
                        Text("to \(endDate, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showingDatePicker.toggle()
                } label: {
                    Text("Change")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            if showingDatePicker {
                DatePicker(
                    "Start Date",
                    selection: $periodStart,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .onChange(of: periodStart) { _, _ in
                    Task {
                        await recalculateStatsAndQuestions()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Suggestions Section
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Suggestions", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                        .padding(.top, 2)
                    
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
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
                .background(
                    Color.gray.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    
    private var answeredCount: Int {
        questionsAnswers.filter { !$0.answer.isEmpty }.count
    }
    
    private var periodEndDate: Date? {
        let calendar = Calendar.current
        switch periodType {
        case .week:
            return calendar.date(byAdding: .day, value: 6, to: periodStart)
        case .month:
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: periodStart) else { return nil }
            return calendar.date(byAdding: .day, value: -1, to: nextMonth)
        case .quarter:
            guard let nextQuarter = calendar.date(byAdding: .month, value: 3, to: periodStart) else { return nil }
            return calendar.date(byAdding: .day, value: -1, to: nextQuarter)
        }
    }
    
    private var periodStartDateNormalized: Date {
        let calendar = Calendar.current
        
        switch periodType {
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: periodStart)) ?? periodStart
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: periodStart)) ?? periodStart
        case .quarter:
            let month = calendar.component(.month, from: periodStart)
            let quarterStart = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: periodStart)
            components.month = quarterStart
            components.day = 1
            return calendar.date(from: components) ?? periodStart
        }
    }
    
    // MARK: - Actions
    
    private func loadQuestionsAndStats() async {
        isLoadingQuestions = true
        error = nil
        
        // Calculate stats from actual data
        calculateStats()
        
        // Generate AI questions and suggestions
        do {
            let result = try await AIService.shared.generateReflectionQuestions(
                periodType: periodType,
                stats: stats
            )
            
            await MainActor.run {
                questionsAnswers = result.questions.map { ReflectionQA(question: $0) }
                suggestions = result.suggestions
                isLoadingQuestions = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoadingQuestions = false
            }
        }
    }
    
    private func recalculateStatsAndQuestions() async {
        isLoadingQuestions = true
        error = nil
        
        // Recalculate stats with new period
        calculateStats()
        
        // Regenerate AI questions and suggestions
        do {
            let result = try await AIService.shared.generateReflectionQuestions(
                periodType: periodType,
                stats: stats
            )
            
            await MainActor.run {
                questionsAnswers = result.questions.map { ReflectionQA(question: $0) }
                suggestions = result.suggestions
                isLoadingQuestions = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoadingQuestions = false
            }
        }
    }
    
    private func calculateStats() {
        guard let endDate = periodEndDate else { return }
        let startDate = periodStartDateNormalized
        
        // Filter entries in the period
        let periodEntries = allEntries.filter { entry in
            entry.occurredAt >= startDate && entry.occurredAt <= endDate
        }
        
        // Filter commitments in the period
        let periodCommitments = allCommitments.filter { commitment in
            if let dueDate = commitment.dueDate {
                return dueDate >= startDate && dueDate <= endDate
            }
            return commitment.createdAt >= startDate && commitment.createdAt <= endDate
        }
        
        // Count active projects
        let activeProjects = allProjects.filter { project in
            project.status == .active
        }
        
        // Calculate stats
        stats = ReflectionStats(
            entriesCreated: periodEntries.count,
            commitmentsCreated: periodCommitments.count,
            commitmentsCompleted: periodCommitments.filter { $0.status == .done }.count,
            iOweOpen: allCommitments.filter { $0.direction == .iOwe && $0.status == .open }.count,
            waitingForOpen: allCommitments.filter { $0.direction == .waitingFor && $0.status == .open }.count,
            projectsActive: activeProjects.count,
            meetingsHeld: periodEntries.filter { $0.kind == .meeting }.count,
            decisionsRecorded: periodEntries.filter { $0.isDecision }.count
        )
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
        suggestions = []
        isLoadingQuestions = false
        error = nil
    }
    
    private func saveReflection() {
        let startDate = periodStartDateNormalized
        guard let endDate = periodEndDate else { return }
        
        let reflection = Reflection(
            periodType: periodType,
            periodStart: startDate,
            periodEnd: endDate,
            questionsAnswers: questionsAnswers
        )
        reflection.stats = stats
        reflection.aiQuestions = questionsAnswers.map { $0.question }
        
        modelContext.insert(reflection)
        try? modelContext.save()
        dismiss()
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


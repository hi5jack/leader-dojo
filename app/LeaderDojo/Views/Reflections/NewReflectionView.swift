import SwiftUI
import SwiftData

// MARK: - View State

enum ReflectionCreationStep: Int, CaseIterable {
    case selectPeriod = 0
    case selectEvents = 1
    case answerQuestions = 2
    case review = 3
    
    var title: String {
        switch self {
        case .selectPeriod: return "Period"
        case .selectEvents: return "Events"
        case .answerQuestions: return "Reflect"
        case .review: return "Review"
        }
    }
}

struct NewReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allEntries: [Entry]
    @Query private var allCommitments: [Commitment]
    @Query private var allProjects: [Project]
    
    let reflectionType: ReflectionType
    let periodType: ReflectionPeriodType?
    let project: Project?
    let person: Person?
    
    // State
    @State private var currentStep: ReflectionCreationStep = .selectPeriod
    @State private var isLoadingQuestions: Bool = false
    @State private var questionsAnswers: [ReflectionQA] = []
    @State private var suggestions: [String] = []
    @State private var stats: ReflectionStats = ReflectionStats()
    @State private var error: String? = nil
    @State private var periodStart: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var selectedEntryIds: Set<UUID> = []
    @State private var currentQuestionIndex: Int = 0
    @State private var mood: ReflectionMood? = nil
    @State private var usedFallbackQuestions: Bool = false
    
    // Voice input state
    @State private var speechService = SpeechRecognitionService()
    @State private var showVoiceOverlay: Bool = false
    @State private var voiceTargetQuestionIndex: Int = 0
    
    // Convenience initializer for periodic reflections
    init(periodType: ReflectionPeriodType) {
        self.reflectionType = .periodic
        self.periodType = periodType
        self.project = nil
        self.person = nil
    }
    
    // Convenience initializer for project reflections
    init(project: Project) {
        self.reflectionType = .project
        self.periodType = nil
        self.project = project
        self.person = nil
    }
    
    // Convenience initializer for relationship reflections
    init(person: Person) {
        self.reflectionType = .relationship
        self.periodType = nil
        self.project = nil
        self.person = person
    }
    
    // Full initializer
    init(
        reflectionType: ReflectionType,
        periodType: ReflectionPeriodType? = nil,
        project: Project? = nil,
        person: Person? = nil
    ) {
        self.reflectionType = reflectionType
        self.periodType = periodType
        self.project = project
        self.person = person
    }
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            rootContent
        }
        #else
        rootContent
        #endif
    }
    
    /// Platform-agnostic root content; wrapped in a `NavigationStack` on iOS only.
    private var rootContent: some View {
        Group {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
            #else
            macLayout
            #endif
        }
        .navigationTitle(navigationTitle)
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
                if currentStep == .review || currentStep == .answerQuestions {
                    Button("Save") {
                        saveReflection()
                    }
                    .disabled(isLoadingQuestions)
                }
            }
        }
        .task {
            await initializeReflection()
        }
        .voiceInputOverlay(
            isPresented: $showVoiceOverlay,
            speechService: speechService,
            title: currentQuestionTitle,
            accentColor: .purple
        ) { text in
            handleVoiceInputComplete(text)
        }
    }
    
    private var currentQuestionTitle: String {
        guard voiceTargetQuestionIndex < questionsAnswers.count else {
            return "Reflect"
        }
        return "Q\(voiceTargetQuestionIndex + 1)"
    }
    
    private func handleVoiceInputComplete(_ text: String) {
        guard voiceTargetQuestionIndex < questionsAnswers.count else { return }
        // Append voice text to existing answer
        if questionsAnswers[voiceTargetQuestionIndex].answer.isEmpty {
            questionsAnswers[voiceTargetQuestionIndex].answer = text
        } else {
            questionsAnswers[voiceTargetQuestionIndex].answer += "\n\n" + text
        }
    }
    
    private var navigationTitle: String {
        switch reflectionType {
        case .periodic:
            return "\(periodType?.displayName ?? "Periodic") Reflection"
        case .project:
            return "Project Reflection"
        case .relationship:
            return "Relationship Reflection"
        case .quick:
            return "Quick Reflection"
        }
    }
    
    // MARK: - iPhone Layout
    
    #if os(iOS)
    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressIndicator
            
            // Content based on step
            TabView(selection: $currentStep) {
                periodSelectionStep
                    .tag(ReflectionCreationStep.selectPeriod)
                
                eventSelectionStep
                    .tag(ReflectionCreationStep.selectEvents)
                
                questionAnswerStep
                    .tag(ReflectionCreationStep.answerQuestions)
                
                reviewStep
                    .tag(ReflectionCreationStep.review)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            // Navigation buttons
            navigationButtons
        }
    }
    #endif
    
    // MARK: - iPad Layout
    
    #if os(iOS)
    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left column: Context panel
            VStack(alignment: .leading, spacing: 16) {
                // Stats summary
                statsSummary
                    .padding()
                
                Divider()
                
                // Event selection (always visible on iPad)
                if reflectionType == .periodic {
                    Text("Highlight Events")
                .font(.headline)
                        .padding(.horizontal)
                    
                    eventSelectionList
                }
                
                Spacer()
            }
            .frame(width: 320)
            .background(Color(uiColor: .secondarySystemBackground))
            
            Divider()
            
            // Right column: Questions
            VStack(spacing: 0) {
                progressIndicator
                
                if isLoadingQuestions {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else {
                    questionAnswerContent
                }
                
                navigationButtons
            }
        }
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macLayout: some View {
        // HSplitView inside a sheet can collapse to zero height on macOS.
        // Use an HStack-based layout instead so the sheet gets a sensible intrinsic size.
        HStack(spacing: 0) {
            // Left column: Context panel
            VStack(alignment: .leading, spacing: 16) {
                // Period info (only for periodic reflections)
                if reflectionType == .periodic {
                    periodSelectionCompact
                }
                
                Divider()
                
                // Stats summary
                statsSummary
                
                Divider()

                Spacer()
            }
            .padding()
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 360, maxHeight: .infinity, alignment: .top)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Right column: Questions
            VStack(spacing: 0) {
                progressIndicator
                    .padding(.horizontal)
                    .padding(.top)
                
                macMainContent
                
                Divider()
                
                navigationButtons
                    .padding()
            }
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // Give the sheet a reasonable default size so content is visible immediately.
        .frame(minWidth: 800, minHeight: 500)
    }

    @ViewBuilder
    private var macMainContent: some View {
        switch currentStep {
        case .selectPeriod:
            // Period selection step (periodic reflections only)
            periodSelectionStep
        case .selectEvents:
            // Event selection step for periodic/project/relationship reflections
            eventSelectionStep
        case .answerQuestions:
            if isLoadingQuestions {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if questionsAnswers.isEmpty {
                noQuestionsView
            } else {
                questionAnswerContent
            }
        case .review:
            reviewStep
        }
    }
    #endif
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            // Step dots
            HStack(spacing: 8) {
                ForEach(Array(stepsForReflectionType.enumerated()), id: \.offset) { index, step in
                    Circle()
                        .fill(currentStep.rawValue >= step.rawValue ? Color.purple : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Question progress (when in answer step)
            if currentStep == .answerQuestions && !questionsAnswers.isEmpty {
                HStack {
                    Text("Question \(currentQuestionIndex + 1) of \(questionsAnswers.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(reflectionType.estimatedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(.bar)
    }
    
    private var stepsForReflectionType: [ReflectionCreationStep] {
        switch reflectionType {
        case .periodic:
            return [.selectPeriod, .selectEvents, .answerQuestions, .review]
        case .project, .relationship:
            return [.selectEvents, .answerQuestions, .review]
        case .quick:
            return [.answerQuestions]
        }
    }
    
    // MARK: - Period Selection Step
    
    private var periodSelectionStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                periodSelectionContent
            }
            .padding()
        }
    }
    
    private var periodSelectionCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Period")
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
                
                Button("Change") {
                    showingDatePicker.toggle()
                }
                .buttonStyle(.bordered)
            }
            
            if showingDatePicker {
                DatePicker("Start Date", selection: $periodStart, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .onChange(of: periodStart) { _, _ in
                        Task {
                            await recalculateStats()
                        }
                    }
            }
        }
    }
    
    private var periodSelectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Select Period", systemImage: "calendar")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(periodStart, style: .date)
                        .font(.title3)
                        .fontWeight(.medium)
                    if let endDate = periodEndDate {
                        Text("to \(endDate, style: .date)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showingDatePicker.toggle()
                } label: {
                    Text("Change")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            if showingDatePicker {
                DatePicker(
                    "Start Date",
                    selection: $periodStart,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .onChange(of: periodStart) { _, _ in
                    Task {
                        await recalculateStats()
                    }
                }
            }
            
            // Stats preview
            statsSummary
        }
    }
    
    // MARK: - Event Selection Step
    
    private var eventSelectionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Select Key Events", systemImage: "star.fill")
                    .font(.headline)
                
                Text("Choose the events you want to reflect on. We'll generate questions specific to what happened.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                eventSelectionList
        }
        .padding()
        }
    }
    
    private var eventSelectionList: some View {
        LazyVStack(spacing: 12) {
            ForEach(significantEntries) { entry in
                EventSelectionCard(
                    entry: entry,
                    isSelected: selectedEntryIds.contains(entry.id)
                ) {
                    toggleEntrySelection(entry)
                }
            }
            
            if significantEntries.isEmpty {
                ContentUnavailableView {
                    Label("No Events", systemImage: "doc.text")
                } description: {
                    Text("No significant events found for this period.")
                }
            }
        }
    }
    
    // MARK: - Question Answer Step
    
    private var questionAnswerStep: some View {
        VStack(spacing: 8) {
            if usedFallbackQuestions {
                fallbackNotice
            }
            
            Group {
                if isLoadingQuestions {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if questionsAnswers.isEmpty {
                    noQuestionsView
                } else {
                    questionAnswerContent
                }
            }
        }
    }
    
    private var questionAnswerContent: some View {
        #if os(iOS)
        // Card-based swipeable questions for iPhone
        TabView(selection: $currentQuestionIndex) {
            ForEach(Array(questionsAnswers.enumerated()), id: \.offset) { index, _ in
                questionCard(index: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        #else
        // Scrollable list for Mac/iPad
        ScrollView {
            LazyVStack(spacing: 16) {
                // Mood selector at top
                moodSelector
                
                ForEach(Array($questionsAnswers.enumerated()), id: \.offset) { index, $qa in
                    questionCardExpanded(qa: $qa, index: index)
                }
            }
            .padding()
        }
        #endif
    }
    
    private func questionCard(index: Int) -> some View {
        let qa = $questionsAnswers[index]
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Question number
                Text("Question \(index + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                // Linked entry context (if any)
                if let linkedId = qa.wrappedValue.linkedEntryId,
                   let entry = significantEntries.first(where: { $0.id == linkedId }) {
                    linkedEntryBadge(entry: entry)
                }
                
                // Question text
                Text(qa.wrappedValue.question)
                    .font(.title3)
                    .fontWeight(.medium)
                
                // Answer input
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: qa.answer)
                        .frame(minHeight: 150)
                        .padding(12)
                        .padding(.bottom, 40) // Space for voice button
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .overlay(alignment: .topLeading) {
                            if qa.wrappedValue.answer.isEmpty {
                                Text("Your thoughts...")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                    
                    // Voice input button
                    InlineVoiceButton(
                        isListening: false,
                        action: {
                            voiceTargetQuestionIndex = index
                            showVoiceOverlay = true
                        },
                        color: .purple
                    )
                    .padding(12)
                }
                
                // Mood selector (on first question)
                if index == 0 {
                    moodSelector
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    /// Shows linked entry context as a prominent badge
    private func linkedEntryBadge(entry: Entry) -> some View {
        HStack(spacing: 8) {
            Image(systemName: entry.kind.icon)
                .font(.caption)
                .foregroundStyle(entryKindColor(entry.kind))
            
            Text(entry.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
            
            Text(entry.occurredAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(entryKindColor(entry.kind).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(entryKindColor(entry.kind).opacity(0.3), lineWidth: 1)
        )
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
    
    private func questionCardExpanded(qa: Binding<ReflectionQA>, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("\(index + 1).")
                .font(.headline)
                    .foregroundStyle(.purple)
                    .frame(width: 24, alignment: .leading)
                
                Text(qa.wrappedValue.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Voice input button
                InlineVoiceButton(
                    isListening: false,
                    action: {
                        voiceTargetQuestionIndex = index
                        showVoiceOverlay = true
                    },
                    color: .purple
                )
            }
            
            TextEditor(text: qa.answer)
                .frame(minHeight: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you feeling?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(ReflectionMood.allCases, id: \.self) { moodOption in
                    Button {
                        mood = moodOption
                    } label: {
                        VStack(spacing: 4) {
                            Text(moodOption.emoji)
                                .font(.title2)
                            Text(moodOption.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            mood == moodOption ? Color.purple.opacity(0.2) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(mood == moodOption ? Color.purple : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Review Step
    
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if usedFallbackQuestions {
                    fallbackNotice
                }
                
                Label("Review", systemImage: "checkmark.circle")
                    .font(.headline)
                
                // Answers summary
                ForEach(Array(questionsAnswers.enumerated()), id: \.offset) { index, qa in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Q\(index + 1): \(qa.question)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(qa.answer.isEmpty ? "No answer" : qa.answer)
                            .font(.body)
                            .foregroundStyle(qa.answer.isEmpty ? .secondary : .primary)
                            .italic(qa.answer.isEmpty)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Mood summary
                if let mood = mood {
                    HStack {
                        Text("Mood:")
                            .foregroundStyle(.secondary)
                        Text(mood.emoji)
                        Text(mood.displayName)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Suggestions
                if !suggestions.isEmpty {
                    suggestionsSummary
                }
            }
            .padding()
        }
    }
    
    // MARK: - Shared Components
    
    /// Banner shown when AI timed out and we fell back to default questions
    private var fallbackNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Using fallback questions")
                    .font(.footnote)
                    .fontWeight(.semibold)
                Text("AI took too long to respond, so we’re using a generic set of questions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Activity Summary", systemImage: "chart.bar.fill")
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
    
    private var suggestionsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggestions", systemImage: "lightbulb.fill")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack {
            // Back button
            #if os(iOS)
            if currentStep == .answerQuestions && currentQuestionIndex > 0 {
                Button {
                    withAnimation {
                        currentQuestionIndex = max(0, currentQuestionIndex - 1)
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                }
                .buttonStyle(.bordered)
            } else if currentStep.rawValue > stepsForReflectionType.first?.rawValue ?? 0 {
                Button {
                    withAnimation {
                        goToPreviousStep()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
            }
            #else
            if currentStep.rawValue > stepsForReflectionType.first?.rawValue ?? 0 {
                Button {
                    withAnimation {
                        goToPreviousStep()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
            }
            #endif
            
            Spacer()
            
            // "Done for now" button (always visible per guardrail)
            if currentStep == .answerQuestions {
                Button("Done for now") {
                    saveReflection()
                }
                .foregroundStyle(.secondary)
            }
            
            if currentStep.rawValue < (stepsForReflectionType.last?.rawValue ?? 0) {
                #if os(iOS)
                if currentStep == .answerQuestions && !questionsAnswers.isEmpty {
                    Button {
                        withAnimation {
                            // On iPhone, advance through questions first, then move to Review
                            if currentQuestionIndex < questionsAnswers.count - 1 {
                                currentQuestionIndex += 1
                            } else {
                                goToNextStep()
                            }
                        }
                    } label: {
                        HStack {
                            Text(currentQuestionIndex < questionsAnswers.count - 1 ? "Next Question" : "Review")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        withAnimation {
                            goToNextStep()
                        }
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                #else
                Button {
                    withAnimation {
                        goToNextStep()
                    }
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                #endif
            }
        }
        .padding()
        .background(.bar)
    }
    
    // MARK: - Computed Properties
    
    private var periodEndDate: Date? {
        guard let type = periodType else { return nil }
        let calendar = Calendar.current
        switch type {
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
        guard let type = periodType else { return periodStart }
        let calendar = Calendar.current
        
        switch type {
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
    
    private var significantEntries: [Entry] {
        let filtered: [Entry]
        
        switch reflectionType {
        case .periodic:
            guard let endDate = periodEndDate else { return [] }
            let startDate = periodStartDateNormalized
            filtered = allEntries.filter { entry in
                entry.deletedAt == nil &&
                entry.occurredAt >= startDate &&
                entry.occurredAt <= endDate
            }
        case .project:
            filtered = allEntries.filter { entry in
                entry.deletedAt == nil &&
                entry.project?.id == project?.id
            }
        case .relationship:
            filtered = allEntries.filter { entry in
                entry.deletedAt == nil &&
                entry.participants?.contains(where: { $0.id == person?.id }) == true
            }
        case .quick:
            return []
        }
        
        // Sort by significance: decisions first, then meetings, then by date
        return filtered.sorted { e1, e2 in
            if e1.isDecision != e2.isDecision {
                return e1.isDecision
            }
            if e1.kind == .decision && e2.kind != .decision {
                return true
            }
            if e1.kind == .meeting && e2.kind != .meeting && e2.kind != .decision {
                return true
            }
            return e1.occurredAt > e2.occurredAt
        }.prefix(10).map { $0 }
    }
    
    private var selectedEntries: [Entry] {
        significantEntries.filter { selectedEntryIds.contains($0.id) }
    }
    
    private var openCommitments: [Commitment] {
        allCommitments.filter { $0.status == .open || $0.status == .blocked }
    }
    
    // MARK: - Actions
    
    /// Reset in-memory state for a fresh reflection session
    private func resetState() {
        questionsAnswers = []
        suggestions = []
        stats = ReflectionStats()
        error = nil
        isLoadingQuestions = false
        currentQuestionIndex = 0
        mood = nil
        selectedEntryIds = []
        usedFallbackQuestions = false
    }
    
    private func initializeReflection() async {
        // Always start from a clean slate to avoid reusing questions
        resetState()
        
        // Auto-select significant entries
        let topEntries = significantEntries.prefix(3)
        selectedEntryIds = Set(topEntries.map { $0.id })
        
        // Calculate initial stats
        calculateStats()
        
        // Skip to appropriate step based on reflection type
        switch reflectionType {
        case .periodic:
            currentStep = .selectPeriod
        case .project, .relationship:
            currentStep = .selectEvents
            // For project/relationship reflections, wait until after the user finalizes
            // event selection (Next) before generating questions, so they reflect the
            // events they actually chose.
        case .quick:
            currentStep = .answerQuestions
            await loadQuestionsAndStats()
        }
    }
    
    private func goToNextStep() {
        let steps = stepsForReflectionType
        guard let currentIndex = steps.firstIndex(of: currentStep) else { return }
        
        // Don't advance past the answer step until we actually have questions
        // (prevents jumping straight to Review while questions are still loading).
        if currentStep == .answerQuestions && (questionsAnswers.isEmpty || isLoadingQuestions) {
            return
        }
        
        if currentIndex < steps.count - 1 {
            let nextStep = steps[currentIndex + 1]
            
            // If we're moving into the answer step (e.g. from event selection),
            // always regenerate questions based on the current selection.
            if nextStep == .answerQuestions {
                questionsAnswers = []
                suggestions = []
                error = nil
                isLoadingQuestions = true
                currentQuestionIndex = 0
            }
            
            currentStep = nextStep
            
            // Load questions when entering answer step
            if currentStep == .answerQuestions {
                Task {
                    await loadQuestionsAndStats()
                }
            }
        }
    }
    
    private func goToPreviousStep() {
        let steps = stepsForReflectionType
        if let currentIndex = steps.firstIndex(of: currentStep),
           currentIndex > 0 {
            let previousStep = steps[currentIndex - 1]
            currentStep = previousStep
            
            // If we're going back to event selection, clear questions so they will regenerate
            if previousStep == .selectEvents {
                questionsAnswers = []
                suggestions = []
                error = nil
                isLoadingQuestions = false
                currentQuestionIndex = 0
            }
        }
    }
    
    private func toggleEntrySelection(_ entry: Entry) {
        if selectedEntryIds.contains(entry.id) {
            selectedEntryIds.remove(entry.id)
        } else {
            selectedEntryIds.insert(entry.id)
        }
    }
    
    private func loadQuestionsAndStats() async {
        isLoadingQuestions = true
        error = nil
        
        calculateStats()

        do {
            let result = try await AIService.shared.generateContextualReflectionQuestions(
                reflectionType: reflectionType,
                periodType: periodType,
                stats: stats,
                selectedEntries: selectedEntries,
                project: project,
                person: person,
                openCommitments: openCommitments
            )
            
            await MainActor.run {
                let qa = result.toQAArray()
                if qa.isEmpty {
                    // Guardrail: never leave the user without questions even if AI
                    // returns an empty set. Fall back to our default question set.
                    usedFallbackQuestions = true
                    useDefaultQuestions()
                } else {
                    questionsAnswers = qa
                    suggestions = result.suggestions
                    currentQuestionIndex = 0
                    isLoadingQuestions = false
                    error = nil
                }
            }
        } catch AIServiceError.timeout {
            // Guardrail: Fall back to defaults on timeout and surface this to the user
            await MainActor.run {
                usedFallbackQuestions = true
                useDefaultQuestions()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoadingQuestions = false
            }
        }
    }
    
    private func recalculateStats() async {
        calculateStats()
        
        // Recalculate significant entries based on new period
        let topEntries = significantEntries.prefix(3)
        selectedEntryIds = Set(topEntries.map { $0.id })
    }
    
    private func calculateStats() {
        let relevantEntries: [Entry]
        let relevantCommitments: [Commitment]
        
        switch reflectionType {
        case .periodic:
        guard let endDate = periodEndDate else { return }
        let startDate = periodStartDateNormalized
        
            relevantEntries = allEntries.filter { entry in
                entry.deletedAt == nil &&
                entry.occurredAt >= startDate &&
                entry.occurredAt <= endDate
            }
            
            relevantCommitments = allCommitments.filter { commitment in
            if let dueDate = commitment.dueDate {
                return dueDate >= startDate && dueDate <= endDate
            }
            return commitment.createdAt >= startDate && commitment.createdAt <= endDate
        }
        
        case .project:
            relevantEntries = allEntries.filter { $0.deletedAt == nil && $0.project?.id == project?.id }
            relevantCommitments = allCommitments.filter { $0.project?.id == project?.id }
            
        case .relationship:
            relevantEntries = allEntries.filter { entry in
                entry.deletedAt == nil &&
                entry.participants?.contains(where: { $0.id == person?.id }) == true
            }
            relevantCommitments = allCommitments.filter { $0.person?.id == person?.id }
            
        case .quick:
            relevantEntries = []
            relevantCommitments = []
        }
        
        let activeProjects = allProjects.filter { $0.status == .active }
        
        stats = ReflectionStats(
            entriesCreated: relevantEntries.count,
            commitmentsCreated: relevantCommitments.count,
            commitmentsCompleted: relevantCommitments.filter { $0.status == .done }.count,
            iOweOpen: allCommitments.filter { $0.direction == .iOwe && $0.status == .open }.count,
            waitingForOpen: allCommitments.filter { $0.direction == .waitingFor && $0.status == .open }.count,
            projectsActive: activeProjects.count,
            meetingsHeld: relevantEntries.filter { $0.kind == .meeting }.count,
            decisionsRecorded: relevantEntries.filter { $0.isDecision || $0.kind == .decision }.count,
            significantEntryIds: Array(selectedEntryIds)
        )
    }
    
    private func useDefaultQuestions() {
        let defaults = Reflection.defaultQuestions(for: reflectionType, periodType: periodType)
        questionsAnswers = defaults.map { ReflectionQA(question: $0) }
        suggestions = []
        isLoadingQuestions = false
        error = nil
    }
    
    private func saveReflection() {
        let startDate = periodStartDateNormalized
        let endDate = periodEndDate
        
        let reflection = Reflection(
            reflectionType: reflectionType,
            periodType: periodType,
            periodStart: startDate,
            periodEnd: endDate,
            mood: mood,
            questionsAnswers: questionsAnswers
        )
        reflection.stats = stats
        reflection.aiQuestions = questionsAnswers.map { $0.question }
        reflection.linkedEntryIds = Array(selectedEntryIds)
        reflection.project = project
        reflection.person = person
        
        modelContext.insert(reflection)
        
        // Extract and save themes asynchronously
        Task {
            if let themes = try? await AIService.shared.extractReflectionThemes(questionsAnswers: questionsAnswers) {
                await MainActor.run {
                    for theme in themes {
                        reflection.addTag(theme)
                    }
                    try? modelContext.save()
                }
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Event Selection Card

struct EventSelectionCard: View {
    let entry: Entry
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .purple : .secondary)
                
                // Entry info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: entry.kind.icon)
                            .font(.caption)
                            .foregroundStyle(kindColor)
                        
                        Text(entry.kind.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if entry.isDecision {
                            Text("• Decision")
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                    }
                    
                    Text(entry.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text(entry.occurredAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                isSelected ? Color.purple.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

// MARK: - Previews

#Preview("Weekly") {
    NewReflectionView(periodType: .week)
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}

#Preview("Monthly") {
    NewReflectionView(periodType: .month)
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}

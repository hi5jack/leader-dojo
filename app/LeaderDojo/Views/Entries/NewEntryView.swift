import SwiftUI
import SwiftData

struct NewEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allReflections: [Reflection]
    
    private var quickReflections: [Reflection] {
        allReflections.filter { $0.reflectionType == .quick }
    }
    
    let project: Project
    var preselectedKind: EntryKind?
    
    // Optional initial values (for quick decision capture flow)
    var initialTitle: String?
    var initialRationale: String?
    var initialReviewDate: Date?
    
    @State private var kind: EntryKind = .note
    @State private var title: String = ""
    @State private var rawContent: String = ""
    @State private var occurredAt: Date = Date()
    @State private var isDecision: Bool = false
    
    // Decision details state
    @State private var decisionRationale: String = ""
    @State private var decisionAssumptions: String = ""
    @State private var decisionConfidence: Int = 3
    @State private var decisionStakes: DecisionStakes = .medium
    @State private var decisionReviewDate: Date? = nil
    @State private var showDecisionDetails: Bool = false
    
    // AI Summary state
    @State private var isGeneratingSummary: Bool = false
    @State private var aiSummary: String = ""
    @State private var suggestedActions: [SuggestedAction] = []
    @State private var showAIResults: Bool = false
    @State private var aiError: String? = nil
    
    // Quick reflection state
    @State private var showQuickReflection: Bool = false
    @State private var savedEntry: Entry? = nil
    
    var body: some View {
        NavigationStack {
            #if os(macOS)
            macOSLayout
            #else
            iOSLayout
            #endif
        }
        .sheet(isPresented: $showQuickReflection) {
            if let entry = savedEntry {
                QuickReflectionSheet(entry: entry) {
                    // Dismiss the parent view after quick reflection is dismissed
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - iOS Layout (Form-based)
    
    #if os(iOS)
    private var iOSLayout: some View {
        Form {
            // Entry Type Section
            Section {
                Picker("Type", selection: $kind) {
                    ForEach(EntryKind.activeCases, id: \.self) { entryKind in
                        Label(entryKind.displayName, systemImage: entryKind.icon)
                            .tag(entryKind)
                    }
                }
                .pickerStyle(.menu)
                
                DatePicker("Date", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
            }
            
            // Content Section
            Section {
                TextField("Title", text: $title)
                
                TextEditor(text: $rawContent)
                    .frame(minHeight: 150)
            } header: {
                Text("Content")
            } footer: {
                if kind.supportsAISummary {
                    Text("Paste your meeting notes or raw content. AI can generate a summary and suggest commitments.")
                }
            }
            
            // Decision marker
            if kind == .decision || kind == .meeting {
                Section {
                    Toggle("Mark as Key Decision", isOn: $isDecision)
                } footer: {
                    Text("Key decisions can be reviewed later for reflection.")
                }
            }
            
            // Decision Details Section (shown when kind is decision or isDecision is true)
            if kind == .decision || isDecision {
                Section {
                    DisclosureGroup("Decision Details", isExpanded: $showDecisionDetails) {
                        // Rationale
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Why are you making this decision?")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $decisionRationale)
                                .frame(minHeight: 80)
                        }
                        
                        // Assumptions
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key assumptions (what must be true?)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $decisionAssumptions)
                                .frame(minHeight: 60)
                        }
                        
                        // Confidence
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Confidence Level")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(confidenceLabel(decisionConfidence))
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                            }
                            Slider(value: Binding(
                                get: { Double(decisionConfidence) },
                                set: { decisionConfidence = Int($0) }
                            ), in: 1...5, step: 1)
                            .tint(.purple)
                        }
                        
                        // Stakes
                        Picker("Stakes Level", selection: $decisionStakes) {
                            ForEach(DecisionStakes.allCases, id: \.self) { stakes in
                                Text(stakes.displayName).tag(stakes)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // Review Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Review Date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 8) {
                                Button("1 Week") {
                                    decisionReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
                                }
                                .buttonStyle(.bordered)
                                .tint(reviewDateMatches(weeks: 1) ? .purple : .secondary)
                                
                                Button("1 Month") {
                                    decisionReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                                }
                                .buttonStyle(.bordered)
                                .tint(reviewDateMatches(months: 1) ? .purple : .secondary)
                                
                                Button("3 Months") {
                                    decisionReviewDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                                }
                                .buttonStyle(.bordered)
                                .tint(reviewDateMatches(months: 3) ? .purple : .secondary)
                            }
                            .font(.caption)
                            
                            if let reviewDate = decisionReviewDate {
                                HStack {
                                    DatePicker("", selection: Binding(
                                        get: { reviewDate },
                                        set: { decisionReviewDate = $0 }
                                    ), displayedComponents: .date)
                                    .labelsHidden()
                                    
                                    Button {
                                        decisionReviewDate = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Decision Hypothesis")
                        Spacer()
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.purple)
                    }
                } footer: {
                    Text("Capture your reasoning and assumptions to learn from this decision later.")
                }
            }
            
            // AI Summary Section
            if kind.supportsAISummary && !rawContent.isEmpty {
                Section {
                    Button {
                        generateAISummary()
                    } label: {
                        HStack {
                            if isGeneratingSummary {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGeneratingSummary ? "Generating..." : "Generate Summary & Actions")
                        }
                    }
                    .disabled(isGeneratingSummary || rawContent.isEmpty)
                    
                    if let error = aiError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("AI Assistant")
                }
            }
            
            // AI Results Section
            if showAIResults {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $aiSummary)
                            .frame(minHeight: 100)
                    }
                } header: {
                    Text("Generated Summary")
                }
                
                if !suggestedActions.isEmpty {
                    Section {
                        ForEach($suggestedActions) { $action in
                            SuggestedActionRow(action: $action)
                        }
                    } header: {
                        Text("Suggested Commitments")
                    } footer: {
                        Text("Select the commitments you want to create.")
                    }
                }
            }
        }
        .navigationTitle("New Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveEntry()
                }
                .disabled(title.isEmpty)
            }
        }
        .onAppear {
            if let preselected = preselectedKind {
                kind = preselected
            }
            // Set initial values from quick decision flow
            if let initialTitle = initialTitle {
                title = initialTitle
            }
            if let initialRationale = initialRationale {
                decisionRationale = initialRationale
            }
            if let initialReviewDate = initialReviewDate {
                decisionReviewDate = initialReviewDate
            }
            // Auto-expand decision details if coming from quick decision
            if initialTitle != nil || initialRationale != nil {
                showDecisionDetails = true
            }
        }
    }
    #endif
    
    // MARK: - macOS Layout (Card-based)
    
    #if os(macOS)
    private var macOSLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Bar
                macOSHeader
                
                // Main Content
                HStack(alignment: .top, spacing: 24) {
                    // Left Column - Main Content
                    VStack(spacing: 20) {
                        contentCard
                        
                        if showAIResults {
                            aiResultsCard
                        }
                    }
                    .frame(minWidth: 400, maxWidth: .infinity)
                    
                    // Right Column - Metadata & AI
                    VStack(spacing: 20) {
                        metadataCard
                        
                        if kind == .decision || kind == .meeting {
                            optionsCard
                        }
                        
                        if shouldShowDecisionDetails {
                            decisionDetailsCard
                        }
                        
                        if kind.supportsAISummary && !rawContent.isEmpty {
                            aiAssistantCard
                        }
                        
                        if showAIResults && !suggestedActions.isEmpty {
                            suggestedCommitmentsCard
                        }
                    }
                    .frame(width: 280)
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("New Entry")
        .onAppear {
            if let preselected = preselectedKind {
                kind = preselected
            }
            // Set initial values from quick decision flow
            if let initialTitle = initialTitle {
                title = initialTitle
            }
            if let initialRationale = initialRationale {
                decisionRationale = initialRationale
            }
            if let initialReviewDate = initialReviewDate {
                decisionReviewDate = initialReviewDate
            }
            // Auto-expand decision details if coming from quick decision
            if initialTitle != nil || initialRationale != nil {
                showDecisionDetails = true
            }
        }
    }
    
    private var macOSHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("New Entry")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.caption)
                    Text(project.name)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save Entry") {
                    saveEntry()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("What happened?", text: $title)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
            
            Divider()
            
            // Content Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if kind.supportsAISummary {
                        Text("Supports AI summary")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                }
                
                MacTextEditor(text: $rawContent, placeholder: "Add your meeting notes, thoughts, or any raw content here...")
                    .frame(minHeight: 200)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Details", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                // Entry Type Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Type")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $kind) {
                        ForEach(EntryKind.activeCases, id: \.self) { entryKind in
                            Label(entryKind.displayName, systemImage: entryKind.icon)
                                .tag(entryKind)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // Date Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Date & Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    DatePicker("", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Options", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Toggle(isOn: $isDecision) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Key Decision")
                        .font(.subheadline)
                    Text("Track for future reflection")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var aiAssistantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Assistant", systemImage: "sparkles")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.purple)
            
            Text("Generate a summary and discover action items from your notes.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button {
                generateAISummary()
            } label: {
                HStack {
                    if isGeneratingSummary {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGeneratingSummary ? "Generating..." : "Generate")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(isGeneratingSummary || rawContent.isEmpty)
            
            if let error = aiError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var aiResultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Generated Summary", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                Button {
                    showAIResults = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            MacTextEditor(text: $aiSummary, placeholder: "AI-generated summary...")
                .frame(minHeight: 120)
        }
        .padding(20)
        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var suggestedCommitmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggested Commitments", systemImage: "checklist")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.indigo)
            
            Text("Select items to create as commitments.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                ForEach($suggestedActions) { $action in
                    MacSuggestedActionRow(action: $action)
                }
            }
        }
        .padding(16)
        .background(.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.indigo.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var decisionDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Decision Hypothesis", systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                Button {
                    showDecisionDetails.toggle()
                } label: {
                    Image(systemName: showDecisionDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if showDecisionDetails {
                VStack(alignment: .leading, spacing: 14) {
                    // Rationale
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why are you making this decision?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        MacTextEditor(text: $decisionRationale, placeholder: "Your reasoning...")
                            .frame(height: 60)
                    }
                    
                    // Assumptions
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key assumptions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        MacTextEditor(text: $decisionAssumptions, placeholder: "What must be true?")
                            .frame(height: 50)
                    }
                    
                    Divider()
                    
                    // Confidence
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Confidence")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(confidenceLabel(decisionConfidence))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.purple)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(decisionConfidence) },
                            set: { decisionConfidence = Int($0) }
                        ), in: 1...5, step: 1)
                        .tint(.purple)
                    }
                    
                    // Stakes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Stakes Level")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 6) {
                            ForEach(DecisionStakes.allCases, id: \.self) { stakes in
                                Button {
                                    decisionStakes = stakes
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: stakes.icon)
                                            .font(.caption2)
                                        Text(stakes.displayName)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        decisionStakes == stakes ? stakesColor(stakes).opacity(0.2) : Color.clear,
                                        in: Capsule()
                                    )
                                    .foregroundStyle(decisionStakes == stakes ? stakesColor(stakes) : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Review Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Review Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 6) {
                            Button("1w") {
                                decisionReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
                            }
                            .buttonStyle(.bordered)
                            .tint(reviewDateMatches(weeks: 1) ? .purple : .secondary)
                            .controlSize(.small)
                            
                            Button("1m") {
                                decisionReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                            }
                            .buttonStyle(.bordered)
                            .tint(reviewDateMatches(months: 1) ? .purple : .secondary)
                            .controlSize(.small)
                            
                            Button("3m") {
                                decisionReviewDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                            }
                            .buttonStyle(.bordered)
                            .tint(reviewDateMatches(months: 3) ? .purple : .secondary)
                            .controlSize(.small)
                            
                            Spacer()
                            
                            if decisionReviewDate != nil {
                                Button {
                                    decisionReviewDate = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if let reviewDate = decisionReviewDate {
                            DatePicker("", selection: Binding(
                                get: { reviewDate },
                                set: { decisionReviewDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.field)
                        }
                    }
                }
            } else {
                Text("Capture your reasoning and assumptions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func stakesColor(_ stakes: DecisionStakes) -> Color {
        switch stakes {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    #endif
    
    // MARK: - Decision Helpers
    
    private func confidenceLabel(_ value: Int) -> String {
        switch value {
        case 1: return "Very Uncertain"
        case 2: return "Somewhat Uncertain"
        case 3: return "Neutral"
        case 4: return "Fairly Confident"
        case 5: return "Very Confident"
        default: return "Neutral"
        }
    }
    
    private func reviewDateMatches(weeks: Int = 0, months: Int = 0) -> Bool {
        guard let reviewDate = decisionReviewDate else { return false }
        let calendar = Calendar.current
        var targetDate: Date?
        
        if weeks > 0 {
            targetDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: Date())
        } else if months > 0 {
            targetDate = calendar.date(byAdding: .month, value: months, to: Date())
        }
        
        guard let target = targetDate else { return false }
        return calendar.isDate(reviewDate, inSameDayAs: target)
    }
    
    /// Whether decision details section should be visible
    private var shouldShowDecisionDetails: Bool {
        kind == .decision || isDecision
    }
    
    // MARK: - Actions
    
    private func generateAISummary() {
        isGeneratingSummary = true
        aiError = nil
        
        Task {
            do {
                let result = try await AIService.shared.summarizeEntry(
                    rawContent: rawContent,
                    projectName: project.name,
                    entryKind: kind
                )
                
                await MainActor.run {
                    aiSummary = result.summary
                    suggestedActions = result.suggestedActions
                    
                    // For decision entries, use AI-suggested assumptions and review date
                    if kind == .decision || isDecision {
                        if let aiAssumptions = result.assumptions, !aiAssumptions.isEmpty {
                            decisionAssumptions = aiAssumptions
                        }
                        if let reviewDays = result.suggestedReviewDays {
                            decisionReviewDate = Calendar.current.date(byAdding: .day, value: reviewDays, to: Date())
                        }
                        showDecisionDetails = true  // Auto-expand decision details
                    }
                    
                    showAIResults = true
                    isGeneratingSummary = false
                }
            } catch {
                await MainActor.run {
                    aiError = error.localizedDescription
                    isGeneratingSummary = false
                }
            }
        }
    }
    
    private func saveEntry() {
        let entry = Entry(
            kind: kind,
            title: title,
            occurredAt: occurredAt,
            rawContent: rawContent.isEmpty ? nil : rawContent,
            aiSummary: aiSummary.isEmpty ? nil : aiSummary,
            isDecision: isDecision
        )
        
        entry.project = project
        
        // Store decision hypothesis fields if this is a decision
        if shouldShowDecisionDetails {
            entry.decisionRationale = decisionRationale.isEmpty ? nil : decisionRationale
            entry.decisionAssumptions = decisionAssumptions.isEmpty ? nil : decisionAssumptions
            entry.decisionConfidence = decisionConfidence
            entry.decisionStakes = decisionStakes
            entry.decisionReviewDate = decisionReviewDate
            entry.decisionOutcome = .pending  // Initialize with pending outcome
        }
        
        // Store suggested actions
        if !suggestedActions.isEmpty {
            entry.aiSuggestedActions = suggestedActions
        }
        
        modelContext.insert(entry)
        
        // Create selected commitments
        let selectedActions = suggestedActions.filter { $0.isSelected }
        for action in selectedActions {
            let commitment = Commitment(
                title: action.title,
                direction: action.direction,
                aiGenerated: true
            )
            // Note: AI-suggested counterparty is displayed but not linked to a Person
            // Users can manually assign a Person relationship after creation
            commitment.project = project
            commitment.sourceEntry = entry
            modelContext.insert(commitment)
        }
        
        // Update project's last active timestamp
        project.markActive()
        
        try? modelContext.save()
        
        // Check if we should prompt for quick reflection (Guardrail: prompting strategy)
        let quickReflectionsToday = QuickReflectionTrigger.quickReflectionsToday(from: quickReflections)
        if QuickReflectionTrigger.shouldPrompt(for: entry, existingReflectionsToday: quickReflectionsToday) {
            savedEntry = entry
            showQuickReflection = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Suggested Action Row

struct SuggestedActionRow: View {
    @Binding var action: SuggestedAction
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                action.isSelected.toggle()
            } label: {
                Image(systemName: action.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(action.isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.subheadline)
                
                HStack(spacing: 8) {
                    Label(action.direction.displayName, systemImage: action.direction.icon)
                        .font(.caption)
                        .foregroundStyle(action.direction == .iOwe ? .orange : .blue)
                    
                    if let counterparty = action.counterparty {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(counterparty)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - macOS Components

#if os(macOS)
/// Compact suggested action row for macOS sidebar
struct MacSuggestedActionRow: View {
    @Binding var action: SuggestedAction
    
    var body: some View {
        Button {
            action.isSelected.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: action.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(action.isSelected ? .indigo : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: action.direction.icon)
                            .font(.caption2)
                        Text(action.direction.displayName)
                            .font(.caption2)
                        
                        if let counterparty = action.counterparty {
                            Text("• \(counterparty)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(action.direction == .iOwe ? .orange : .blue)
                }
                
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(action.isSelected ? .indigo.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif

#Preview {
    NewEntryView(project: Project(name: "Test Project"))
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}




import SwiftUI
import SwiftData

/// Voice input targets for decision review
private enum DecisionVoiceTarget {
    case outcome
    case assumptions
    case learning
    
    var title: String {
        switch self {
        case .outcome: return "Outcome Notes"
        case .assumptions: return "Assumption Check"
        case .learning: return "Key Learning"
        }
    }
}

/// Sheet for reviewing a decision and recording its outcome
struct DecisionReviewSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: Entry
    
    @State private var outcome: DecisionOutcome = .pending
    @State private var outcomeNotes: String = ""
    @State private var assumptionResults: String = ""
    @State private var learning: String = ""
    @State private var createFollowUpCommitment: Bool = false
    @State private var followUpTitle: String = ""
    
    // Voice input state
    @State private var speechService = SpeechRecognitionService()
    @State private var showVoiceOverlay: Bool = false
    @State private var voiceTarget: DecisionVoiceTarget = .outcome
    
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
            // Original Decision Context
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.headline)
                    
                    if let rationale = entry.decisionRationale, !rationale.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Original Rationale")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rationale)
                                .font(.subheadline)
                        }
                    }
                    
                    if let assumptions = entry.decisionAssumptions, !assumptions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key Assumptions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(assumptions)
                                .font(.subheadline)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        if let confidence = entry.decisionConfidence {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Confidence")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(entry.confidenceDisplayText ?? "\(confidence)")
                                    .font(.caption)
                            }
                        }
                        
                        if let stakes = entry.decisionStakes {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stakes")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(stakes.displayName)
                                    .font(.caption)
                            }
                        }
                    }
                }
            } header: {
                Text("Original Decision")
            }
            
            // Outcome Selection
            Section {
                Picker("Outcome", selection: $outcome) {
                    ForEach(DecisionOutcome.allCases, id: \.self) { outcome in
                        HStack {
                            Image(systemName: outcome.icon)
                            Text(outcome.displayName)
                        }
                        .tag(outcome)
                    }
                }
                .pickerStyle(.menu)
                
                HStack(alignment: .top, spacing: 8) {
                    TextEditor(text: $outcomeNotes)
                        .frame(minHeight: 80)
                    
                    InlineVoiceButton(
                        isListening: false,
                        action: {
                            voiceTarget = .outcome
                            showVoiceOverlay = true
                        },
                        color: .purple
                    )
                }
            } header: {
                Text("What Happened?")
            } footer: {
                Text("Describe the actual outcome and any surprises.")
            }
            
            // Assumption Results
            Section {
                HStack(alignment: .top, spacing: 8) {
                    TextEditor(text: $assumptionResults)
                        .frame(minHeight: 60)
                    
                    InlineVoiceButton(
                        isListening: false,
                        action: {
                            voiceTarget = .assumptions
                            showVoiceOverlay = true
                        },
                        color: .secondary
                    )
                }
            } header: {
                Text("Assumption Check")
            } footer: {
                Text("Which of your original assumptions held true? Which broke?")
            }
            
            // Learning
            Section {
                HStack(alignment: .top, spacing: 8) {
                    TextEditor(text: $learning)
                        .frame(minHeight: 80)
                    
                    InlineVoiceButton(
                        isListening: false,
                        action: {
                            voiceTarget = .learning
                            showVoiceOverlay = true
                        },
                        color: .yellow
                    )
                }
            } header: {
                HStack {
                    Text("Key Learning")
                    Spacer()
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                }
            } footer: {
                Text("What would you do differently? What patterns do you notice?")
            }
            
            // Follow-up Commitment
            Section {
                Toggle("Create follow-up commitment", isOn: $createFollowUpCommitment)
                
                if createFollowUpCommitment {
                    TextField("Commitment title", text: $followUpTitle)
                }
            } header: {
                Text("Next Steps")
            }
        }
        .navigationTitle("Review Decision")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveReview()
                }
                .disabled(outcome == .pending)
            }
        }
        .onAppear {
            // Pre-populate if there's existing outcome data
            if let existingOutcome = entry.decisionOutcome {
                outcome = existingOutcome
            }
            if let notes = entry.decisionOutcomeNotes {
                outcomeNotes = notes
            }
            if let results = entry.decisionAssumptionResults {
                assumptionResults = results
            }
            if let existingLearning = entry.decisionLearning {
                learning = existingLearning
            }
        }
        .voiceInputOverlay(
            isPresented: $showVoiceOverlay,
            speechService: speechService,
            title: voiceTarget.title,
            accentColor: .purple
        ) { text in
            handleVoiceInputComplete(text)
        }
    }
    #endif
    
    private func handleVoiceInputComplete(_ text: String) {
        switch voiceTarget {
        case .outcome:
            if outcomeNotes.isEmpty {
                outcomeNotes = text
            } else {
                outcomeNotes += "\n\n" + text
            }
        case .assumptions:
            if assumptionResults.isEmpty {
                assumptionResults = text
            } else {
                assumptionResults += "\n\n" + text
            }
        case .learning:
            if learning.isEmpty {
                learning = text
            } else {
                learning += "\n\n" + text
            }
        }
    }
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                macOSHeader
                
                // Content - vertical stacked layout for better sheet presentation
                VStack(spacing: 20) {
                    // Original Decision Context (collapsible summary at top)
                    originalDecisionCard
                    
                    // Review Form
                    outcomeCard
                    assumptionCard
                    learningCard
                    followUpCard
                }
                .padding(24)
            }
        }
        .frame(minWidth: 520, idealWidth: 600, maxWidth: 700)
        .frame(minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Review Decision")
        .onAppear {
            if let existingOutcome = entry.decisionOutcome {
                outcome = existingOutcome
            }
            if let notes = entry.decisionOutcomeNotes {
                outcomeNotes = notes
            }
            if let results = entry.decisionAssumptionResults {
                assumptionResults = results
            }
            if let existingLearning = entry.decisionLearning {
                learning = existingLearning
            }
        }
        .voiceInputOverlay(
            isPresented: $showVoiceOverlay,
            speechService: speechService,
            title: voiceTarget.title,
            accentColor: .purple
        ) { text in
            handleVoiceInputComplete(text)
        }
    }
    
    private var macOSHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Review Decision")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(entry.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save Review") {
                    saveReview()
                }
                .buttonStyle(.borderedProminent)
                .disabled(outcome == .pending)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var originalDecisionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with title and metadata
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Original Decision", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.title)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Compact metadata badges
                HStack(spacing: 12) {
                    if let confidence = entry.decisionConfidence {
                        VStack(alignment: .center, spacing: 2) {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { level in
                                    Circle()
                                        .fill(level <= confidence ? .purple : .purple.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            Text("Confidence")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let stakes = entry.decisionStakes {
                        VStack(alignment: .center, spacing: 2) {
                            Image(systemName: stakes.icon)
                                .font(.caption)
                                .foregroundStyle(stakesColor(stakes))
                            Text(stakes.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(entry.occurredAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                        Text("Decided")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Rationale and assumptions in a horizontal layout if both exist
            if (entry.decisionRationale != nil && !entry.decisionRationale!.isEmpty) ||
               (entry.decisionAssumptions != nil && !entry.decisionAssumptions!.isEmpty) {
                
                Divider()
                
                HStack(alignment: .top, spacing: 20) {
                    if let rationale = entry.decisionRationale, !rationale.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rationale")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text(rationale)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let assumptions = entry.decisionAssumptions, !assumptions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key Assumptions")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text(assumptions)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var outcomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Outcome", systemImage: "checkmark.seal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                InlineVoiceButton(
                    isListening: false,
                    action: {
                        voiceTarget = .outcome
                        showVoiceOverlay = true
                    },
                    color: .purple
                )
            }
            
            // Outcome picker as buttons
            HStack(spacing: 6) {
                ForEach(DecisionOutcome.allCases.filter { $0 != .pending }, id: \.self) { outcomeOption in
                    Button {
                        outcome = outcomeOption
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: outcomeOption.icon)
                                .font(.title3)
                            Text(outcomeOption.displayName)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            outcome == outcomeOption ? outcomeColor(outcomeOption).opacity(0.2) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(outcome == outcomeOption ? outcomeColor(outcomeOption) : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("What happened?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            MacTextEditor(text: $outcomeNotes, placeholder: "Describe the actual outcome...")
                .frame(height: 80)
        }
        .padding(16)
        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var assumptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Assumption Check", systemImage: "checklist")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                InlineVoiceButton(
                    isListening: false,
                    action: {
                        voiceTarget = .assumptions
                        showVoiceOverlay = true
                    },
                    color: .secondary
                )
            }
            
            Text("Which assumptions held? Which broke?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            MacTextEditor(text: $assumptionResults, placeholder: "Review your original assumptions...")
                .frame(height: 60)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var learningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Key Learning", systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.yellow)
                
                Spacer()
                
                InlineVoiceButton(
                    isListening: false,
                    action: {
                        voiceTarget = .learning
                        showVoiceOverlay = true
                    },
                    color: .yellow
                )
            }
            
            Text("What would you do differently?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            MacTextEditor(text: $learning, placeholder: "Capture your insights...")
                .frame(height: 80)
        }
        .padding(16)
        .background(.yellow.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var followUpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Next Steps", systemImage: "arrow.right.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Toggle(isOn: $createFollowUpCommitment) {
                Text("Create follow-up commitment")
                    .font(.subheadline)
            }
            .toggleStyle(.switch)
            
            if createFollowUpCommitment {
                TextField("Commitment title", text: $followUpTitle)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private func stakesColor(_ stakes: DecisionStakes) -> Color {
        switch stakes {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    
    private func outcomeColor(_ outcome: DecisionOutcome) -> Color {
        switch outcome {
        case .pending: return .gray
        case .validated: return .green
        case .invalidated: return .red
        case .mixed: return .yellow
        case .superseded: return .blue
        }
    }
    #endif
    
    // MARK: - Actions
    
    private func saveReview() {
        // Update the entry with outcome data
        entry.decisionOutcome = outcome
        entry.decisionOutcomeDate = Date()
        entry.decisionOutcomeNotes = outcomeNotes.isEmpty ? nil : outcomeNotes
        entry.decisionAssumptionResults = assumptionResults.isEmpty ? nil : assumptionResults
        entry.decisionLearning = learning.isEmpty ? nil : learning
        entry.updatedAt = Date()
        
        // Create follow-up commitment if requested
        if createFollowUpCommitment && !followUpTitle.isEmpty {
            let commitment = Commitment(
                title: followUpTitle,
                direction: .iOwe,
                aiGenerated: false
            )
            commitment.project = entry.project
            commitment.sourceEntry = entry
            modelContext.insert(commitment)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let entry = Entry(kind: .decision, title: "Hire senior engineer for platform team")
    entry.decisionRationale = "We need more senior capacity to accelerate platform development"
    entry.decisionAssumptions = "Budget will be approved. Good candidates are available."
    entry.decisionConfidence = 4
    entry.decisionStakes = .high
    entry.decisionReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
    
    return DecisionReviewSheet(entry: entry)
        .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


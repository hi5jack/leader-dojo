import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var entry: Entry
    
    @State private var showingEditEntry: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var showingNewCommitment: Bool = false
    @State private var showingDecisionReview: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Header
                entryHeader
                
                // Content sections
                if let summary = entry.aiSummary, !summary.isEmpty {
                    summarySection(summary)
                }
                
                if let rawContent = entry.rawContent, !rawContent.isEmpty {
                    rawContentSection(rawContent)
                }
                
                if let decisions = entry.decisions, !decisions.isEmpty {
                    decisionsSection(decisions)
                }
                
                // Decision Hypothesis Section (for decision entries)
                if entry.isDecisionEntry {
                    decisionHypothesisSection
                }
                
                // Related Commitments
                commitmentsSection
                
                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle(entry.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditEntry = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        showingNewCommitment = true
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
        .sheet(isPresented: $showingEditEntry) {
            EditEntryView(entry: entry)
        }
        .sheet(isPresented: $showingNewCommitment) {
            NewCommitmentView(project: entry.project, person: nil, sourceEntry: entry)
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                entry.softDelete()
                try? modelContext.save()
            }
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
        .sheet(isPresented: $showingDecisionReview) {
            DecisionReviewSheet(entry: entry)
        }
    }
    
    // MARK: - Entry Header
    
    private var participants: [Person] {
        entry.participants ?? []
    }
    
    private var entryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Badge(text: entry.kind.displayName, icon: entry.kind.icon, color: kindColor)
                
                if entry.isDecision {
                    Badge(text: "Decision", icon: "checkmark.seal.fill", color: .purple)
                }
            }
            
            if let project = entry.project {
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text(project.name)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(entry.occurredAt, style: .date)
                Text("at")
                    .foregroundStyle(.secondary)
                Text(entry.occurredAt, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            // Participants section
            if !participants.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Participants")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(participants) { person in
                            NavigationLink {
                                PersonDetailView(person: person)
                            } label: {
                                HStack(spacing: 4) {
                                    PersonAvatarCircle(person: person, size: 20)
                                    Text(person.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                                .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Section
    
    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI Summary", systemImage: "sparkles")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.purple)
            
            MarkdownText(summary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Raw Content Section
    
    private func rawContentSection(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Original Notes", systemImage: "doc.text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            MarkdownText(content)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Decisions Section
    
    private func decisionsSection(_ decisions: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Decisions Made", systemImage: "checkmark.seal.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            
            MarkdownText(decisions)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Decision Hypothesis Section
    
    private var decisionHypothesisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with outcome badge
            HStack {
                Label("Decision Hypothesis", systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                if let outcome = entry.decisionOutcome, outcome != .pending {
                    outcomeBadge(outcome)
                } else if entry.needsDecisionReview {
                    Button {
                        showingDecisionReview = true
                    } label: {
                        Label("Review", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Rationale
            if let rationale = entry.decisionRationale, !rationale.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rationale")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rationale)
                        .font(.subheadline)
                }
            }
            
            // Assumptions
            if let assumptions = entry.decisionAssumptions, !assumptions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Assumptions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(assumptions)
                        .font(.subheadline)
                }
            }
            
            // Confidence and Stakes row
            HStack(spacing: 16) {
                if let confidence = entry.decisionConfidence {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confidence")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { level in
                                Circle()
                                    .fill(level <= confidence ? .purple : .purple.opacity(0.2))
                                    .frame(width: 8, height: 8)
                            }
                            if let text = entry.confidenceDisplayText {
                                Text(text)
                                    .font(.caption2)
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                }
                
                if let stakes = entry.decisionStakes {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stakes")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: stakes.icon)
                                .font(.caption)
                            Text(stakes.displayName)
                                .font(.caption)
                        }
                        .foregroundStyle(stakesColor(stakes))
                    }
                }
            }
            
            // Review Date
            if let reviewDate = entry.decisionReviewDate {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                    
                    if let days = entry.daysUntilReview {
                        if days < 0 {
                            Text("Review overdue by \(abs(days)) days")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else if days == 0 {
                            Text("Review due today")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            Text("Review in \(days) days (\(reviewDate.formatted(date: .abbreviated, time: .omitted)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Outcome section (if reviewed)
            if let outcome = entry.decisionOutcome, outcome != .pending {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Outcome")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if let outcomeDate = entry.decisionOutcomeDate {
                            Text(outcomeDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let notes = entry.decisionOutcomeNotes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                    }
                    
                    if let assumptionResults = entry.decisionAssumptionResults, !assumptionResults.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Assumption Results")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(assumptionResults)
                                .font(.caption)
                        }
                    }
                    
                    if let learning = entry.decisionLearning, !learning.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Key Learning")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(learning)
                                .font(.caption)
                                .italic()
                        }
                    }
                }
            }
            
            // Review button (if not yet reviewed)
            if entry.decisionOutcome == nil || entry.decisionOutcome == .pending {
                Button {
                    showingDecisionReview = true
                } label: {
                    Label("Record Outcome", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func outcomeBadge(_ outcome: DecisionOutcome) -> some View {
        HStack(spacing: 4) {
            Image(systemName: outcome.icon)
                .font(.caption2)
            Text(outcome.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(outcomeColor(outcome).opacity(0.2), in: Capsule())
        .foregroundStyle(outcomeColor(outcome))
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
    
    // MARK: - Commitments Section
    
    private var commitmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Related Commitments", systemImage: "checklist")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingNewCommitment = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            let commitments = entry.commitments ?? []
            
            if commitments.isEmpty {
                Text("No commitments linked to this entry.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(commitments) { commitment in
                    NavigationLink {
                        CommitmentDetailView(commitment: commitment)
                    } label: {
                        MiniCommitmentRow(commitment: commitment)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            LabeledContent("Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
            
            LabeledContent("Updated", value: entry.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
            
            LabeledContent("ID", value: entry.id.uuidString.prefix(8).description)
                .font(.caption)
        }
        .textSelection(.enabled)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    
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

// MARK: - Edit Entry View

struct EditEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: Entry
    
    var body: some View {
        NavigationStack {
            #if os(macOS)
            macOSEditLayout
            #else
            iOSEditLayout
            #endif
        }
    }
    
    // MARK: - iOS Layout
    
    #if os(iOS)
    private var iOSEditLayout: some View {
        Form {
            Section {
                Picker("Type", selection: $entry.kind) {
                    ForEach(EntryKind.activeCases, id: \.self) { kind in
                        Label(kind.displayName, systemImage: kind.icon)
                            .tag(kind)
                    }
                }
                
                DatePicker("Date", selection: $entry.occurredAt, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section("Content") {
                TextField("Title", text: $entry.title)
                
                TextEditor(text: Binding(
                    get: { entry.rawContent ?? "" },
                    set: { entry.rawContent = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 150)
            }
            
            Section {
                Toggle("Key Decision", isOn: $entry.isDecision)
            }
            
            // Decision Details - show when it's a decision
            if entry.isDecisionEntry {
                Section("Decision Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rationale")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: Binding(
                            get: { entry.decisionRationale ?? "" },
                            set: { entry.decisionRationale = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Assumptions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: Binding(
                            get: { entry.decisionAssumptions ?? "" },
                            set: { entry.decisionAssumptions = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 60)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Confidence")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(confidenceLabel(entry.decisionConfidence ?? 3))
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                        Slider(value: Binding(
                            get: { Double(entry.decisionConfidence ?? 3) },
                            set: { entry.decisionConfidence = Int($0) }
                        ), in: 1...5, step: 1)
                        .tint(.purple)
                    }
                    
                    Picker("Stakes Level", selection: Binding(
                        get: { entry.decisionStakes ?? .medium },
                        set: { entry.decisionStakes = $0 }
                    )) {
                        ForEach(DecisionStakes.allCases, id: \.self) { stakes in
                            Text(stakes.displayName).tag(stakes)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            Button("1 Week") {
                                entry.decisionReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
                            }
                            .buttonStyle(.bordered)
                            .tint(.cyan)
                            
                            Button("1 Month") {
                                entry.decisionReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                            }
                            .buttonStyle(.bordered)
                            .tint(.cyan)
                            
                            Button("3 Months") {
                                entry.decisionReviewDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                            }
                            .buttonStyle(.bordered)
                            .tint(.cyan)
                        }
                        .font(.caption)
                        
                        if let reviewDate = entry.decisionReviewDate {
                            HStack {
                                DatePicker("", selection: Binding(
                                    get: { reviewDate },
                                    set: { entry.decisionReviewDate = $0 }
                                ), displayedComponents: .date)
                                .labelsHidden()
                                
                                Button {
                                    entry.decisionReviewDate = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            
            if entry.aiSummary != nil {
                Section("AI Summary") {
                    TextEditor(text: Binding(
                        get: { entry.aiSummary ?? "" },
                        set: { entry.aiSummary = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                }
            }
        }
        .navigationTitle("Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    entry.updatedAt = Date()
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
    
    private func confidenceLabel(_ value: Int) -> String {
        switch value {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Medium"
        case 4: return "High"
        case 5: return "Very High"
        default: return "Medium"
        }
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSEditLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Bar
                macOSEditHeader
                
                // Main Content
                HStack(alignment: .top, spacing: 24) {
                    // Left Column - Main Content
                    VStack(spacing: 20) {
                        editContentCard
                        
                        if entry.aiSummary != nil {
                            editSummaryCard
                        }
                    }
                    .frame(minWidth: 400, maxWidth: .infinity)
                    
                    // Right Column - Metadata
                    VStack(spacing: 20) {
                        editMetadataCard
                        editOptionsCard
                        editDecisionDetailsCard
                    }
                    .frame(width: 300)
                }
                .padding(24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Edit Entry")
    }
    
    private var macOSEditHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Entry")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let project = entry.project {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                        Text(project.name)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save Changes") {
                    entry.updatedAt = Date()
                    try? modelContext.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var editContentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("What happened?", text: $entry.title)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
            
            Divider()
            
            // Content Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                MacTextEditor(
                    text: Binding(
                        get: { entry.rawContent ?? "" },
                        set: { entry.rawContent = $0.isEmpty ? nil : $0 }
                    ),
                    placeholder: "Add your notes or content here..."
                )
                .frame(minHeight: 200)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var editSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("AI Summary", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                Button {
                    entry.aiSummary = nil
                } label: {
                    Text("Remove")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            MacTextEditor(
                text: Binding(
                    get: { entry.aiSummary ?? "" },
                    set: { entry.aiSummary = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "AI-generated summary..."
            )
            .frame(minHeight: 120)
        }
        .padding(20)
        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var editMetadataCard: some View {
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
                    
                    Picker("", selection: $entry.kind) {
                        ForEach(EntryKind.activeCases, id: \.self) { kind in
                            Label(kind.displayName, systemImage: kind.icon)
                                .tag(kind)
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
                    
                    DatePicker("", selection: $entry.occurredAt, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                Divider()
                
                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Modified")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var editOptionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Options", systemImage: "slider.horizontal.3")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Toggle(isOn: $entry.isDecision) {
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
    
    @ViewBuilder
    private var editDecisionDetailsCard: some View {
        if entry.isDecisionEntry {
            VStack(alignment: .leading, spacing: 16) {
                Label("Decision Details", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                
                // Rationale
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rationale")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    MacTextEditor(
                        text: Binding(
                            get: { entry.decisionRationale ?? "" },
                            set: { entry.decisionRationale = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "Why are you making this decision?"
                    )
                    .frame(height: 60)
                }
                
                // Assumptions
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key Assumptions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    MacTextEditor(
                        text: Binding(
                            get: { entry.decisionAssumptions ?? "" },
                            set: { entry.decisionAssumptions = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "What must be true for this to work?"
                    )
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
                        Text(macOSConfidenceLabel(entry.decisionConfidence ?? 3))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.purple)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(entry.decisionConfidence ?? 3) },
                        set: { entry.decisionConfidence = Int($0) }
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
                                entry.decisionStakes = stakes
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: stakes.icon)
                                        .font(.caption)
                                    Text(stakes.displayName)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    entry.decisionStakes == stakes ? macOSStakesColor(stakes).opacity(0.2) : Color.clear,
                                    in: Capsule()
                                )
                                .foregroundStyle(entry.decisionStakes == stakes ? macOSStakesColor(stakes) : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // Review Date
                VStack(alignment: .leading, spacing: 6) {
                    Text("Review Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 6) {
                        Button("1w") {
                            entry.decisionReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.cyan)
                        
                        Button("1m") {
                            entry.decisionReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.cyan)
                        
                        Button("3m") {
                            entry.decisionReviewDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.cyan)
                        
                        Spacer()
                        
                        if entry.decisionReviewDate != nil {
                            Button {
                                entry.decisionReviewDate = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if let reviewDate = entry.decisionReviewDate {
                        DatePicker("", selection: Binding(
                            get: { reviewDate },
                            set: { entry.decisionReviewDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                    }
                }
            }
            .padding(16)
            .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.purple.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func macOSConfidenceLabel(_ value: Int) -> String {
        switch value {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Medium"
        case 4: return "High"
        case 5: return "Very High"
        default: return "Medium"
        }
    }
    
    private func macOSStakesColor(_ stakes: DecisionStakes) -> Color {
        switch stakes {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    #endif
}

#Preview {
    let entry = Entry(kind: .meeting, title: "Weekly Sync")
    entry.rawContent = "Discussed project progress and next steps."
    entry.aiSummary = "Team aligned on Q4 priorities. Key blockers identified."
    
    return NavigationStack {
        EntryDetailView(entry: entry)
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


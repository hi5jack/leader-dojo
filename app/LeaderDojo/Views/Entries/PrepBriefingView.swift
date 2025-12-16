import SwiftUI
import SwiftData

struct PrepBriefingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let project: Project
    
    @State private var isLoading: Bool = true
    @State private var briefing: String = ""
    @State private var error: String? = nil
    @State private var dayRange: Int = 90
    @State private var isSaved: Bool = false
    @State private var showSaveToast: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Project Header
                    projectHeader
                    
                    // Settings
                    settingsSection
                    
                    // Briefing Content
                    if isLoading {
                        loadingView
                    } else if let error = error {
                        errorView(error)
                    } else {
                        briefingContent
                    }
                    
                    // Past Reflection Insights (NEW)
                    reflectionInsightsSection
                    
                    // Decision Context Section (NEW)
                    decisionContextSection
                    
                    // Commitments Summary
                    commitmentsSummary
                    
                    // Recent Timeline
                    recentTimeline
                }
                .padding()
            }
            .navigationTitle("Prep Briefing")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        // Regenerate button
                        Button {
                            Task {
                                await generateBriefing()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isLoading)
                        
                        // Save to Timeline button
                        Button {
                            saveBriefingToTimeline()
                        } label: {
                            Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                        }
                        .disabled(isLoading || briefing.isEmpty || isSaved)
                    }
                }
            }
            .task {
                await generateBriefing()
            }
            .overlay(alignment: .bottom) {
                if showSaveToast {
                    saveToastView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Project Header
    
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Badge(text: project.status.displayName, icon: project.status.icon, color: statusColor)
                Badge(text: "P\(project.priority)", icon: "flag.fill", color: priorityColor)
            }
            
            if let lastActive = project.lastActiveAt {
                Text("Last active \(lastActive, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        HStack {
            Text("Time range:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("", selection: $dayRange) {
                Text("30 days").tag(30)
                Text("60 days").tag(60)
                Text("90 days").tag(90)
                Text("180 days").tag(180)
            }
            .pickerStyle(.segmented)
            .onChange(of: dayRange) { _, _ in
                Task {
                    await generateBriefing()
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text("Generating briefing...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text("Failed to generate briefing")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await generateBriefing()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Briefing Content
    
    private var briefingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Briefing", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.purple)
            
            MarkdownText(briefing)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Reflection Insights Section (NEW)
    
    @ViewBuilder
    private var reflectionInsightsSection: some View {
        let relevantReflections = getRelevantReflections()
        
        if !relevantReflections.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Past Reflection Insights", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundStyle(.pink)
                
                ForEach(relevantReflections.prefix(3)) { reflection in
                    reflectionInsightCard(reflection)
                }
            }
        }
    }
    
    private func reflectionInsightCard(_ reflection: Reflection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reflection.periodDisplay)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(reflection.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let mood = reflection.mood {
                    Text(mood.emoji)
                }
            }
            
            // Show key insight from reflection
            if let firstAnswer = reflection.questionsAnswers.first(where: { !$0.answer.isEmpty }) {
                Text(firstAnswer.answer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            // Show themes if any
            if !reflection.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(reflection.tags.prefix(3), id: \.self) { tag in
                        Text(tag.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.pink.opacity(0.1), in: Capsule())
                            .foregroundStyle(.pink)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.pink.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.pink.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Decision Context Section (NEW)
    
    @ViewBuilder
    private var decisionContextSection: some View {
        let projectDecisions = getProjectDecisions()
        let decisionsNeedingReview = projectDecisions.filter { $0.needsDecisionReview }
        let pendingDecisions = projectDecisions.filter { 
            ($0.decisionOutcome == nil || $0.decisionOutcome == .pending) && !$0.needsDecisionReview
        }
        
        if !projectDecisions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Decision Context", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)
                
                // Decisions needing review - these are actionable
                if !decisionsNeedingReview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Due for Review (\(decisionsNeedingReview.count))", systemImage: "exclamationmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        
                        ForEach(decisionsNeedingReview.prefix(3)) { entry in
                            decisionCard(entry, showReviewIndicator: true)
                        }
                    }
                }
                
                // Pending decisions - context for the meeting
                if !pendingDecisions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Open Decisions", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(pendingDecisions.prefix(3)) { entry in
                            decisionCard(entry, showReviewIndicator: false)
                        }
                    }
                }
                
                // Key assumptions that could be validated
                let assumptionsToValidate = getAssumptionsToValidate()
                if !assumptionsToValidate.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Assumptions to Validate", systemImage: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                        
                        ForEach(assumptionsToValidate, id: \.decision.id) { item in
                            assumptionCard(decision: item.decision, assumption: item.assumption)
                        }
                    }
                }
            }
        }
    }
    
    private func decisionCard(_ entry: Entry, showReviewIndicator: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                if showReviewIndicator {
                    if let days = entry.daysUntilReview, days < 0 {
                        Text("\(abs(days))d overdue")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                } else {
                    Text(entry.occurredAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Show rationale summary
            if let rationale = entry.decisionRationale, !rationale.isEmpty {
                Text("Why: \(rationale)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Show stakes if set
            if let stakes = entry.decisionStakes {
                HStack(spacing: 4) {
                    Image(systemName: stakes.icon)
                        .font(.caption2)
                    Text(stakes.displayName + " stakes")
                        .font(.caption2)
                }
                .foregroundStyle(stakesColor(stakes))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func assumptionCard(decision: Entry, assumption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("From: \(decision.title)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text("• \(assumption)")
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func stakesColor(_ stakes: DecisionStakes) -> Color {
        switch stakes {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    
    /// Get decisions related to this project
    private func getProjectDecisions() -> [Entry] {
        let entries = project.entries ?? []
        return entries
            .filter { $0.isDecisionEntry && !$0.isDeleted }
            .sorted { $0.occurredAt > $1.occurredAt }
    }
    
    /// Extract assumptions that could be validated in this meeting
    private func getAssumptionsToValidate() -> [(decision: Entry, assumption: String)] {
        var results: [(decision: Entry, assumption: String)] = []
        
        let pendingDecisions = getProjectDecisions().filter { 
            $0.decisionOutcome == nil || $0.decisionOutcome == .pending
        }
        
        for decision in pendingDecisions.prefix(5) {
            if let assumptions = decision.decisionAssumptions, !assumptions.isEmpty {
                // Split assumptions by newlines or bullet points
                let assumptionLines = assumptions
                    .components(separatedBy: CharacterSet.newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .map { $0.hasPrefix("•") || $0.hasPrefix("-") ? String($0.dropFirst()).trimmingCharacters(in: .whitespaces) : $0 }
                    .filter { !$0.isEmpty }
                
                for assumption in assumptionLines.prefix(2) {
                    results.append((decision: decision, assumption: assumption))
                }
            }
        }
        
        return Array(results.prefix(5))
    }
    
    // MARK: - Commitments Summary
    
    private var commitmentsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Open Commitments", systemImage: "checklist")
                .font(.headline)
            
            let iOwe = project.commitments?.filter { $0.direction == .iOwe && $0.status.isActive } ?? []
            let waitingFor = project.commitments?.filter { $0.direction == .waitingFor && $0.status.isActive } ?? []
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(.orange)
                        Text("I Owe")
                            .font(.subheadline)
                    }
                    Text("\(iOwe.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Waiting For")
                            .font(.subheadline)
                    }
                    Text("\(waitingFor.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // List overdue items
            let overdueItems = iOwe.filter { $0.isOverdue }
            if !overdueItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    
                    ForEach(overdueItems) { commitment in
                        Text("• \(commitment.title)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Recent Timeline
    
    private var recentTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Activity", systemImage: "clock.fill")
                .font(.headline)
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
            let entries = (project.entries ?? [])
                .filter { $0.deletedAt == nil && $0.occurredAt > cutoffDate }
                .sorted { $0.occurredAt > $1.occurredAt }
                .prefix(5)
            
            if entries.isEmpty {
                Text("No entries in the selected time range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(Array(entries)) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: entry.kind.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.subheadline)
                            Text(entry.occurredAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Toast View
    
    private var saveToastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Prep saved to timeline")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThickMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }
    
    // MARK: - Actions
    
    private func saveBriefingToTimeline() {
        // Create a prep entry with the briefing content
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let entry = Entry(
            kind: .prep,
            title: "Prep: \(project.name)",
            occurredAt: Date(),
            rawContent: briefing,
            aiSummary: nil,
            isDecision: false
        )
        
        entry.project = project
        modelContext.insert(entry)
        
        // Update project's last active timestamp
        project.markActive()
        
        do {
            try modelContext.save()
            
            // Show success state
            isSaved = true
            withAnimation(.easeInOut) {
                showSaveToast = true
            }
            
            // Hide toast after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut) {
                    showSaveToast = false
                }
            }
        } catch {
            // Handle error silently for now
            print("Failed to save prep briefing: \(error)")
        }
    }
    
    private func generateBriefing() async {
        await MainActor.run {
            isLoading = true
            error = nil
            isSaved = false  // Reset saved state on regenerate
        }
        
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
            let recentEntries = (project.entries ?? [])
                .filter { $0.deletedAt == nil && $0.occurredAt > cutoffDate }
                .sorted { $0.occurredAt > $1.occurredAt }
            
            let openCommitments = (project.commitments ?? [])
                .filter { $0.status.isActive }
            
            // NEW: Include relevant reflections in briefing generation
            let relevantReflections = getRelevantReflections()
            
            let result = try await AIService.shared.generatePrepBriefing(
                project: project,
                recentEntries: recentEntries,
                openCommitments: openCommitments,
                relevantReflections: relevantReflections
            )
            
            await MainActor.run {
                briefing = result.briefing
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    /// Get reflections relevant to this project
    private func getRelevantReflections() -> [Reflection] {
        // Get project-specific reflections first
        var reflections = (project.reflections ?? [])
            .sorted { $0.createdAt > $1.createdAt }
        
        // Also include periodic reflections that mention this project's entries
        let projectEntryIds = Set((project.entries ?? []).map { $0.id })
        let periodicReflectionsWithProjectEntries = reflections.filter { reflection in
            reflection.reflectionType == .periodic &&
            !Set(reflection.linkedEntryIds).isDisjoint(with: projectEntryIds)
        }
        
        // Combine and dedupe
        let allRelevant = Set(reflections + periodicReflectionsWithProjectEntries)
        
        return Array(allRelevant)
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch project.status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
    
    private var priorityColor: Color {
        switch project.priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
}

#Preview {
    PrepBriefingView(project: Project(name: "Sample Project"))
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}

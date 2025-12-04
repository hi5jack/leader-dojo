import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Commitment.dueDate)
    private var allCommitments: [Commitment]
    
    @Query(sort: \Entry.occurredAt, order: .reverse)
    private var allEntries: [Entry]
    
    @Query(sort: \Project.lastActiveAt)
    private var allProjects: [Project]
    
    @Query(sort: \Reflection.createdAt, order: .reverse)
    private var reflections: [Reflection]
    
    var body: some View {
        dashboardContent
    }
    
    private var dashboardContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Weekly Focus Section
                weeklyFocusSection
                
                // Decisions Section
                decisionsSection
                
                // Reflection Prompt
                reflectionSection
                
                // Projects Needing Attention
                attentionProjectsSection
                
                // Quick Stats
                quickStatsSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CaptureView()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }
    
    // MARK: - Weekly Focus Section
    
    private var weeklyFocusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Weekly Focus", icon: "target", color: .orange)
            
            if topCommitments.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.circle",
                    title: "All Clear",
                    message: "No open commitments. Great job staying on top of things!"
                )
            } else {
                ForEach(topCommitments) { commitment in
                    CommitmentRow(commitment: commitment) {
                        markCommitmentDone(commitment)
                    }
                }
                
                if openIOweCommitments.count > 5 {
                    NavigationLink {
                        CommitmentsListView()
                    } label: {
                        Text("View all \(openIOweCommitments.count) commitments")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Attention Projects Section
    
    private var attentionProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Needs Attention", icon: "exclamationmark.triangle.fill", color: .red)
            
            if projectsNeedingAttention.isEmpty {
                EmptyStateCard(
                    icon: "hand.thumbsup.fill",
                    title: "Looking Good",
                    message: "All high-priority projects are active."
                )
            } else {
                ForEach(projectsNeedingAttention) { project in
                    #if os(macOS)
                    NavigationLink(value: AppRoute.project(project.persistentModelID)) {
                        ProjectAttentionRow(project: project)
                    }
                    .buttonStyle(.plain)
                    #else
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        ProjectAttentionRow(project: project)
                    }
                    .buttonStyle(.plain)
                    #endif
                }
            }
        }
    }
    
    // MARK: - Decisions Section
    
    private var decisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Decisions", icon: "checkmark.seal.fill", color: .purple)
                
                Spacer()
                
                #if os(macOS)
                NavigationLink(value: AppRoute.decisionInsights) {
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                }
                #else
                NavigationLink {
                    DecisionInsightsView()
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                }
                #endif
            }
            
            if !hasDecisionsToShow {
                EmptyStateCard(
                    icon: "checkmark.seal",
                    title: "No Decisions to Review",
                    message: "Your decisions are on track. Keep recording key decisions to build your learning history."
                )
            } else {
                // Prioritized decision list (max 4 items)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(prioritizedDecisionReviews, id: \.entry.id) { item in
                        NavigationLink {
                            EntryDetailView(entry: item.entry)
                        } label: {
                            PrioritizedDecisionRow(entry: item.entry, priority: item.priority)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Show "See all" link if there are more decisions
                    let totalCount = overdueDecisions.count + decisionsDueSoon.count + staleDecisions.count
                    if totalCount > 4 {
                        #if os(macOS)
                        NavigationLink(value: AppRoute.decisionInsights) {
                            HStack {
                                Text("See all \(totalCount) decisions")
                                    .font(.caption)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.purple)
                        }
                        #else
                        NavigationLink {
                            DecisionInsightsView()
                        } label: {
                            HStack {
                                Text("See all \(totalCount) decisions")
                                    .font(.caption)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.purple)
                        }
                        #endif
                    }
                }
                
                // Quick decision stats
                if decisionsThisQuarter > 0 {
                    HStack(spacing: 12) {
                        MiniStatCard(title: "This Quarter", value: "\(decisionsThisQuarter)", color: .purple)
                        MiniStatCard(title: "Validated", value: "\(validatedRate)%", color: .green)
                    }
                }
            }
        }
    }
    
    // MARK: - Reflection Section (Enhanced)
    
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Reflect", icon: "brain.head.profile", color: .purple)
                
                Spacer()
                
                #if os(macOS)
                // Use value-based navigation so it integrates with NavigationStack(path:)
                // and sidebar clicks can pop the view by clearing the path.
                NavigationLink(value: AppRoute.reflectionInsights) {
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                }
                #else
                NavigationLink {
                    ReflectionInsightsView()
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                }
                #endif
            }
            
            // Smart prompting based on context (Guardrail: max 1 passive prompt per day)
            getContextualReflectionPrompt()
        }
    }
    
    /// Smart contextual prompting - shows ONE relevant prompt based on user's situation
    @ViewBuilder
    private func getContextualReflectionPrompt() -> some View {
        // If user already reflected today, don't show passive prompts, just recap
        if hasReflectedToday {
            if let lastReflection = reflections.first {
                ReflectionSummaryCard(reflection: lastReflection)
            } else {
                EmptyStateCard(
                    icon: "lightbulb",
                    title: "Start Reflecting",
                    message: "Create your first reflection to track your growth."
                )
            }
        }
        // Weekly reflection prompt takes priority
        else if shouldPromptWeeklyReflection {
            #if os(macOS)
            // Use value-based navigation so it integrates with NavigationStack(path:)
            // and sidebar clicks can pop the view by clearing the path.
            NavigationLink(value: AppRoute.newPeriodicReflection(.week)) {
                ReflectionPromptCard(
                    title: "Weekly Reflection",
                    message: "Take a few minutes to reflect on your week. You had \(entriesThisWeek) entries.",
                    icon: "calendar.badge.clock"
                )
            }
            .buttonStyle(.plain)
            #else
            NavigationLink {
                NewReflectionView(periodType: .week)
            } label: {
                ReflectionPromptCard(
                    title: "Weekly Reflection",
                    message: "Take a few minutes to reflect on your week. You had \(entriesThisWeek) entries.",
                    icon: "calendar.badge.clock"
                )
            }
            .buttonStyle(.plain)
            #endif
        }
        // Project needing reflection (hasn't been reflected on in 2+ weeks)
        else if let projectNeedingReflection = projectNeedingReflection {
            NavigationLink {
                NewReflectionView(project: projectNeedingReflection)
            } label: {
                ReflectionPromptCard(
                    title: "Project Check-In",
                    message: "How are you showing up for \(projectNeedingReflection.name)?",
                    icon: "folder.fill"
                )
            }
            .buttonStyle(.plain)
        }
        // High activity week - suggest quick reflection
        else if entriesThisWeek >= 5 && quickReflectionsToday < QuickReflectionTrigger.maxPromptsPerDay {
            ReflectionPromptCard(
                title: "Busy Week",
                message: "You've been active! Consider a quick reflection on what's working.",
                icon: "bolt.fill"
            )
        }
        // Fallback: show latest reflection summary or empty state
        else if let lastReflection = reflections.first {
            ReflectionSummaryCard(reflection: lastReflection)
        } else {
            EmptyStateCard(
                icon: "lightbulb",
                title: "Start Reflecting",
                message: "Create your first reflection to track your growth."
            )
        }
    }
    
    private var hasReflectedToday: Bool {
        let calendar = Calendar.current
        return reflections.contains { calendar.isDateInToday($0.createdAt) }
    }
    
    private var quickReflectionsToday: Int {
        QuickReflectionTrigger.quickReflectionsToday(from: reflections)
    }
    
    private var projectNeedingReflection: Project? {
        activeProjects.first { $0.needsReflection }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Overview", icon: "chart.bar.fill", color: .cyan)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(title: "Active Projects", value: "\(activeProjects.count)", icon: "folder.fill", color: .blue)
                StatCard(title: "I Owe", value: "\(openIOweCommitments.count)", icon: "arrow.up.right", color: .orange)
                StatCard(title: "Waiting For", value: "\(waitingForCount)", icon: "arrow.down.left", color: .green)
                StatCard(title: "This Week", value: "\(entriesThisWeek)", icon: "doc.text.fill", color: .purple)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var openIOweCommitments: [Commitment] {
        allCommitments.filter { $0.direction == .iOwe && $0.status == .open }
    }
    
    private var topCommitments: [Commitment] {
        Array(openIOweCommitments.sorted { $0.priorityScore > $1.priorityScore }.prefix(5))
    }
    
    private var activeProjects: [Project] {
        allProjects.filter { $0.status == .active }
    }
    
    private var projectsNeedingAttention: [Project] {
        activeProjects.filter { $0.needsAttention }.prefix(3).map { $0 }
    }
    
    private var shouldPromptWeeklyReflection: Bool {
        guard let lastReflection = reflections.first(where: { $0.periodType == .week }) else {
            return true
        }
        
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return lastReflection.createdAt < weekAgo
    }
    
    private var waitingForCount: Int {
        allCommitments.filter { $0.direction == .waitingFor && $0.status == .open }.count
    }
    
    private var entriesThisWeek: Int {
        allEntries.filter { !$0.isDeleted && isDateInThisWeek($0.occurredAt) }.count
    }
    
    // MARK: - Decision Computed Properties
    
    private var allDecisions: [Entry] {
        allEntries.filter { $0.isDecisionEntry && !$0.isDeleted }
    }
    
    /// Overdue decisions (review date has passed, no outcome yet)
    private var overdueDecisions: [Entry] {
        allDecisions
            .filter { $0.needsDecisionReview }
            .sorted { ($0.decisionReviewDate ?? .distantPast) < ($1.decisionReviewDate ?? .distantPast) }
    }
    
    /// Decisions due within next 7 days (not yet overdue)
    private var decisionsDueSoon: [Entry] {
        let now = Date()
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return allDecisions.filter { entry in
            guard let reviewDate = entry.decisionReviewDate else { return false }
            guard entry.decisionOutcome == nil || entry.decisionOutcome == .pending else { return false }
            return reviewDate > now && reviewDate <= sevenDaysFromNow
        }
        .sorted { ($0.decisionReviewDate ?? .distantFuture) < ($1.decisionReviewDate ?? .distantFuture) }
    }
    
    /// Stale decisions (30+ days old, no outcome, no review date set)
    private var staleDecisions: [Entry] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allDecisions.filter { entry in
            (entry.decisionOutcome == nil || entry.decisionOutcome == .pending) &&
            entry.occurredAt < thirtyDaysAgo &&
            entry.decisionReviewDate == nil  // No review date set
        }
    }
    
    /// Combined prioritized list for dashboard (max 4 items)
    private var prioritizedDecisionReviews: [(entry: Entry, priority: DecisionReviewPriority)] {
        var results: [(Entry, DecisionReviewPriority)] = []
        
        // Add overdue first
        for entry in overdueDecisions {
            results.append((entry, .overdue))
        }
        
        // Add due soon
        for entry in decisionsDueSoon {
            results.append((entry, .dueSoon))
        }
        
        // Add stale
        for entry in staleDecisions {
            results.append((entry, .stale))
        }
        
        return Array(results.prefix(4))
    }
    
    private var hasDecisionsToShow: Bool {
        !overdueDecisions.isEmpty || !decisionsDueSoon.isEmpty || !staleDecisions.isEmpty
    }
    
    private var decisionsThisQuarter: Int {
        let calendar = Calendar.current
        let now = Date()
        let quarter = calendar.component(.quarter, from: now)
        let year = calendar.component(.year, from: now)
        
        var components = DateComponents()
        components.year = year
        components.month = (quarter - 1) * 3 + 1
        components.day = 1
        
        guard let quarterStart = calendar.date(from: components) else { return 0 }
        
        return allDecisions.filter { $0.occurredAt >= quarterStart }.count
    }
    
    private var validatedRate: Int {
        let reviewedDecisions = allDecisions.filter { $0.hasBeenReviewed }
        guard !reviewedDecisions.isEmpty else { return 0 }
        
        let validated = reviewedDecisions.filter { $0.decisionOutcome == .validated }.count
        return Int(Double(validated) / Double(reviewedDecisions.count) * 100)
    }
    
    private func isDateInThisWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }
        
        return date >= weekStart && date < weekEnd
    }
    
    // MARK: - Actions
    
    private func markCommitmentDone(_ commitment: Commitment) {
        commitment.markDone()
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct CommitmentRow: View {
    let commitment: Commitment
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(commitment.title)
                    .font(.subheadline)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let projectName = commitment.project?.name {
                        Text(projectName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let dueDate = commitment.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(commitment.isOverdue ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            if commitment.isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ProjectAttentionRow: View {
    let project: Project
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let days = project.daysSinceLastActive {
                    Text("\(days) days since last activity")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ReflectionPromptCard: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ReflectionSummaryCard: View {
    let reflection: Reflection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reflection.periodDisplay)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count) questions answered")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Decision Review Priority

enum DecisionReviewPriority {
    case overdue    // Review date has passed
    case dueSoon    // Review date within 7 days
    case stale      // 30+ days old, no review date
    
    var badgeText: (Entry) -> String {
        return { entry in
            switch self {
            case .overdue:
                if let days = entry.daysUntilReview, days < 0 {
                    return "\(abs(days))d overdue"
                }
                return "overdue"
            case .dueSoon:
                if let days = entry.daysUntilReview, days >= 0 {
                    return days == 0 ? "due today" : "due in \(days)d"
                }
                return "due soon"
            case .stale:
                return "needs review"
            }
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .overdue: return .red
        case .dueSoon: return .orange
        case .stale: return .secondary
        }
    }
    
    var icon: String {
        switch self {
        case .overdue: return "exclamationmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .stale: return "questionmark.circle"
        }
    }
}

struct PrioritizedDecisionRow: View {
    let entry: Entry
    let priority: DecisionReviewPriority
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let projectName = entry.project?.name {
                        Text(projectName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Priority badge
                    HStack(spacing: 3) {
                        Image(systemName: priority.icon)
                            .font(.caption2)
                        Text(priority.badgeText(entry))
                            .font(.caption)
                    }
                    .foregroundStyle(priority.badgeColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DecisionReviewRow: View {
    let entry: Entry
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let projectName = entry.project?.name {
                        Text(projectName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if entry.needsDecisionReview {
                        if let days = entry.daysUntilReview, days < 0 {
                            Text("\(abs(days)) days overdue")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text(entry.occurredAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if entry.needsDecisionReview {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}


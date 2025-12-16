import SwiftUI
import SwiftData

/// Decision analytics view showing patterns and learning insights
struct DecisionInsightsView: View {
    @Query(sort: \Entry.occurredAt, order: .reverse)
    private var allEntries: [Entry]
    
    // AI Pattern Analysis State
    @State private var aiAnalysis: DecisionPatternAnalysis? = nil
    @State private var isLoadingAI: Bool = false
    @State private var aiError: String? = nil
    
    private var decisions: [Entry] {
        allEntries.filter { $0.isDecisionEntry && !$0.isDeleted }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Overview Stats
                overviewSection
                
                // AI Pattern Insights
                aiInsightsSection
                
                // Outcome Distribution
                outcomeDistributionSection
                
                // Confidence Calibration
                confidenceCalibrationSection
                
                // By Stakes Level
                stakesAnalysisSection
                
                // Recent Decisions
                recentDecisionsSection
            }
            .padding()
        }
        .navigationTitle("Decision Insights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await loadAIAnalysis()
                    }
                } label: {
                    if isLoadingAI {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .disabled(isLoadingAI || decisions.count < 3)
            }
        }
        .task {
            // Auto-load AI analysis if we have enough decisions
            if decisions.count >= 3 {
                await loadAIAnalysis()
            }
        }
    }
    
    // MARK: - AI Insights Section
    
    @ViewBuilder
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "AI Insights", icon: "sparkles", color: .indigo)
                
                Spacer()
                
                if isLoadingAI {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                }
            }
            
            if let analysis = aiAnalysis, analysis.hasInsights {
                VStack(alignment: .leading, spacing: 12) {
                    if let calibration = analysis.calibrationInsight {
                        AIInsightCard(
                            icon: "gauge.medium",
                            title: "Confidence Calibration",
                            insight: calibration,
                            color: .cyan
                        )
                    }
                    
                    if let stakes = analysis.stakesPatternInsight {
                        AIInsightCard(
                            icon: "flag.fill",
                            title: "Stakes Pattern",
                            insight: stakes,
                            color: .orange
                        )
                    }
                    
                    if let timing = analysis.timingInsight {
                        AIInsightCard(
                            icon: "clock.fill",
                            title: "Review Timing",
                            insight: timing,
                            color: .green
                        )
                    }
                    
                    // Overall recommendation
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                        
                        Text(analysis.overallRecommendation)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            } else if let error = aiError {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else if decisions.count < 3 {
                EmptyStateCard(
                    icon: "sparkles",
                    title: "Not Enough Data",
                    message: "Record at least 3 decisions to see AI-powered pattern analysis."
                )
            } else {
                Button {
                    Task {
                        await loadAIAnalysis()
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate AI Insights")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.indigo.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func loadAIAnalysis() async {
        guard !isLoadingAI else { return }
        
        await MainActor.run {
            isLoadingAI = true
            aiError = nil
        }
        
        do {
            let result = try await AIService.shared.analyzeDecisionPatterns(decisions: decisions)
            await MainActor.run {
                aiAnalysis = result
                isLoadingAI = false
            }
        } catch {
            await MainActor.run {
                aiError = error.localizedDescription
                isLoadingAI = false
            }
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Overview", icon: "chart.bar.fill", color: .purple)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InsightStatCard(
                    title: "Total Decisions",
                    value: "\(decisions.count)",
                    icon: "checkmark.seal.fill",
                    color: .purple
                )
                
                InsightStatCard(
                    title: "Reviewed",
                    value: "\(reviewedDecisions.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                InsightStatCard(
                    title: "Pending Review",
                    value: "\(decisionsNeedingReview.count)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                InsightStatCard(
                    title: "Validation Rate",
                    value: "\(validationRate)%",
                    icon: "target",
                    color: validationRate >= 70 ? .green : (validationRate >= 50 ? .yellow : .red)
                )
            }
        }
    }
    
    // MARK: - Outcome Distribution Section
    
    private var outcomeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Outcome Distribution", icon: "chart.pie.fill", color: .blue)
            
            if reviewedDecisions.isEmpty {
                EmptyStateCard(
                    icon: "chart.pie",
                    title: "No Reviewed Decisions",
                    message: "Review your past decisions to see outcome patterns."
                )
            } else {
                VStack(spacing: 8) {
                    OutcomeRow(
                        outcome: .validated,
                        count: outcomeCount(.validated),
                        total: reviewedDecisions.count
                    )
                    OutcomeRow(
                        outcome: .invalidated,
                        count: outcomeCount(.invalidated),
                        total: reviewedDecisions.count
                    )
                    OutcomeRow(
                        outcome: .mixed,
                        count: outcomeCount(.mixed),
                        total: reviewedDecisions.count
                    )
                    OutcomeRow(
                        outcome: .superseded,
                        count: outcomeCount(.superseded),
                        total: reviewedDecisions.count
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Confidence Calibration Section
    
    private var confidenceCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Confidence Calibration", icon: "gauge.medium", color: .cyan)
            
            let calibrationData = confidenceCalibration
            
            if calibrationData.isEmpty {
                EmptyStateCard(
                    icon: "gauge.medium",
                    title: "Not Enough Data",
                    message: "Record decision confidence levels and review outcomes to see calibration."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(calibrationData.sorted(by: { $0.key < $1.key }), id: \.key) { confidence, rate in
                        CalibrationRow(
                            confidenceLevel: confidence,
                            validationRate: rate,
                            decisionCount: decisionsAtConfidence(confidence)
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Calibration insight
                if let insight = calibrationInsight {
                    Text(insight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    // MARK: - Stakes Analysis Section
    
    private var stakesAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "By Stakes Level", icon: "flag.fill", color: .red)
            
            let stakesData = decisionsByStakes
            
            if stakesData.isEmpty {
                EmptyStateCard(
                    icon: "flag",
                    title: "No Stakes Data",
                    message: "Set stakes levels on your decisions to see patterns."
                )
            } else {
                HStack(spacing: 12) {
                    ForEach([DecisionStakes.low, .medium, .high], id: \.self) { stakes in
                        StakesCard(
                            stakes: stakes,
                            count: stakesData[stakes] ?? 0,
                            validationRate: validationRateForStakes(stakes)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Decisions Section
    
    private var recentDecisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Decisions", icon: "clock.fill", color: .secondary)
            
            if decisions.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.seal",
                    title: "No Decisions Yet",
                    message: "Start logging decisions to build your decision history."
                )
            } else {
                ForEach(decisions.prefix(5)) { entry in
                    #if os(macOS)
                    // Use value-based navigation on macOS so it integrates with
                    // NavigationStack(path:) and sidebar clicks can pop the view.
                    NavigationLink(value: AppRoute.entry(entry.persistentModelID)) {
                        RecentDecisionRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    #else
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        RecentDecisionRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    #endif
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var reviewedDecisions: [Entry] {
        decisions.filter { $0.hasBeenReviewed }
    }
    
    private var decisionsNeedingReview: [Entry] {
        decisions.filter { $0.needsDecisionReview }
    }
    
    private var validationRate: Int {
        guard !reviewedDecisions.isEmpty else { return 0 }
        let validated = reviewedDecisions.filter { $0.decisionOutcome == .validated }.count
        return Int(Double(validated) / Double(reviewedDecisions.count) * 100)
    }
    
    private func outcomeCount(_ outcome: DecisionOutcome) -> Int {
        reviewedDecisions.filter { $0.decisionOutcome == outcome }.count
    }
    
    private var confidenceCalibration: [Int: Int] {
        var calibration: [Int: Int] = [:]
        
        for confidence in 1...5 {
            let decisionsAtLevel = reviewedDecisions.filter { $0.decisionConfidence == confidence }
            guard !decisionsAtLevel.isEmpty else { continue }
            
            let validated = decisionsAtLevel.filter { $0.decisionOutcome == .validated }.count
            calibration[confidence] = Int(Double(validated) / Double(decisionsAtLevel.count) * 100)
        }
        
        return calibration
    }
    
    private func decisionsAtConfidence(_ confidence: Int) -> Int {
        decisions.filter { $0.decisionConfidence == confidence }.count
    }
    
    private var calibrationInsight: String? {
        let calibration = confidenceCalibration
        guard calibration.count >= 2 else { return nil }
        
        // Check for overconfidence (high confidence but low validation)
        if let highConfRate = calibration[5], let lowConfRate = calibration[1] ?? calibration[2] {
            if highConfRate < lowConfRate + 20 {
                return "💡 Your high-confidence decisions don't validate much better than low-confidence ones. Consider slowing down on \"sure things.\""
            }
        }
        
        // Check for good calibration
        if let rate4 = calibration[4], let rate5 = calibration[5] {
            if rate5 > rate4 && rate5 >= 70 {
                return "✅ Good calibration! Your confidence levels align well with actual outcomes."
            }
        }
        
        return nil
    }
    
    private var decisionsByStakes: [DecisionStakes: Int] {
        var counts: [DecisionStakes: Int] = [:]
        for decision in decisions {
            if let stakes = decision.decisionStakes {
                counts[stakes, default: 0] += 1
            }
        }
        return counts
    }
    
    private func validationRateForStakes(_ stakes: DecisionStakes) -> Int {
        let reviewed = reviewedDecisions.filter { $0.decisionStakes == stakes }
        guard !reviewed.isEmpty else { return 0 }
        let validated = reviewed.filter { $0.decisionOutcome == .validated }.count
        return Int(Double(validated) / Double(reviewed.count) * 100)
    }
}

// MARK: - Supporting Views

struct AIInsightCard: View {
    let icon: String
    let title: String
    let insight: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text(insight)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct OutcomeRow: View {
    let outcome: DecisionOutcome
    let count: Int
    let total: Int
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: outcome.icon)
                .font(.body)
                .foregroundStyle(outcomeColor)
                .frame(width: 24)
            
            Text(outcome.displayName)
                .font(.subheadline)
            
            Spacer()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(outcomeColor)
                        .frame(width: geo.size.width * percentage, height: 8)
                }
            }
            .frame(width: 80, height: 8)
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    private var outcomeColor: Color {
        switch outcome {
        case .pending: return .gray
        case .validated: return .green
        case .invalidated: return .red
        case .mixed: return .yellow
        case .superseded: return .blue
        }
    }
}

struct CalibrationRow: View {
    let confidenceLevel: Int
    let validationRate: Int
    let decisionCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Confidence level indicator
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= confidenceLevel ? .purple : .purple.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            
            Text(confidenceLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            // Validation rate bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(validationColor)
                        .frame(width: geo.size.width * Double(validationRate) / 100, height: 8)
                }
            }
            .frame(width: 60, height: 8)
            
            Text("\(validationRate)%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    private var confidenceLabel: String {
        switch confidenceLevel {
        case 1: return "Very Uncertain"
        case 2: return "Uncertain"
        case 3: return "Neutral"
        case 4: return "Confident"
        case 5: return "Very Confident"
        default: return "Unknown"
        }
    }
    
    private var validationColor: Color {
        if validationRate >= 70 { return .green }
        if validationRate >= 50 { return .yellow }
        return .red
    }
}

struct StakesCard: View {
    let stakes: DecisionStakes
    let count: Int
    let validationRate: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: stakes.icon)
                .font(.title2)
                .foregroundStyle(stakesColor)
            
            Text(stakes.displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            
            if count > 0 {
                Text("\(validationRate)% validated")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var stakesColor: Color {
        switch stakes {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

struct RecentDecisionRow: View {
    let entry: Entry
    
    var body: some View {
        HStack(spacing: 12) {
            // Outcome indicator
            if let outcome = entry.decisionOutcome, outcome != .pending {
                Image(systemName: outcome.icon)
                    .font(.title3)
                    .foregroundStyle(outcomeColor(outcome))
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }
            
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
                    
                    Text(entry.occurredAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let stakes = entry.decisionStakes {
                Image(systemName: stakes.icon)
                    .font(.caption)
                    .foregroundStyle(stakesColor(stakes))
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
    
    private func stakesColor(_ stakes: DecisionStakes) -> Color {
        switch stakes {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

#Preview {
    NavigationStack {
        DecisionInsightsView()
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


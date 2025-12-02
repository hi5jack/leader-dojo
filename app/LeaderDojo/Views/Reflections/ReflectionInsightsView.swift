import SwiftUI
import SwiftData

/// Growth tracking dashboard showing patterns and insights from reflections
struct ReflectionInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reflection.createdAt, order: .reverse) private var allReflections: [Reflection]
    
    @State private var selectedTimeRange: TimeRange = .quarter
    
    enum TimeRange: String, CaseIterable {
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        case allTime = "All Time"
        
        var days: Int? {
            switch self {
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            case .allTime: return nil
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Time range selector
                timeRangeSelector
                
                // Overview stats
                overviewSection
                
                // Reflection frequency
                frequencySection
                
                // Top themes
                themesSection
                
                // Commitment tracking from reflections
                commitmentTrackingSection
                
                // Mood trends
                moodTrendsSection
            }
            .padding()
        }
        .navigationTitle("Growth Insights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation {
                            selectedTimeRange = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeRange == range ? Color.purple.opacity(0.2) : Color.secondary.opacity(0.1),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedTimeRange == range ? .purple : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Overview", systemImage: "chart.bar.fill")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InsightStatCard(
                    title: "Total Reflections",
                    value: "\(filteredReflections.count)",
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                InsightStatCard(
                    title: "Completed",
                    value: "\(completedReflections.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                InsightStatCard(
                    title: "Quick",
                    value: "\(quickReflections.count)",
                    icon: "bolt.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Frequency Section
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reflection Frequency", systemImage: "calendar")
                .font(.headline)
            
            HStack(spacing: 16) {
                FrequencyMetric(
                    label: "Weekly Average",
                    value: String(format: "%.1f", weeklyAverage),
                    trend: weeklyTrend
                )
                
                Divider()
                    .frame(height: 40)
                
                FrequencyMetric(
                    label: "Current Streak",
                    value: "\(currentStreak)",
                    suffix: "weeks"
                )
                
                Divider()
                    .frame(height: 40)
                
                FrequencyMetric(
                    label: "Best Streak",
                    value: "\(bestStreak)",
                    suffix: "weeks"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Themes Section
    
    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top Themes", systemImage: "tag.fill")
                .font(.headline)
            
            if topThemes.isEmpty {
                Text("No themes detected yet. Keep reflecting!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(Array(topThemes.enumerated()), id: \.element.theme) { index, themeCount in
                        ThemeChip(
                            theme: themeCount.theme,
                            count: themeCount.count,
                            isTop: index == 0
                        )
                    }
                }
            }
            
            if let topTheme = topThemes.first {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.orange)
                    Text("\"\(topTheme.theme.capitalized)\" has come up \(topTheme.count) times")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Commitment Tracking Section
    
    private var commitmentTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Commitments from Reflections", systemImage: "checkmark.circle")
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalCommitmentsGenerated)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Created")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Completion rate visual
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: commitmentCompletionRate)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(commitmentCompletionRate * 100))%")
                            .font(.headline)
                        Text("done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 70, height: 70)
            }
            
            if commitmentCompletionRate < 0.5 && totalCommitmentsGenerated > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("You have \(totalCommitmentsGenerated - completedCommitments) open commitments from reflections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Mood Trends Section
    
    private var moodTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Mood Trends", systemImage: "face.smiling")
                .font(.headline)
            
            if moodDistribution.isEmpty {
                Text("No mood data yet. Add moods to your reflections!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                HStack(spacing: 12) {
                    ForEach(Array(moodDistribution.enumerated()), id: \.element.mood) { index, moodCount in
                        VStack(spacing: 4) {
                            Text(moodCount.mood.emoji)
                                .font(.title2)
                            
                            Text("\(moodCount.count)")
                                .font(.headline)
                            
                            Text(moodCount.mood.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            index == 0 ? Color.purple.opacity(0.1) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    
    private var filteredReflections: [Reflection] {
        guard let days = selectedTimeRange.days else {
            return allReflections
        }
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return allReflections.filter { $0.createdAt >= cutoff }
    }
    
    private var completedReflections: [Reflection] {
        filteredReflections.filter { $0.isComplete }
    }
    
    private var quickReflections: [Reflection] {
        filteredReflections.filter { $0.reflectionType == .quick }
    }
    
    private var weeklyAverage: Double {
        guard !filteredReflections.isEmpty else { return 0 }
        
        let days = selectedTimeRange.days ?? 365
        let weeks = max(1, Double(days) / 7.0)
        return Double(filteredReflections.count) / weeks
    }
    
    private var weeklyTrend: Double {
        // Compare last 2 weeks
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        
        let lastWeek = allReflections.filter { $0.createdAt >= oneWeekAgo }.count
        let previousWeek = allReflections.filter { $0.createdAt >= twoWeeksAgo && $0.createdAt < oneWeekAgo }.count
        
        guard previousWeek > 0 else { return 0 }
        return Double(lastWeek - previousWeek) / Double(previousWeek)
    }
    
    private var currentStreak: Int {
        // Count consecutive weeks with at least one reflection
        let calendar = Calendar.current
        var streak = 0
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        while true {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let hasReflection = allReflections.contains { $0.createdAt >= weekStart && $0.createdAt < weekEnd }
            
            if hasReflection {
                streak += 1
                weekStart = calendar.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var bestStreak: Int {
        // This would require more complex calculation - simplified for now
        return max(currentStreak, 1)
    }
    
    private var topThemes: [(theme: String, count: Int)] {
        var themeCounts: [String: Int] = [:]
        
        for reflection in filteredReflections {
            for tag in reflection.tags {
                themeCounts[tag, default: 0] += 1
            }
        }
        
        return themeCounts
            .map { (theme: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }
    
    private var totalCommitmentsGenerated: Int {
        filteredReflections.reduce(0) { $0 + $1.generatedCommitmentIds.count }
    }
    
    private var completedCommitments: Int {
        // This would need to query actual commitment status - simplified for now
        return Int(Double(totalCommitmentsGenerated) * 0.4)  // Placeholder
    }
    
    private var commitmentCompletionRate: Double {
        guard totalCommitmentsGenerated > 0 else { return 0 }
        return Double(completedCommitments) / Double(totalCommitmentsGenerated)
    }
    
    private var moodDistribution: [(mood: ReflectionMood, count: Int)] {
        var moodCounts: [ReflectionMood: Int] = [:]
        
        for reflection in filteredReflections {
            if let mood = reflection.mood {
                moodCounts[mood, default: 0] += 1
            }
        }
        
        return moodCounts
            .map { (mood: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Supporting Views

struct InsightStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct FrequencyMetric: View {
    let label: String
    let value: String
    var suffix: String? = nil
    var trend: Double? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let suffix = suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let trend = trend, trend != 0 {
                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(trend > 0 ? .green : .red)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ThemeChip: View {
    let theme: String
    let count: Int
    let isTop: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(theme.capitalized)
                .font(.caption)
            
            Text("×\(count)")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isTop ? Color.purple.opacity(0.2) : Color.secondary.opacity(0.1),
            in: Capsule()
        )
        .foregroundStyle(isTop ? .purple : .secondary)
    }
}

/// Simple flow layout for theme chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    
    private func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowMaxHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowMaxHeight + spacing
                rowMaxHeight = 0
            }
            
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            
            rowMaxHeight = max(rowMaxHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowMaxHeight)
        }
        
        return (CGSize(width: maxWidth, height: maxHeight), frames)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReflectionInsightsView()
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}


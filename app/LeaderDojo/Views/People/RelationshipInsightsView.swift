import SwiftUI
import SwiftData

/// Aggregate view showing relationship health patterns and insights across all people
struct RelationshipInsightsView: View {
    @Query(sort: \Person.name) private var allPeople: [Person]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header Summary
                healthSummarySection
                
                // At Risk Relationships
                atRiskSection
                
                // Commitment Balance Overview
                balanceOverviewSection
                
                // Interaction Frequency Insights
                interactionInsightsSection
                
                // Reflection Recommendations
                reflectionRecommendationsSection
            }
            .padding()
        }
        .navigationTitle("Relationship Insights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    // MARK: - Health Summary
    
    private var healthySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Overview", systemImage: "chart.pie.fill")
                .font(.headline)
            
            HStack(spacing: 16) {
                healthStatCard(
                    status: .healthy,
                    count: healthyCount,
                    total: allPeople.count
                )
                
                healthStatCard(
                    status: .needsAttention,
                    count: needsAttentionCount,
                    total: allPeople.count
                )
                
                healthStatCard(
                    status: .atRisk,
                    count: atRiskCount,
                    total: allPeople.count
                )
            }
        }
    }
    
    private var healthSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Relationship Health Overview", systemImage: "heart.text.square.fill")
                .font(.headline)
                .foregroundStyle(.pink)
            
            // Health distribution chart
            GeometryReader { geo in
                let total = max(allPeople.count, 1)
                HStack(spacing: 0) {
                    if healthyCount > 0 {
                        Rectangle()
                            .fill(healthColor(.healthy))
                            .frame(width: geo.size.width * CGFloat(healthyCount) / CGFloat(total))
                    }
                    if needsAttentionCount > 0 {
                        Rectangle()
                            .fill(healthColor(.needsAttention))
                            .frame(width: geo.size.width * CGFloat(needsAttentionCount) / CGFloat(total))
                    }
                    if atRiskCount > 0 {
                        Rectangle()
                            .fill(healthColor(.atRisk))
                            .frame(width: geo.size.width * CGFloat(atRiskCount) / CGFloat(total))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: 24)
            
            // Legend
            HStack(spacing: 20) {
                healthLegendItem(status: .healthy, count: healthyCount)
                healthLegendItem(status: .needsAttention, count: needsAttentionCount)
                healthLegendItem(status: .atRisk, count: atRiskCount)
            }
            
            // Key stat
            if allPeople.count > 0 {
                let avgHealth = allPeople.reduce(0) { $0 + $1.relationshipHealthScore } / allPeople.count
                HStack {
                    Text("Average Health Score:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(avgHealth)/100")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(avgHealth >= 80 ? .green : (avgHealth >= 50 ? .yellow : .red))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func healthColor(_ status: RelationshipHealthStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .needsAttention: return .yellow
        case .atRisk: return .red
        }
    }
    
    private func healthLegendItem(status: RelationshipHealthStatus, count: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(healthColor(status))
                .frame(width: 10, height: 10)
            Text("\(count) \(status.displayName)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func healthStatCard(status: RelationshipHealthStatus, count: Int, total: Int) -> some View {
        let percentage = total > 0 ? Int(Double(count) / Double(total) * 100) : 0
        
        return VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(healthColor(status))
            
            Text("\(percentage)%")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(status.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(healthColor(status).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - At Risk Section
    
    @ViewBuilder
    private var atRiskSection: some View {
        if !atRiskPeople.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Needs Attention", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    Spacer()
                    
                    Text("\(atRiskPeople.count) relationships")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                ForEach(atRiskPeople.prefix(5)) { person in
                    atRiskPersonCard(person)
                }
                
                if atRiskPeople.count > 5 {
                    Text("+ \(atRiskPeople.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func atRiskPersonCard(_ person: Person) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(personInitials(person))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Reason for risk
                Text(riskReasons(person))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            // Action suggestion
            NavigationLink {
                PersonDetailView(person: person)
            } label: {
                Text("View")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.red, in: Capsule())
            }
        }
        .padding()
        .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func riskReasons(_ person: Person) -> String {
        var reasons: [String] = []
        
        if person.hasOverdueCommitments {
            reasons.append("Overdue commitments")
        }
        
        if let days = person.daysSinceLastInteraction, days > 30 {
            reasons.append("\(days)d since contact")
        } else if person.lastInteractionDate == nil {
            reasons.append("No recorded interactions")
        }
        
        if abs(person.commitmentBalance) > 0.6 {
            reasons.append("Commitment imbalance")
        }
        
        return reasons.isEmpty ? "Needs attention" : reasons.joined(separator: " • ")
    }
    
    // MARK: - Balance Overview
    
    private var balanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Commitment Balance", systemImage: "scale.3d")
                .font(.headline)
                .foregroundStyle(.orange)
            
            HStack(spacing: 16) {
                // Total I Owe
                VStack(alignment: .center, spacing: 4) {
                    Text("\(totalIOwe)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    Label("You Owe", systemImage: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                
                // Balance indicator
                VStack(spacing: 4) {
                    Image(systemName: overallBalance > 0 ? "arrow.right" : (overallBalance < 0 ? "arrow.left" : "equal"))
                        .font(.title2)
                        .foregroundStyle(overallBalance == 0 ? .green : .secondary)
                    
                    Text(balanceText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 60)
                
                // Total Waiting For
                VStack(alignment: .center, spacing: 4) {
                    Text("\(totalWaitingFor)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Label("Waiting", systemImage: "arrow.down.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Top imbalanced relationships
            if !imbalancedPeople.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Imbalanced Relationships")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    ForEach(imbalancedPeople.prefix(3)) { person in
                        balanceRow(person)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func balanceRow(_ person: Person) -> some View {
        HStack(spacing: 12) {
            Text(person.name)
                .font(.caption)
                .lineLimit(1)
            
            Spacer()
            
            // Balance bar
            HStack(spacing: 2) {
                // I Owe
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: CGFloat(person.iOweCount) * 10, height: 8)
                
                // Waiting For
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(person.waitingForCount) * 10, height: 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Text(person.commitmentBalance > 0 ? "They owe" : "You owe")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Interaction Insights
    
    private var interactionInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Interaction Patterns", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.cyan)
            
            // Staleness distribution
            HStack(spacing: 12) {
                interactionStatCard(
                    title: "Active",
                    subtitle: "< 7 days",
                    count: activePeople.count,
                    color: .green
                )
                
                interactionStatCard(
                    title: "Recent",
                    subtitle: "7-30 days",
                    count: recentPeople.count,
                    color: .yellow
                )
                
                interactionStatCard(
                    title: "Dormant",
                    subtitle: "> 30 days",
                    count: dormantPeople.count,
                    color: .red
                )
            }
            
            // People to reconnect with
            if !dormantPeople.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Consider reconnecting:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    ForEach(dormantPeople.prefix(3)) { person in
                        HStack {
                            Text(person.name)
                                .font(.caption)
                            Spacer()
                            if let days = person.daysSinceLastInteraction {
                                Text("\(days)d silent")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func interactionStatCard(title: String, subtitle: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Reflection Recommendations
    
    @ViewBuilder
    private var reflectionRecommendationsSection: some View {
        let needsReflection = allPeople.filter { $0.needsReflection }
        
        if !needsReflection.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Reflection Recommended", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundStyle(.pink)
                
                Text("These relationships have active commitments but no recent reflection:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach(needsReflection.prefix(5)) { person in
                    HStack {
                        Text(person.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(person.activeCommitmentCount) commitments")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        NavigationLink {
                            NewReflectionView(person: person)
                        } label: {
                            Text("Reflect")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.pink, in: Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(.pink.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.pink.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var healthyCount: Int {
        allPeople.filter { $0.healthStatus == .healthy }.count
    }
    
    private var needsAttentionCount: Int {
        allPeople.filter { $0.healthStatus == .needsAttention }.count
    }
    
    private var atRiskCount: Int {
        allPeople.filter { $0.healthStatus == .atRisk }.count
    }
    
    private var atRiskPeople: [Person] {
        allPeople.filter { $0.healthStatus == .atRisk }
            .sorted { $0.relationshipHealthScore < $1.relationshipHealthScore }
    }
    
    private var totalIOwe: Int {
        allPeople.reduce(0) { $0 + $1.iOweCount }
    }
    
    private var totalWaitingFor: Int {
        allPeople.reduce(0) { $0 + $1.waitingForCount }
    }
    
    private var overallBalance: Int {
        totalWaitingFor - totalIOwe
    }
    
    private var balanceText: String {
        if overallBalance > 0 {
            return "Others owe you more"
        } else if overallBalance < 0 {
            return "You owe more"
        }
        return "Balanced"
    }
    
    private var imbalancedPeople: [Person] {
        allPeople.filter { abs($0.commitmentBalance) > 0.5 && $0.activeCommitmentCount >= 2 }
            .sorted { abs($0.commitmentBalance) > abs($1.commitmentBalance) }
    }
    
    private var activePeople: [Person] {
        allPeople.filter { ($0.daysSinceLastInteraction ?? 100) <= 7 }
    }
    
    private var recentPeople: [Person] {
        allPeople.filter {
            let days = $0.daysSinceLastInteraction ?? 100
            return days > 7 && days <= 30
        }
    }
    
    private var dormantPeople: [Person] {
        allPeople.filter { ($0.daysSinceLastInteraction ?? 100) > 30 }
            .sorted { ($0.daysSinceLastInteraction ?? 0) > ($1.daysSinceLastInteraction ?? 0) }
    }
    
    private func personInitials(_ person: Person) -> String {
        let components = person.name.components(separatedBy: " ")
        return components.prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
    }
}

#Preview {
    NavigationStack {
        RelationshipInsightsView()
    }
    .modelContainer(for: [Person.self, Commitment.self, Entry.self], inMemory: true)
}


import SwiftUI
import SwiftData

/// A prep briefing view for preparing conversations with a specific person
struct PersonPrepView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let person: Person
    
    @State private var isLoading: Bool = true
    @State private var briefing: String = ""
    @State private var talkingPoints: [String] = []
    @State private var error: String? = nil
    @State private var dayRange: Int = 90
    @State private var isSaved: Bool = false
    @State private var showSaveToast: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Person Header
                    personHeader
                    
                    // Relationship Stats
                    relationshipStats
                    
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
                    
                    // Talking Points
                    if !talkingPoints.isEmpty && !isLoading {
                        talkingPointsSection
                    }
                    
                    // Open Commitments
                    commitmentsSection
                    
                    // Recent Interactions
                    recentInteractionsSection
                    
                    // Reflection Insights (if any)
                    reflectionInsightsSection
                }
                .padding()
            }
            .navigationTitle("Prep: \(person.name)")
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
    
    // MARK: - Person Header
    
    private var personHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(initials)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(avatarColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let role = person.role, !role.isEmpty {
                    Text(role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let org = person.organization, !org.isEmpty {
                    Text(org)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let type = person.relationshipType {
                VStack {
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundStyle(avatarColor)
                    Text(type.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Relationship Stats
    
    private var relationshipStats: some View {
        HStack(spacing: 12) {
            statCard(
                value: person.iOweCount,
                label: "I Owe",
                icon: "arrow.up.right",
                color: .orange
            )
            
            statCard(
                value: person.waitingForCount,
                label: "Waiting For",
                icon: "arrow.down.left",
                color: .blue
            )
            
            statCard(
                value: person.entryCount,
                label: "Interactions",
                icon: "doc.text",
                color: .purple
            )
            
            if let days = person.daysSinceLastInteraction {
                statCard(
                    value: days,
                    label: "Days Silent",
                    icon: "clock",
                    color: days > 30 ? .orange : .green
                )
            }
        }
    }
    
    private func statCard(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        HStack {
            Text("History range:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("", selection: $dayRange) {
                Text("30 days").tag(30)
                Text("60 days").tag(60)
                Text("90 days").tag(90)
                Text("All time").tag(365)
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
            
            Text("Preparing briefing...")
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
    
    // MARK: - Talking Points Section
    
    private var talkingPointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggested Talking Points", systemImage: "text.bubble")
                .font(.headline)
                .foregroundStyle(.cyan)
            
            ForEach(Array(talkingPoints.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.cyan))
                    
                    Text(point)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Commitments Section
    
    private var commitmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Open Commitments", systemImage: "checklist")
                .font(.headline)
            
            let commitments = person.commitments ?? []
            let iOwe = commitments.filter { $0.direction == .iOwe && $0.status.isActive }
            let waitingFor = commitments.filter { $0.direction == .waitingFor && $0.status.isActive }
            
            if iOwe.isEmpty && waitingFor.isEmpty {
                Text("No open commitments with \(person.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                // I Owe section
                if !iOwe.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("I Owe (\(iOwe.count))", systemImage: "arrow.up.right")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        
                        ForEach(iOwe) { commitment in
                            commitmentRow(commitment)
                        }
                    }
                }
                
                // Waiting For section
                if !waitingFor.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Waiting For (\(waitingFor.count))", systemImage: "arrow.down.left")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        
                        ForEach(waitingFor) { commitment in
                            commitmentRow(commitment)
                        }
                    }
                }
            }
        }
    }
    
    private func commitmentRow(_ commitment: Commitment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(commitment.title)
                    .font(.subheadline)
                    .lineLimit(2)
                
                if let project = commitment.project {
                    Text(project.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if commitment.isOverdue {
                Badge(text: "Overdue", icon: "exclamationmark.triangle.fill", color: .red)
            } else if let due = commitment.dueDate {
                Text(due, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Recent Interactions Section
    
    private var recentInteractionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Interactions", systemImage: "clock.fill")
                .font(.headline)
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
            let entries = (person.entries ?? [])
                .filter { $0.deletedAt == nil && $0.occurredAt > cutoffDate }
                .sorted { $0.occurredAt > $1.occurredAt }
                .prefix(5)
            
            if entries.isEmpty {
                Text("No interactions in the selected time range.")
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
                            .foregroundStyle(entryKindColor(entry.kind))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            HStack(spacing: 6) {
                                Text(entry.kind.displayName)
                                    .font(.caption2)
                                
                                if let project = entry.project {
                                    Text("•")
                                    Text(project.name)
                                        .font(.caption2)
                                }
                                
                                Text("•")
                                Text(entry.occurredAt, style: .date)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Reflection Insights Section
    
    @ViewBuilder
    private var reflectionInsightsSection: some View {
        let reflections = (person.reflections ?? [])
            .filter { $0.reflectionType == .relationship }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
        
        if !reflections.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Past Reflection Insights", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundStyle(.pink)
                
                ForEach(Array(reflections)) { reflection in
                    reflectionInsightCard(reflection)
                }
            }
        }
    }
    
    private func reflectionInsightCard(_ reflection: Reflection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reflection.createdAt, style: .date)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let mood = reflection.mood {
                    Text(mood.emoji)
                }
            }
            
            if let firstAnswer = reflection.questionsAnswers.first(where: { !$0.answer.isEmpty }) {
                Text(firstAnswer.answer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
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
    
    // MARK: - Toast View
    
    private var saveToastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Prep saved to \(person.name)'s timeline")
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
        // Build full content including talking points
        var fullContent = briefing
        if !talkingPoints.isEmpty {
            fullContent += "\n\n## Talking Points\n"
            for (index, point) in talkingPoints.enumerated() {
                fullContent += "\(index + 1). \(point)\n"
            }
        }
        
        // Create a prep entry for this person
        let entry = Entry(
            kind: .prep,
            title: "Prep: \(person.name)",
            occurredAt: Date(),
            rawContent: fullContent,
            aiSummary: nil,
            isDecision: false
        )
        
        // Link to person (not project) - will appear in person's activity
        entry.participants = [person]
        
        modelContext.insert(entry)
        
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
            let recentEntries = (person.entries ?? [])
                .filter { $0.deletedAt == nil && $0.occurredAt > cutoffDate }
                .sorted { $0.occurredAt > $1.occurredAt }
            
            let openCommitments = (person.commitments ?? [])
                .filter { $0.status.isActive }
            
            let relevantReflections = (person.reflections ?? [])
                .filter { $0.reflectionType == .relationship }
                .sorted { $0.createdAt > $1.createdAt }
            
            let result = try await AIService.shared.generatePersonPrepBriefing(
                person: person,
                recentEntries: recentEntries,
                openCommitments: openCommitments,
                relevantReflections: Array(relevantReflections.prefix(3))
            )
            
            await MainActor.run {
                briefing = result.briefing
                talkingPoints = result.talkingPoints
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var initials: String {
        let components = person.name.components(separatedBy: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    private var avatarColor: Color {
        switch person.relationshipType?.groupName {
        case "Internal": return .blue
        case "Investment & Advisory": return .purple
        case "External": return .green
        default: return .gray
        }
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
}

#Preview {
    let person = Person(
        name: "Sarah Chen",
        organization: "Acme Corp",
        role: "CEO",
        relationshipType: .portfolioFounder
    )
    
    return PersonPrepView(person: person)
        .modelContainer(for: [Person.self, Entry.self, Commitment.self, Project.self, Reflection.self], inMemory: true)
}


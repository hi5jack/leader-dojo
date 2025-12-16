import SwiftUI
import SwiftData

struct ReflectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var reflection: Reflection
    
    @Query private var allEntries: [Entry]
    @Query private var allCommitments: [Commitment]
    @Query(sort: \Reflection.createdAt, order: .reverse) private var allReflections: [Reflection]
    
    @State private var isEditing: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var showingNewCommitment: Bool = false
    @State private var newCommitmentTitle: String = ""
    @State private var newCommitmentDirection: CommitmentDirection = .iOwe
    @State private var commitmentSourceQuestion: String = ""
    @State private var showingAddTheme: Bool = false
    @State private var newTheme: String = ""
    @State private var isExtractingThemes: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Header
                reflectionHeader
                
                // Key Insights Summary (if complete)
                if reflection.isComplete {
                    insightsSummarySection
                }
                
                // Mood (if set)
                if let mood = reflection.mood {
                    moodSection(mood)
                }
                
                // Themes section (always show, with add option)
                themesSection
                
                // Linked entries (if any)
                if reflection.hasLinkedEntries {
                    linkedEntriesSection
                }
                
                // Stats (if available)
                if let stats = reflection.stats {
                    statsSection(stats)
                }
                
                // Questions and Answers
                questionsSection
                
                // Generated commitments
                if reflection.hasGeneratedCommitments {
                    generatedCommitmentsSection
                }
                
                // Growth Tracking (compare with past)
                if reflection.isComplete {
                    growthTrackingSection
                }
            }
            .padding()
        }
        .navigationTitle(reflection.shortTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Label(isEditing ? "Done Editing" : "Edit Answers", systemImage: "pencil")
                    }
                    
                    Button {
                        showingNewCommitment = true
                        newCommitmentTitle = ""
                        commitmentSourceQuestion = ""
                    } label: {
                        Label("Add Commitment", systemImage: "plus.circle")
                    }
                    
                    if reflection.tags.isEmpty {
                        Button {
                            extractThemesFromAnswers()
                        } label: {
                            Label("Extract Themes", systemImage: "sparkles")
                        }
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
        .alert("Delete Reflection", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(reflection)
                try? modelContext.save()
            }
        } message: {
            Text("Are you sure you want to delete this reflection?")
        }
        .alert("Add Theme", isPresented: $showingAddTheme) {
            TextField("Theme name", text: $newTheme)
            Button("Cancel", role: .cancel) { newTheme = "" }
            Button("Add") {
                if !newTheme.isEmpty {
                    reflection.addTag(newTheme)
                    try? modelContext.save()
                    newTheme = ""
                }
            }
        } message: {
            Text("Add a leadership theme for this reflection")
        }
        .sheet(isPresented: $showingNewCommitment) {
            newCommitmentSheet
        }
    }
    
    // MARK: - Insights Summary Section
    
    private var insightsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Insights", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 8) {
                // Extract key insight from answers
                if let keyInsight = extractKeyInsight() {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.caption)
                            .foregroundStyle(.orange.opacity(0.6))
                        
                        Text(keyInsight)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.primary.opacity(0.9))
                    }
                }
                
                // Theme summary
                if !reflection.tags.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                        Text("Themes:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(reflection.tags.prefix(3).map { $0.capitalized }.joined(separator: ", "))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                // Mood context
                if let mood = reflection.mood {
                    HStack(spacing: 6) {
                        Text(mood.emoji)
                            .font(.caption)
                        Text("Feeling \(mood.displayName.lowercased()) during this reflection")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func extractKeyInsight() -> String? {
        // Find the longest meaningful answer as the key insight
        let sortedAnswers = reflection.questionsAnswers
            .filter { !$0.answer.isEmpty && $0.answer.count > 20 }
            .sorted { $0.answer.count > $1.answer.count }
        
        guard let bestAnswer = sortedAnswers.first else { return nil }
        
        // Truncate if too long
        let answer = bestAnswer.answer
        if answer.count > 150 {
            let truncated = String(answer.prefix(150))
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return truncated + "..."
        }
        return answer
    }
    
    // MARK: - Header
    
    private var reflectionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type and status badges
            HStack(spacing: 8) {
                Badge(text: reflection.reflectionType.displayName, icon: reflection.reflectionType.icon, color: reflectionTypeColor)
                
                if let periodType = reflection.periodType {
                    Badge(text: periodType.displayName, icon: periodType.icon, color: periodColor)
                }
                
                if reflection.isComplete {
                    Badge(text: "Complete", icon: "checkmark.circle.fill", color: .green)
                } else {
                    Badge(text: "In Progress", icon: "circle.dashed", color: .orange)
                }
            }
            
            // Title/context
            Text(reflection.periodDisplay)
                .font(.title2)
                .fontWeight(.bold)
            
            // Period dates (for periodic reflections)
            if let periodStart = reflection.periodStart, let periodEnd = reflection.periodEnd {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("\(periodStart, style: .date) - \(periodEnd, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Project/Person context
            if let project = reflection.project {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.indigo)
                    Text(project.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let person = reflection.person {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.pink)
                    Text(person.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Created \(reflection.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Mood Section
    
    private func moodSection(_ mood: ReflectionMood) -> some View {
        HStack {
            Text(mood.emoji)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Mood")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(mood.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Linked Entries Section (Enhanced)
    
    private var linkedEntriesSection: some View {
        let linkedEntries = getLinkedEntries()
        let groupedEntries = Dictionary(grouping: linkedEntries) { $0.kind }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Events Reflected On", systemImage: "link.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text("\(linkedEntries.count) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if linkedEntries.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("No specific events linked to this reflection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Summary by type
                HStack(spacing: 12) {
                    ForEach(Array(groupedEntries.keys), id: \.self) { kind in
                        if let count = groupedEntries[kind]?.count {
                            HStack(spacing: 4) {
                                Image(systemName: kind.icon)
                                    .font(.caption2)
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(entryKindColor(kind))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(entryKindColor(kind).opacity(0.1), in: Capsule())
                        }
                    }
                }
                
                Divider()
                
                // Entry list with better context
                ForEach(linkedEntries) { entry in
                    linkedEntryRow(entry)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func linkedEntryRow(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                // Entry type icon with background
                ZStack {
                    Circle()
                        .fill(entryKindColor(entry.kind).opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: entry.kind.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(entryKindColor(entry.kind))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(entry.kind.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Text(entry.occurredAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 4) {
                    if entry.isDecision {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                    }
                    
                    if entry.project != nil {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.indigo.opacity(0.6))
                            .font(.caption2)
                    }
                }
            }
            
            // Show brief content preview if available
            if !entry.displayContent.isEmpty {
                Text(entry.displayContent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.leading, 42)
            }
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Stats Section
    
    private func statsSection(_ stats: ReflectionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Period Statistics", systemImage: "chart.bar.fill")
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
    
    // MARK: - Themes Section (Enhanced)
    
    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Leadership Themes", systemImage: "tag.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                if isExtractingThemes {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button {
                        showingAddTheme = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if reflection.tags.isEmpty {
                // Empty state with suggested themes
                VStack(alignment: .leading, spacing: 8) {
                    Text("No themes identified yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Suggested themes:")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(suggestedThemes, id: \.self) { theme in
                            Button {
                                reflection.addTag(theme)
                                try? modelContext.save()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.caption2)
                                    Text(theme.capitalized)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1), in: Capsule())
                                .foregroundStyle(.purple.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(reflection.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag.capitalized)
                                .font(.caption)
                            
                            Button {
                                reflection.removeTag(tag)
                                try? modelContext.save()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.purple.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15), in: Capsule())
                        .foregroundStyle(.purple)
                    }
                    
                    // Add more button inline
                    Button {
                        showingAddTheme = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption2)
                            Text("Add")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1), in: Capsule())
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Theme frequency context
                if let themeFrequency = getThemeFrequencyContext() {
                    Text(themeFrequency)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var suggestedThemes: [String] {
        // Suggest themes based on answer content
        let answerText = reflection.questionsAnswers.map { $0.answer.lowercased() }.joined(separator: " ")
        
        var suggestions: [String] = []
        
        let themeKeywords: [(theme: String, keywords: [String])] = [
            ("accountability", ["commit", "promise", "deliver", "own", "responsible"]),
            ("communication", ["conversation", "discuss", "talk", "listen", "share"]),
            ("decision-making", ["decide", "choice", "decision", "chose", "judgment"]),
            ("delegation", ["delegate", "assign", "hand off", "empower", "trust"]),
            ("feedback", ["feedback", "review", "input", "critique", "improve"]),
            ("conflict", ["conflict", "disagree", "tension", "difficult", "confront"]),
            ("prioritization", ["priority", "focus", "important", "urgent", "time"]),
            ("trust", ["trust", "reliable", "depend", "confidence", "faith"]),
            ("growth", ["grow", "learn", "develop", "improve", "better"])
        ]
        
        for (theme, keywords) in themeKeywords {
            if keywords.contains(where: { answerText.contains($0) }) && !reflection.tags.contains(theme) {
                suggestions.append(theme)
            }
        }
        
        // Return top 4 suggestions, or default themes if none match
        if suggestions.isEmpty {
            return Array(Reflection.leadershipThemes.filter { !reflection.tags.contains($0) }.prefix(4))
        }
        return Array(suggestions.prefix(4))
    }
    
    private func getThemeFrequencyContext() -> String? {
        guard !reflection.tags.isEmpty else { return nil }
        
        // Count how often these themes appear in other reflections
        let otherReflections = allReflections.filter { $0.id != reflection.id }
        guard !otherReflections.isEmpty else { return nil }
        
        var matchingCount = 0
        for otherReflection in otherReflections {
            if !Set(otherReflection.tags).isDisjoint(with: Set(reflection.tags)) {
                matchingCount += 1
            }
        }
        
        if matchingCount > 0 {
            let percentage = (matchingCount * 100) / otherReflections.count
            return "These themes appear in \(percentage)% of your reflections"
        }
        return nil
    }
    
    private func extractThemesFromAnswers() {
        isExtractingThemes = true
        
        // Use keyword matching as fallback (could integrate with AIService)
        let answerText = reflection.questionsAnswers.map { $0.answer.lowercased() }.joined(separator: " ")
        
        var extractedThemes: [String] = []
        
        let themeKeywords: [(theme: String, keywords: [String])] = [
            ("accountability", ["commit", "promise", "deliver", "own", "responsible", "accountable"]),
            ("communication", ["conversation", "discuss", "talk", "listen", "share", "communicate"]),
            ("decision-making", ["decide", "choice", "decision", "chose", "judgment", "call"]),
            ("delegation", ["delegate", "assign", "hand off", "empower", "let them"]),
            ("feedback", ["feedback", "review", "input", "critique", "told me"]),
            ("conflict", ["conflict", "disagree", "tension", "difficult", "confront", "avoiding"]),
            ("prioritization", ["priority", "focus", "important", "urgent", "time", "spending"]),
            ("trust", ["trust", "reliable", "depend", "confidence", "faith"]),
            ("growth", ["grow", "learn", "develop", "improve", "better", "lesson"]),
            ("influence", ["influence", "persuade", "convince", "align", "support"]),
            ("execution", ["execute", "deliver", "ship", "done", "complete", "finish"]),
            ("empathy", ["understand", "perspective", "feel", "empathy", "care"])
        ]
        
        for (theme, keywords) in themeKeywords {
            if keywords.contains(where: { answerText.contains($0) }) {
                extractedThemes.append(theme)
            }
        }
        
        // Add top 3 extracted themes
        for theme in extractedThemes.prefix(3) {
            reflection.addTag(theme)
        }
        
        try? modelContext.save()
        isExtractingThemes = false
    }
    
    // MARK: - Growth Tracking Section
    
    private var growthTrackingSection: some View {
        let previousReflections = getPreviousSimilarReflections()
        
        return Group {
            if !previousReflections.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Growth Tracking", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    // Theme evolution
                    if let themeEvolution = getThemeEvolution(previousReflections: previousReflections) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption)
                                .foregroundStyle(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Theme Evolution")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(themeEvolution)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Mood trend
                    if let moodTrend = getMoodTrend(previousReflections: previousReflections) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: moodTrend.icon)
                                .font(.caption)
                                .foregroundStyle(moodTrend.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mood Trend")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(moodTrend.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Consistency indicator
                    let consistencyMessage = getConsistencyMessage(previousReflections: previousReflections)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reflection Consistency")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(consistencyMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }
    
    private func getPreviousSimilarReflections() -> [Reflection] {
        allReflections
            .filter { $0.id != reflection.id && $0.periodType == reflection.periodType }
            .prefix(5)
            .map { $0 }
    }
    
    private func getThemeEvolution(previousReflections: [Reflection]) -> String? {
        let currentThemes = Set(reflection.tags)
        guard !currentThemes.isEmpty else { return nil }
        
        let pastThemes = Set(previousReflections.flatMap { $0.tags })
        
        let newThemes = currentThemes.subtracting(pastThemes)
        let continuingThemes = currentThemes.intersection(pastThemes)
        
        if !newThemes.isEmpty && !continuingThemes.isEmpty {
            return "New focus on \(newThemes.first!.capitalized), continuing work on \(continuingThemes.first!.capitalized)"
        } else if !newThemes.isEmpty {
            return "New area of focus: \(newThemes.joined(separator: ", "))"
        } else if !continuingThemes.isEmpty {
            return "Consistent focus on: \(continuingThemes.prefix(2).joined(separator: ", "))"
        }
        return nil
    }
    
    private func getMoodTrend(previousReflections: [Reflection]) -> (icon: String, color: Color, description: String)? {
        guard let currentMood = reflection.mood else { return nil }
        
        let previousMoods = previousReflections.compactMap { $0.mood }
        guard !previousMoods.isEmpty else { return nil }
        
        // Simple comparison with last reflection
        if let lastMood = previousMoods.first {
            let positiveOrder: [ReflectionMood] = [.drained, .uncertain, .neutral, .confident, .energized]
            let currentIndex = positiveOrder.firstIndex(of: currentMood) ?? 2
            let lastIndex = positiveOrder.firstIndex(of: lastMood) ?? 2
            
            if currentIndex > lastIndex {
                return ("arrow.up.circle.fill", .green, "Feeling more positive than last \(reflection.periodType?.displayName.lowercased() ?? "time")")
            } else if currentIndex < lastIndex {
                return ("arrow.down.circle.fill", .orange, "Energy lower than last \(reflection.periodType?.displayName.lowercased() ?? "time")")
            } else {
                return ("equal.circle.fill", .blue, "Mood consistent with recent reflections")
            }
        }
        return nil
    }
    
    private func getConsistencyMessage(previousReflections: [Reflection]) -> String {
        let totalReflections = previousReflections.count + 1
        if totalReflections >= 4 {
            return "This is your \(totalReflections)th \(reflection.periodType?.displayName.lowercased() ?? "") reflection - great consistency!"
        } else if totalReflections >= 2 {
            return "Building your reflection habit - \(totalReflections) \(reflection.periodType?.displayName.lowercased() ?? "") reflections so far"
        } else {
            return "First reflection of this type - starting your growth journey!"
        }
    }
    
    // MARK: - Questions Section
    
    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Reflections", systemImage: "brain.head.profile")
                    .font(.headline)
                
                Spacer()
                
                Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(Array(reflection.questionsAnswers.enumerated()), id: \.element.id) { index, qa in
                qaCard(qa: qa, index: index)
            }
        }
    }
    
    // MARK: - QA Card
    
    private func qaCard(qa: ReflectionQA, index: Int) -> some View {
        let answerBinding = Binding<String>(
            get: { qa.answer },
            set: { newValue in
                var updatedQA = reflection.questionsAnswers
                updatedQA[index].answer = newValue
                reflection.questionsAnswers = updatedQA
            }
        )
        
        let hasAnswer = !qa.answer.isEmpty
        let backgroundColor: Color = hasAnswer
            ? Color.purple.opacity(0.05)
            : Color.orange.opacity(0.05)
        let borderColor: Color = hasAnswer
            ? Color.purple.opacity(0.2)
            : Color.orange.opacity(0.2)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("\(index + 1).")
                    .font(.headline)
                    .foregroundStyle(.purple)
                    .frame(width: 24, alignment: .leading)
                
                Text(qa.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Add commitment from this answer
                if hasAnswer && !isEditing {
                    Button {
                        commitmentSourceQuestion = qa.question
                        newCommitmentTitle = ""
                        showingNewCommitment = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.purple.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Show linked entry context if available
            if let linkedEntryId = qa.linkedEntryId,
               let linkedEntry = allEntries.first(where: { $0.id == linkedEntryId }) {
                HStack {
                    Image(systemName: linkedEntry.kind.icon)
                        .font(.caption2)
                    Text(linkedEntry.title)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            
            if isEditing {
                TextEditor(text: answerBinding)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        Color.gray.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            } else {
                if hasAnswer {
                    MarkdownText(qa.answer)
                } else {
                    Text("No answer provided")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            backgroundColor,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Generated Commitments Section
    
    private var generatedCommitmentsSection: some View {
        let commitments = getGeneratedCommitments()
        
        return VStack(alignment: .leading, spacing: 12) {
            Label("Commitments from Reflection", systemImage: "checkmark.circle")
                .font(.headline)
                .foregroundStyle(.indigo)
            
            if commitments.isEmpty {
                Text("No commitments found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(commitments) { commitment in
                    commitmentRow(commitment)
                }
            }
        }
        .padding()
        .background(.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func commitmentRow(_ commitment: Commitment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: commitment.status == .done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(commitment.status == .done ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(commitment.title)
                    .font(.subheadline)
                    .strikethrough(commitment.status == .done)
                
                HStack {
                    Label(commitment.direction.displayName, systemImage: commitment.direction.icon)
                        .font(.caption2)
                        .foregroundStyle(commitment.direction == .iOwe ? .orange : .blue)
                    
                    if let person = commitment.person {
                        Text("• \(person.name)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - New Commitment Sheet
    
    private var newCommitmentSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you commit to?", text: $newCommitmentTitle)
                    
                    Picker("Direction", selection: $newCommitmentDirection) {
                        ForEach(CommitmentDirection.allCases, id: \.self) { direction in
                            Label(direction.displayName, systemImage: direction.icon)
                                .tag(direction)
                        }
                    }
                } header: {
                    Text("New Commitment")
                } footer: {
                    if !commitmentSourceQuestion.isEmpty {
                        Text("From reflection: \"\(commitmentSourceQuestion)\"")
                    }
                }
            }
            .navigationTitle("Add Commitment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNewCommitment = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        createCommitmentFromReflection()
                    }
                    .disabled(newCommitmentTitle.isEmpty)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
    
    // MARK: - Actions
    
    private func createCommitmentFromReflection() {
        let commitment = Commitment(
            title: newCommitmentTitle,
            direction: newCommitmentDirection
        )
        commitment.project = reflection.project
        commitment.notes = "Created from reflection: \(commitmentSourceQuestion)"
        
        modelContext.insert(commitment)
        
        // Track that this commitment came from this reflection
        reflection.addGeneratedCommitment(commitment.id)
        
        try? modelContext.save()
        showingNewCommitment = false
    }
    
    // MARK: - Helper Methods
    
    private func getLinkedEntries() -> [Entry] {
        var entries: [Entry] = []
        
        // Get source entry if quick reflection
        if let sourceEntry = reflection.sourceEntry {
            entries.append(sourceEntry)
        }
        
        // Get entries by ID
        let linkedIds = reflection.linkedEntryIds
        let linkedById = allEntries.filter { linkedIds.contains($0.id) }
        entries.append(contentsOf: linkedById)
        
        // Dedupe and sort
        let uniqueEntries = Array(Set(entries))
        return uniqueEntries.sorted { $0.occurredAt > $1.occurredAt }
    }
    
    private func getGeneratedCommitments() -> [Commitment] {
        let commitmentIds = reflection.generatedCommitmentIds
        return allCommitments.filter { commitmentIds.contains($0.id) }
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
    
    // MARK: - Computed Properties
    
    private var reflectionTypeColor: Color {
        switch reflection.reflectionType {
        case .quick: return .orange
        case .periodic: return .blue
        case .project: return .indigo
        case .relationship: return .pink
        }
    }
    
    private var periodColor: Color {
        switch reflection.periodType {
        case .week: return .blue
        case .month: return .purple
        case .quarter: return .cyan
        case .none: return .gray
        }
    }
}

#Preview {
    let reflection = Reflection(
        reflectionType: .periodic,
        periodType: .week,
        periodStart: Date(),
        periodEnd: Date(),
        mood: .confident,
        questionsAnswers: [
            ReflectionQA(question: "What was your biggest win?", answer: "Closed the deal with Company X"),
            ReflectionQA(question: "What would you do differently?", answer: "")
        ],
        tags: ["delegation", "communication"]
    )
    
    return NavigationStack {
        ReflectionDetailView(reflection: reflection)
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}

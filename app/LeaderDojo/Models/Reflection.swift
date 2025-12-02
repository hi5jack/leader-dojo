import Foundation
import SwiftData

// MARK: - Reflection Type (NEW)

/// Type of reflection - determines the scope and prompting strategy
enum ReflectionType: String, Codable, CaseIterable, Sendable {
    case quick = "quick"           // Post-event micro-reflection (30 sec - 1 min)
    case periodic = "periodic"     // Weekly/monthly/quarterly review
    case project = "project"       // Project-specific reflection
    case relationship = "relationship" // Person/relationship-focused reflection
    
    nonisolated var displayName: String {
        switch self {
        case .quick: return "Quick Reflection"
        case .periodic: return "Periodic Review"
        case .project: return "Project Reflection"
        case .relationship: return "Relationship Reflection"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .quick: return "bolt.fill"
        case .periodic: return "calendar.badge.clock"
        case .project: return "folder.fill"
        case .relationship: return "person.2.fill"
        }
    }
    
    nonisolated var estimatedTime: String {
        switch self {
        case .quick: return "30 sec"
        case .periodic: return "3-5 min"
        case .project: return "2-3 min"
        case .relationship: return "2-3 min"
        }
    }
}

// MARK: - Reflection Mood (NEW)

/// Mood/confidence captured during reflection
enum ReflectionMood: String, Codable, CaseIterable, Sendable {
    case confident = "confident"
    case uncertain = "uncertain"
    case energized = "energized"
    case drained = "drained"
    case neutral = "neutral"
    
    nonisolated var displayName: String {
        switch self {
        case .confident: return "Confident"
        case .uncertain: return "Uncertain"
        case .energized: return "Energized"
        case .drained: return "Drained"
        case .neutral: return "Neutral"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .confident: return "hand.thumbsup.fill"
        case .uncertain: return "questionmark.circle.fill"
        case .energized: return "bolt.fill"
        case .drained: return "battery.25"
        case .neutral: return "face.smiling"
        }
    }
    
    nonisolated var emoji: String {
        switch self {
        case .confident: return "💪"
        case .uncertain: return "🤔"
        case .energized: return "⚡️"
        case .drained: return "😓"
        case .neutral: return "😐"
        }
    }
}

// MARK: - Reflection Period Type

/// Reflection period type (for periodic reflections)
enum ReflectionPeriodType: String, Codable, CaseIterable, Sendable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    
    nonisolated var displayName: String {
        switch self {
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .quarter: return "Quarterly"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .quarter: return "calendar.badge.plus"
        }
    }
}

// MARK: - Reflection Q&A

/// Question and answer pair for reflections
struct ReflectionQA: Codable, Identifiable, Sendable {
    var id: UUID
    var question: String
    var answer: String
    var linkedEntryId: UUID?  // NEW: Optional link to specific entry this question is about
    
    nonisolated init(id: UUID = UUID(), question: String, answer: String = "", linkedEntryId: UUID? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.linkedEntryId = linkedEntryId
    }
}

// MARK: - Reflection Stats

/// Statistics snapshot for a reflection period
struct ReflectionStats: Codable, Sendable {
    var entriesCreated: Int
    var commitmentsCreated: Int
    var commitmentsCompleted: Int
    var iOweOpen: Int
    var waitingForOpen: Int
    var projectsActive: Int
    var meetingsHeld: Int
    var decisionsRecorded: Int
    
    // NEW: Additional context for contextual prompts
    var significantEntryIds: [UUID]?  // IDs of entries marked as significant
    var topProjectIds: [UUID]?        // Most active projects
    
    nonisolated init(
        entriesCreated: Int = 0,
        commitmentsCreated: Int = 0,
        commitmentsCompleted: Int = 0,
        iOweOpen: Int = 0,
        waitingForOpen: Int = 0,
        projectsActive: Int = 0,
        meetingsHeld: Int = 0,
        decisionsRecorded: Int = 0,
        significantEntryIds: [UUID]? = nil,
        topProjectIds: [UUID]? = nil
    ) {
        self.entriesCreated = entriesCreated
        self.commitmentsCreated = commitmentsCreated
        self.commitmentsCompleted = commitmentsCompleted
        self.iOweOpen = iOweOpen
        self.waitingForOpen = waitingForOpen
        self.projectsActive = projectsActive
        self.meetingsHeld = meetingsHeld
        self.decisionsRecorded = decisionsRecorded
        self.significantEntryIds = significantEntryIds
        self.topProjectIds = topProjectIds
    }
}

// MARK: - Reflection Model

@Model
final class Reflection {
    var id: UUID = UUID()
    
    // NEW: Reflection type determines scope and behavior
    var reflectionType: ReflectionType = ReflectionType.periodic
    
    // Periodic reflection fields
    var periodType: ReflectionPeriodType?
    var periodStart: Date?
    var periodEnd: Date?
    
    // NEW: Mood/confidence capture
    var mood: ReflectionMood?
    
    // Data storage (JSON encoded)
    var statsData: Data?                    // JSON encoded ReflectionStats
    var questionsAnswersData: Data = Data() // JSON encoded [ReflectionQA]
    var aiQuestionsData: Data?              // JSON encoded [String]
    var tagsData: Data?                     // NEW: JSON encoded [String] - leadership themes
    var linkedEntryIdsData: Data?           // NEW: JSON encoded [UUID] - entries being reflected on
    var generatedCommitmentIdsData: Data?   // NEW: JSON encoded [UUID] - commitments created from this reflection
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Relationships
    
    /// Project this reflection is about (for project-specific reflections)
    var project: Project?
    
    /// Single source entry that triggered this reflection (for quick reflections)
    var sourceEntry: Entry?
    
    /// NEW: Person this reflection is about (for relationship reflections)
    @Relationship(deleteRule: .nullify, inverse: \Person.reflections)
    var person: Person?
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        reflectionType: ReflectionType = .periodic,
        periodType: ReflectionPeriodType? = nil,
        periodStart: Date? = nil,
        periodEnd: Date? = nil,
        mood: ReflectionMood? = nil,
        questionsAnswers: [ReflectionQA] = [],
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reflectionType = reflectionType
        self.periodType = periodType
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.mood = mood
        self.questionsAnswersData = (try? JSONEncoder().encode(questionsAnswers)) ?? Data()
        self.tagsData = tags.isEmpty ? nil : (try? JSONEncoder().encode(tags))
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    /// Convenience initializer for quick reflections
    convenience init(
        quickReflectionFor entry: Entry,
        mood: ReflectionMood? = nil,
        question: String,
        answer: String = ""
    ) {
        self.init(
            reflectionType: .quick,
            mood: mood,
            questionsAnswers: [ReflectionQA(question: question, answer: answer, linkedEntryId: entry.id)]
        )
        self.sourceEntry = entry
        self.project = entry.project
        self.linkedEntryIds = [entry.id]
    }
    
    /// Convenience initializer for project reflections
    convenience init(
        projectReflection project: Project,
        questionsAnswers: [ReflectionQA] = []
    ) {
        self.init(
            reflectionType: .project,
            questionsAnswers: questionsAnswers
        )
        self.project = project
    }
    
    /// Convenience initializer for relationship reflections
    convenience init(
        relationshipReflection person: Person,
        questionsAnswers: [ReflectionQA] = []
    ) {
        self.init(
            reflectionType: .relationship,
            questionsAnswers: questionsAnswers
        )
        self.person = person
    }
    
    // MARK: - Stats (JSON encoded)
    
    var stats: ReflectionStats? {
        get {
            guard let data = statsData else { return nil }
            return try? JSONDecoder().decode(ReflectionStats.self, from: data)
        }
        set {
            statsData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }
    
    // MARK: - Questions & Answers (JSON encoded)
    
    var questionsAnswers: [ReflectionQA] {
        get {
            (try? JSONDecoder().decode([ReflectionQA].self, from: questionsAnswersData)) ?? []
        }
        set {
            questionsAnswersData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }
    
    // MARK: - AI Generated Questions (JSON encoded)
    
    var aiQuestions: [String]? {
        get {
            guard let data = aiQuestionsData else { return nil }
            return try? JSONDecoder().decode([String].self, from: data)
        }
        set {
            aiQuestionsData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }
    
    // MARK: - NEW: Tags (JSON encoded) - Leadership themes like "delegation", "feedback", "conflict"
    
    var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsData = newValue.isEmpty ? nil : (try? JSONEncoder().encode(newValue))
            updatedAt = Date()
        }
    }
    
    // MARK: - NEW: Linked Entry IDs (JSON encoded) - Entries this reflection is about
    
    var linkedEntryIds: [UUID] {
        get {
            guard let data = linkedEntryIdsData else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            linkedEntryIdsData = newValue.isEmpty ? nil : (try? JSONEncoder().encode(newValue))
            updatedAt = Date()
        }
    }
    
    // MARK: - NEW: Generated Commitment IDs (JSON encoded) - Commitments created from this reflection
    
    var generatedCommitmentIds: [UUID] {
        get {
            guard let data = generatedCommitmentIdsData else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            generatedCommitmentIdsData = newValue.isEmpty ? nil : (try? JSONEncoder().encode(newValue))
            updatedAt = Date()
        }
    }
    
    // MARK: - Display Helpers
    
    /// Period display string
    var periodDisplay: String {
        // For non-periodic reflections, show appropriate title
        switch reflectionType {
        case .quick:
            if let entry = sourceEntry {
                return "Quick: \(entry.title)"
            }
            return "Quick Reflection"
            
        case .project:
            if let project = project {
                return "Project: \(project.name)"
            }
            return "Project Reflection"
            
        case .relationship:
            if let person = person {
                return "Relationship: \(person.name)"
            }
            return "Relationship Reflection"
            
        case .periodic:
            guard let type = periodType, let start = periodStart else {
                return "General Reflection"
            }
            
            let formatter = DateFormatter()
            switch type {
            case .week:
                formatter.dateFormat = "'Week of' MMM d, yyyy"
            case .month:
                formatter.dateFormat = "MMMM yyyy"
            case .quarter:
                let quarter = Calendar.current.component(.month, from: start) / 3 + 1
                let year = Calendar.current.component(.year, from: start)
                return "Q\(quarter) \(year)"
            }
            return formatter.string(from: start)
        }
    }
    
    /// Short display title
    var shortTitle: String {
        switch reflectionType {
        case .quick:
            return sourceEntry?.title ?? "Quick Reflection"
        case .project:
            return project?.name ?? "Project"
        case .relationship:
            return person?.name ?? "Relationship"
        case .periodic:
            return periodType?.displayName ?? "Reflection"
        }
    }
    
    /// Check if all questions have been answered
    var isComplete: Bool {
        let qa = questionsAnswers
        return !qa.isEmpty && qa.allSatisfy { !$0.answer.isEmpty }
    }
    
    /// Count of answered questions
    var answeredCount: Int {
        questionsAnswers.filter { !$0.answer.isEmpty }.count
    }
    
    /// Total number of questions
    var totalQuestions: Int {
        questionsAnswers.count
    }
    
    /// Progress as a fraction (0.0 - 1.0)
    var progress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(answeredCount) / Double(totalQuestions)
    }
    
    /// Whether this reflection has linked entries
    var hasLinkedEntries: Bool {
        !linkedEntryIds.isEmpty || sourceEntry != nil
    }
    
    /// Whether this reflection generated any commitments
    var hasGeneratedCommitments: Bool {
        !generatedCommitmentIds.isEmpty
    }
    
    // MARK: - Actions
    
    /// Add a commitment ID to the generated commitments list
    func addGeneratedCommitment(_ commitmentId: UUID) {
        var ids = generatedCommitmentIds
        if !ids.contains(commitmentId) {
            ids.append(commitmentId)
            generatedCommitmentIds = ids
        }
    }
    
    /// Link an entry to this reflection
    func linkEntry(_ entryId: UUID) {
        var ids = linkedEntryIds
        if !ids.contains(entryId) {
            ids.append(entryId)
            linkedEntryIds = ids
        }
    }
    
    /// Add a tag to this reflection
    func addTag(_ tag: String) {
        let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var currentTags = tags
        if !currentTags.contains(normalizedTag) {
            currentTags.append(normalizedTag)
            tags = currentTags
        }
    }
    
    /// Remove a tag from this reflection
    func removeTag(_ tag: String) {
        let normalizedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var currentTags = tags
        currentTags.removeAll { $0 == normalizedTag }
        tags = currentTags
    }
}

// MARK: - Default Questions

extension Reflection {
    
    /// Default questions for when AI is unavailable (Guardrail: Reflection is never blocked by AI)
    static func defaultQuestions(for type: ReflectionType, periodType: ReflectionPeriodType? = nil) -> [String] {
        switch type {
        case .quick:
            return [
                "How confident are you in how this went?"
            ]
            
        case .periodic:
            switch periodType {
            case .week:
                return [
                    "What was your biggest win this week?",
                    "What commitment did you struggle to keep? Why?",
                    "Which conversation or decision would you handle differently?",
                    "What pattern do you notice in how you spent your time?",
                    "What's one thing you want to do better next week?"
                ]
            case .month:
                return [
                    "What progress did you make on your most important projects?",
                    "Which relationships received the most attention? Which were neglected?",
                    "What decisions are you most and least confident about?",
                    "What feedback have you received and how have you acted on it?",
                    "What's the most important lesson you learned this month?"
                ]
            case .quarter:
                return [
                    "Looking at your projects, what themes emerge in where you invested time?",
                    "How has your leadership style evolved this quarter?",
                    "What commitments did you consistently keep or break?",
                    "What were the three most impactful decisions you made?",
                    "What do you want to be different about next quarter?"
                ]
            case .none:
                return [
                    "What's on your mind right now?",
                    "What would you do differently if you could?"
                ]
            }
            
        case .project:
            return [
                "How am I showing up for this project?",
                "What's blocking progress that I haven't addressed?",
                "What conversation am I avoiding?",
                "What would success look like in the next 2 weeks?"
            ]
            
        case .relationship:
            return [
                "How would this person rate my reliability?",
                "What have I promised that I haven't delivered?",
                "What's one thing I could do to strengthen this relationship?",
                "What difficult conversation am I avoiding with this person?"
            ]
        }
    }
}

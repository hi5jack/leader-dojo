import Foundation
import SwiftData

/// Reflection period type
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

/// Question and answer pair for reflections
struct ReflectionQA: Codable, Identifiable, Sendable {
    var id: UUID
    var question: String
    var answer: String
    
    nonisolated init(id: UUID = UUID(), question: String, answer: String = "") {
        self.id = id
        self.question = question
        self.answer = answer
    }
}

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
    
    nonisolated init(
        entriesCreated: Int = 0,
        commitmentsCreated: Int = 0,
        commitmentsCompleted: Int = 0,
        iOweOpen: Int = 0,
        waitingForOpen: Int = 0,
        projectsActive: Int = 0,
        meetingsHeld: Int = 0,
        decisionsRecorded: Int = 0
    ) {
        self.entriesCreated = entriesCreated
        self.commitmentsCreated = commitmentsCreated
        self.commitmentsCompleted = commitmentsCompleted
        self.iOweOpen = iOweOpen
        self.waitingForOpen = waitingForOpen
        self.projectsActive = projectsActive
        self.meetingsHeld = meetingsHeld
        self.decisionsRecorded = decisionsRecorded
    }
}

@Model
final class Reflection {
    var id: UUID = UUID()
    var periodType: ReflectionPeriodType?
    var periodStart: Date?
    var periodEnd: Date?
    var statsData: Data? // JSON encoded ReflectionStats
    var questionsAnswersData: Data = Data() // JSON encoded [ReflectionQA]
    var aiQuestionsData: Data? // JSON encoded [String]
    var createdAt: Date = Date()
    
    // Relationships
    var project: Project? // Optional: reflection can be project-specific
    var sourceEntry: Entry? // Optional: linked to an entry
    
    init(
        id: UUID = UUID(),
        periodType: ReflectionPeriodType? = nil,
        periodStart: Date? = nil,
        periodEnd: Date? = nil,
        questionsAnswers: [ReflectionQA] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.periodType = periodType
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.questionsAnswersData = (try? JSONEncoder().encode(questionsAnswers)) ?? Data()
        self.createdAt = createdAt
    }
    
    // MARK: - Stats (JSON encoded)
    
    var stats: ReflectionStats? {
        get {
            guard let data = statsData else { return nil }
            return try? JSONDecoder().decode(ReflectionStats.self, from: data)
        }
        set {
            statsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Questions & Answers (JSON encoded)
    
    var questionsAnswers: [ReflectionQA] {
        get {
            (try? JSONDecoder().decode([ReflectionQA].self, from: questionsAnswersData)) ?? []
        }
        set {
            questionsAnswersData = (try? JSONEncoder().encode(newValue)) ?? Data()
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
        }
    }
    
    /// Period display string
    var periodDisplay: String {
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
    
    /// Check if all questions have been answered
    var isComplete: Bool {
        questionsAnswers.allSatisfy { !$0.answer.isEmpty }
    }
    
    /// Count of answered questions
    var answeredCount: Int {
        questionsAnswers.filter { !$0.answer.isEmpty }.count
    }
}


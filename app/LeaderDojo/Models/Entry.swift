import Foundation
import SwiftData

/// Entry types (timeline card kinds)
/// Note: Commitments are tracked separately in the Commitment model, not as entries.
enum EntryKind: String, CaseIterable, Sendable {
    case meeting = "meeting"
    case update = "update"
    case decision = "decision"
    case note = "note"
    case prep = "prep"
    case reflection = "reflection"
    
    /// Cases that should be shown in UI pickers for creating new entries.
    /// Note: .reflection is excluded because reflections should be created through
    /// the dedicated Reflection system (with structured prompts), not as freeform entries.
    static var activeCases: [EntryKind] {
        [.meeting, .update, .decision, .note, .prep]
    }
    
    nonisolated var displayName: String {
        switch self {
        case .meeting: return "Meeting"
        case .update: return "Update"
        case .decision: return "Decision"
        case .note: return "Note"
        case .prep: return "Prep"
        case .reflection: return "Reflection"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .update: return "arrow.up.circle.fill"
        case .decision: return "checkmark.seal.fill"
        case .note: return "note.text"
        case .prep: return "doc.text.fill"
        case .reflection: return "brain.head.profile"
        }
    }
    
    nonisolated var color: String {
        switch self {
        case .meeting: return "blue"
        case .update: return "green"
        case .decision: return "purple"
        case .note: return "orange"
        case .prep: return "cyan"
        case .reflection: return "pink"
        }
    }
    
    /// Whether this entry type supports AI summarization
    nonisolated var supportsAISummary: Bool {
        switch self {
        case .meeting, .update, .decision: return true
        case .note, .prep, .reflection: return false
        }
    }
}

// Custom Codable conformance so that unknown future values don't crash decoding.
extension EntryKind: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = EntryKind(rawValue: rawValue) ?? .note
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

// MARK: - Decision Stakes

/// Stakes level for a decision (low/medium/high impact)
enum DecisionStakes: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "equal.circle"
        case .high: return "arrow.up.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

extension DecisionStakes: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = DecisionStakes(rawValue: rawValue) ?? .medium
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

// MARK: - Decision Outcome

/// Outcome status for a decision after review
enum DecisionOutcome: String, CaseIterable, Sendable {
    case pending = "pending"
    case validated = "validated"
    case invalidated = "invalidated"
    case mixed = "mixed"
    case superseded = "superseded"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .validated: return "Validated"
        case .invalidated: return "Invalidated"
        case .mixed: return "Mixed"
        case .superseded: return "Superseded"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .validated: return "checkmark.circle.fill"
        case .invalidated: return "xmark.circle.fill"
        case .mixed: return "plusminus.circle.fill"
        case .superseded: return "arrow.uturn.right.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .validated: return "green"
        case .invalidated: return "red"
        case .mixed: return "yellow"
        case .superseded: return "blue"
        }
    }
}

extension DecisionOutcome: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = DecisionOutcome(rawValue: rawValue) ?? .pending
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

/// AI suggested action from entry analysis
struct SuggestedAction: Codable, Identifiable, Sendable {
    var id: UUID
    var direction: CommitmentDirection
    var title: String
    var counterparty: String?
    var isSelected: Bool
    
    nonisolated init(
        id: UUID = UUID(),
        direction: CommitmentDirection,
        title: String,
        counterparty: String? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.direction = direction
        self.title = title
        self.counterparty = counterparty
        self.isSelected = isSelected
    }
}

@Model
final class Entry {
    var id: UUID = UUID()
    var kind: EntryKind = EntryKind.note
    var title: String = ""
    var occurredAt: Date = Date()
    var rawContent: String?
    var aiSummary: String?
    var decisions: String?
    var aiSuggestedActionsData: Data? // Stored as JSON
    var isDecision: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?
    
    // MARK: - Decision Hypothesis Fields (Phase 1)
    
    /// Why are you making this decision? The rationale and reasoning.
    var decisionRationale: String?
    
    /// What must be true for this decision to work? Key assumptions.
    var decisionAssumptions: String?
    
    /// Confidence level 1-5 (1=very uncertain, 5=very confident)
    var decisionConfidence: Int?
    
    /// Stakes level: low, medium, high
    var decisionStakes: DecisionStakes?
    
    /// When should this decision be reviewed?
    var decisionReviewDate: Date?
    
    // MARK: - Decision Outcome Fields (Phase 2)
    
    /// Outcome after review: pending, validated, invalidated, mixed, superseded
    var decisionOutcome: DecisionOutcome?
    
    /// When was the outcome recorded?
    var decisionOutcomeDate: Date?
    
    /// What actually happened? Notes on the outcome.
    var decisionOutcomeNotes: String?
    
    /// Which assumptions held or broke?
    var decisionAssumptionResults: String?
    
    /// What would you do differently? Key learning.
    var decisionLearning: String?
    
    // MARK: - Relationships
    
    var project: Project?
    
    @Relationship(deleteRule: .nullify, inverse: \Commitment.sourceEntry)
    var commitments: [Commitment]?
    
    @Relationship(deleteRule: .nullify, inverse: \Reflection.sourceEntry)
    var reflections: [Reflection]?
    
    @Relationship(deleteRule: .nullify, inverse: \Person.entries)
    var participants: [Person]?
    
    init(
        id: UUID = UUID(),
        kind: EntryKind = .note,
        title: String,
        occurredAt: Date = Date(),
        rawContent: String? = nil,
        aiSummary: String? = nil,
        decisions: String? = nil,
        isDecision: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.occurredAt = occurredAt
        self.rawContent = rawContent
        self.aiSummary = aiSummary
        self.decisions = decisions
        self.isDecision = isDecision
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - AI Suggested Actions (JSON encoded)
    
    var aiSuggestedActions: [SuggestedAction]? {
        get {
            guard let data = aiSuggestedActionsData else { return nil }
            return try? JSONDecoder().decode([SuggestedAction].self, from: data)
        }
        set {
            aiSuggestedActionsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Display content - either AI summary or raw content truncated
    var displayContent: String {
        if let summary = aiSummary, !summary.isEmpty {
            return summary
        }
        if let raw = rawContent {
            return String(raw.prefix(200)) + (raw.count > 200 ? "..." : "")
        }
        return ""
    }
    
    /// Soft delete the entry
    func softDelete() {
        deletedAt = Date()
        updatedAt = Date()
    }
    
    /// Restore soft-deleted entry
    func restore() {
        deletedAt = nil
        updatedAt = Date()
    }
    
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    // MARK: - Decision Computed Properties
    
    /// Whether this entry represents a decision (either by kind or flag)
    var isDecisionEntry: Bool {
        kind == .decision || isDecision
    }
    
    /// Whether this decision needs review (review date passed and no outcome yet)
    var needsDecisionReview: Bool {
        guard isDecisionEntry else { return false }
        guard let reviewDate = decisionReviewDate else { return false }
        guard decisionOutcome == nil || decisionOutcome == .pending else { return false }
        return reviewDate <= Date()
    }
    
    /// Days until review date (negative if overdue)
    var daysUntilReview: Int? {
        guard let reviewDate = decisionReviewDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: reviewDate).day
    }
    
    /// Whether this decision has been reviewed (has an outcome other than pending)
    var hasBeenReviewed: Bool {
        guard let outcome = decisionOutcome else { return false }
        return outcome != .pending
    }
    
    /// Confidence display text
    var confidenceDisplayText: String? {
        guard let confidence = decisionConfidence else { return nil }
        switch confidence {
        case 1: return "Very Uncertain"
        case 2: return "Somewhat Uncertain"
        case 3: return "Neutral"
        case 4: return "Fairly Confident"
        case 5: return "Very Confident"
        default: return nil
        }
    }
}


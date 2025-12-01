import Foundation
import SwiftData

/// Entry types (timeline card kinds)
/// Note: Commitments are tracked separately in the Commitment model, not as entries.
/// We keep a hidden legacy case to be able to decode and clean up old data.
enum EntryKind: String, CaseIterable, Sendable {
    case meeting = "meeting"
    case update = "update"
    case decision = "decision"
    case note = "note"
    case prep = "prep"
    case reflection = "reflection"
    
    /// Legacy value used by older builds before commitments were a separate model.
    /// Kept only so we can decode and delete those entries from existing stores.
    case _legacyCommitment = "commitment"
    
    /// Cases that should be shown in UI pickers.
    static var activeCases: [EntryKind] {
        [.meeting, .update, .decision, .note, .prep, .reflection]
    }
    
    nonisolated var displayName: String {
        switch self {
        case .meeting: return "Meeting"
        case .update: return "Update"
        case .decision: return "Decision"
        case .note, ._legacyCommitment: return "Note"
        case .prep: return "Prep"
        case .reflection: return "Reflection"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .update: return "arrow.up.circle.fill"
        case .decision: return "checkmark.seal.fill"
        case .note, ._legacyCommitment: return "note.text"
        case .prep: return "doc.text.fill"
        case .reflection: return "brain.head.profile"
        }
    }
    
    nonisolated var color: String {
        switch self {
        case .meeting: return "blue"
        case .update: return "green"
        case .decision: return "purple"
        case .note, ._legacyCommitment: return "orange"
        case .prep: return "cyan"
        case .reflection: return "pink"
        }
    }
    
    /// Whether this entry type supports AI summarization
    nonisolated var supportsAISummary: Bool {
        switch self {
        case .meeting, .update: return true
        case .decision, .note, .prep, .reflection, ._legacyCommitment: return false
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
    
    // Relationships
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
}


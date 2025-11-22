import Foundation

struct Entry: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case meeting
        case update
        case decision
        case note
        case prep
        case reflection
        case self_note = "self_note"
    }

    struct SuggestedAction: Codable, Identifiable, Equatable {
        let id = UUID()
        let title: String
        let direction: Commitment.Direction
        let counterparty: String?
        let dueDate: Date?
        let importance: Int?
        let urgency: Int?
        let notes: String?

        private enum CodingKeys: String, CodingKey {
            case title
            case direction
            case counterparty
            case dueDate
            case importance
            case urgency
            case notes
        }
    }

    let id: String
    let projectId: String
    let kind: Kind
    let title: String
    let occurredAt: Date
    let rawContent: String?
    let aiSummary: String?
    let aiSuggestedActions: [SuggestedAction]?
    let isDecision: Bool
    let createdAt: Date?
    let updatedAt: Date?
}

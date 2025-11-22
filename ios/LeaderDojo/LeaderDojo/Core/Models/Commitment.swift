import Foundation

struct Commitment: Codable, Identifiable, Equatable {
    enum Direction: String, Codable {
        case i_owe = "i_owe"
        case waiting_for = "waiting_for"
    }

    enum Status: String, Codable {
        case open
        case done
        case blocked
        case dropped
    }

    let id: String
    let title: String
    let projectId: String
    let entryId: String?
    let direction: Direction
    let status: Status
    let counterparty: String?
    let dueDate: Date?
    let importance: Int?
    let urgency: Int?
    let notes: String?
    let aiGenerated: Bool?
    let createdAt: Date?
    let updatedAt: Date?
}

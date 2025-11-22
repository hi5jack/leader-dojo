import Foundation

struct Project: Codable, Identifiable, Equatable {
    enum ProjectType: String, Codable {
        case project
        case relationship
        case area
    }

    enum Status: String, Codable {
        case active
        case on_hold
        case completed
        case archived
    }

    let id: String
    let name: String
    let description: String?
    let type: ProjectType
    let status: Status
    let priority: Int
    let ownerNotes: String?
    let lastActiveAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
}

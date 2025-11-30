import Foundation
import SwiftData

/// Project types matching the web app schema
enum ProjectType: String, Codable, CaseIterable, Sendable {
    case project = "project"
    case relationship = "relationship"
    case area = "area"
    
    nonisolated var displayName: String {
        switch self {
        case .project: return "Project"
        case .relationship: return "Relationship"
        case .area: return "Area"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .project: return "folder.fill"
        case .relationship: return "person.2.fill"
        case .area: return "square.stack.3d.up.fill"
        }
    }
}

/// Project status
enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case active = "active"
    case onHold = "on_hold"
    case completed = "completed"
    case archived = "archived"
    
    nonisolated var displayName: String {
        switch self {
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .active: return "circle.fill"
        case .onHold: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }
    
    nonisolated var color: String {
        switch self {
        case .active: return "green"
        case .onHold: return "orange"
        case .completed: return "blue"
        case .archived: return "gray"
        }
    }
}

@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""
    var projectDescription: String?
    var type: ProjectType = ProjectType.project
    var status: ProjectStatus = ProjectStatus.active
    var priority: Int = 3 // 1-5, higher is more important
    var ownerNotes: String?
    var lastActiveAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Entry.project)
    var entries: [Entry]?
    
    @Relationship(deleteRule: .cascade, inverse: \Commitment.project)
    var commitments: [Commitment]?
    
    @Relationship(deleteRule: .cascade, inverse: \Reflection.project)
    var reflections: [Reflection]?
    
    init(
        id: UUID = UUID(),
        name: String,
        projectDescription: String? = nil,
        type: ProjectType = .project,
        status: ProjectStatus = .active,
        priority: Int = 3,
        ownerNotes: String? = nil,
        lastActiveAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.type = type
        self.status = status
        self.priority = priority
        self.ownerNotes = ownerNotes
        self.lastActiveAt = lastActiveAt ?? createdAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Update the last active timestamp
    func markActive() {
        lastActiveAt = Date()
        updatedAt = Date()
    }
    
    /// Days since last activity
    var daysSinceLastActive: Int? {
        guard let lastActive = lastActiveAt else { return nil }
        return Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day
    }
    
    /// Check if project needs attention (high priority + inactive for 45+ days)
    var needsAttention: Bool {
        guard priority >= 3, let days = daysSinceLastActive else { return false }
        return days >= 45
    }
    
    /// Count of open commitments where I owe
    var openIOweCount: Int {
        commitments?.filter { $0.direction == .iOwe && $0.status == .open }.count ?? 0
    }
    
    /// Count of open commitments where waiting for others
    var openWaitingForCount: Int {
        commitments?.filter { $0.direction == .waitingFor && $0.status == .open }.count ?? 0
    }
}


import Foundation
import SwiftData

/// Commitment direction - who owes whom
enum CommitmentDirection: String, Codable, CaseIterable {
    case iOwe = "i_owe"
    case waitingFor = "waiting_for"
    
    var displayName: String {
        switch self {
        case .iOwe: return "I Owe"
        case .waitingFor: return "Waiting For"
        }
    }
    
    var icon: String {
        switch self {
        case .iOwe: return "arrow.up.right.circle.fill"
        case .waitingFor: return "arrow.down.left.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .iOwe: return "orange"
        case .waitingFor: return "blue"
        }
    }
}

/// Commitment status
enum CommitmentStatus: String, Codable, CaseIterable {
    case open = "open"
    case done = "done"
    case blocked = "blocked"
    case dropped = "dropped"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .done: return "Done"
        case .blocked: return "Blocked"
        case .dropped: return "Dropped"
        }
    }
    
    var icon: String {
        switch self {
        case .open: return "circle"
        case .done: return "checkmark.circle.fill"
        case .blocked: return "xmark.circle.fill"
        case .dropped: return "minus.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .open: return "blue"
        case .done: return "green"
        case .blocked: return "red"
        case .dropped: return "gray"
        }
    }
    
    var isActive: Bool {
        self == .open || self == .blocked
    }
}

@Model
final class Commitment {
    var id: UUID = UUID()
    var title: String = ""
    var direction: CommitmentDirection = CommitmentDirection.iOwe
    var status: CommitmentStatus = CommitmentStatus.open
    var counterparty: String?
    var dueDate: Date?
    var importance: Int = 3 // 1-5
    var urgency: Int = 3 // 1-5
    var notes: String?
    var aiGenerated: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    var project: Project?
    var sourceEntry: Entry?
    
    init(
        id: UUID = UUID(),
        title: String,
        direction: CommitmentDirection = .iOwe,
        status: CommitmentStatus = .open,
        counterparty: String? = nil,
        dueDate: Date? = nil,
        importance: Int = 3,
        urgency: Int = 3,
        notes: String? = nil,
        aiGenerated: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.direction = direction
        self.status = status
        self.counterparty = counterparty
        self.dueDate = dueDate
        self.importance = importance
        self.urgency = urgency
        self.notes = notes
        self.aiGenerated = aiGenerated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Mark the commitment as done
    func markDone() {
        status = .done
        completedAt = Date()
        updatedAt = Date()
    }
    
    /// Reopen a completed commitment
    func reopen() {
        status = .open
        completedAt = nil
        updatedAt = Date()
    }
    
    /// Check if commitment is overdue
    var isOverdue: Bool {
        guard let due = dueDate, status.isActive else { return false }
        return due < Date()
    }
    
    /// Days until due (negative if overdue)
    var daysUntilDue: Int? {
        guard let due = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: due).day
    }
    
    /// Priority score for sorting (higher = more urgent/important)
    var priorityScore: Double {
        var score = Double(importance + urgency) / 2.0
        
        // Boost score if overdue
        if isOverdue {
            score += 2.0
        } else if let days = daysUntilDue, days <= 7 {
            score += 1.0 // Due within a week
        }
        
        // Factor in project priority
        if let projectPriority = project?.priority {
            score += Double(projectPriority) * 0.2
        }
        
        return score
    }
}


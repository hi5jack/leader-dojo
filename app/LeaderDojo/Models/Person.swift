import Foundation
import SwiftData

/// Relationship types for categorizing people
enum RelationshipType: String, Codable, CaseIterable, Sendable {
    // Organizational hierarchy
    case manager = "manager"
    case directReport = "direct_report"
    case skipLevel = "skip_level"
    case peer = "peer"
    case crossFunctional = "cross_functional"
    case stakeholder = "stakeholder"
    
    // Leadership/Governance
    case boardMember = "board_member"
    case executive = "executive"
    case founder = "founder"
    
    // Investment/Advisory
    case portfolioFounder = "portfolio_founder"
    case investor = "investor"
    case advisor = "advisor"
    case mentor = "mentor"
    case mentee = "mentee"
    
    // External
    case client = "client"
    case vendor = "vendor"
    case partner = "partner"
    case candidate = "candidate"
    
    case other = "other"
    
    nonisolated var displayName: String {
        switch self {
        case .manager: return "Manager"
        case .directReport: return "Direct Report"
        case .skipLevel: return "Skip Level"
        case .peer: return "Peer"
        case .crossFunctional: return "Cross-Functional"
        case .stakeholder: return "Stakeholder"
        case .boardMember: return "Board Member"
        case .executive: return "Executive"
        case .founder: return "Founder"
        case .portfolioFounder: return "Portfolio Founder"
        case .investor: return "Investor"
        case .advisor: return "Advisor"
        case .mentor: return "Mentor"
        case .mentee: return "Mentee"
        case .client: return "Client"
        case .vendor: return "Vendor"
        case .partner: return "Partner"
        case .candidate: return "Candidate"
        case .other: return "Other"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .manager: return "person.crop.rectangle"
        case .directReport: return "person.badge.minus"
        case .skipLevel: return "person.2.badge.gearshape"
        case .peer: return "person.2"
        case .crossFunctional: return "arrow.left.arrow.right"
        case .stakeholder: return "star.circle"
        case .boardMember: return "person.3.sequence"
        case .executive: return "crown"
        case .founder: return "flag"
        case .portfolioFounder: return "briefcase"
        case .investor: return "dollarsign.circle"
        case .advisor: return "lightbulb"
        case .mentor: return "graduationcap"
        case .mentee: return "book"
        case .client: return "building.2"
        case .vendor: return "shippingbox"
        case .partner: return "handshake"
        case .candidate: return "person.badge.plus"
        case .other: return "person.crop.circle.badge.questionmark"
        }
    }
    
    /// Group name for UI organization
    nonisolated var groupName: String {
        switch self {
        case .manager, .directReport, .skipLevel, .peer, .crossFunctional, .stakeholder, .executive, .founder:
            return "Internal"
        case .portfolioFounder, .investor, .advisor, .mentor, .mentee, .boardMember:
            return "Investment & Advisory"
        case .client, .vendor, .partner, .candidate:
            return "External"
        case .other:
            return "Other"
        }
    }
    
    /// Grouped relationship types for UI picker
    static var grouped: [(String, [RelationshipType])] {
        [
            ("Internal", [.manager, .directReport, .skipLevel, .peer, .crossFunctional, .stakeholder, .executive, .founder]),
            ("Investment & Advisory", [.portfolioFounder, .investor, .advisor, .mentor, .mentee, .boardMember]),
            ("External", [.client, .vendor, .partner, .candidate]),
            ("Other", [.other])
        ]
    }
}

@Model
final class Person {
    var id: UUID = UUID()
    var name: String = ""
    var organization: String?
    var role: String?
    var relationshipType: RelationshipType?
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Inverse relationships
    @Relationship(deleteRule: .nullify, inverse: \Commitment.person)
    var commitments: [Commitment]?
    
    @Relationship(deleteRule: .nullify)
    var entries: [Entry]?
    
    init(
        id: UUID = UUID(),
        name: String,
        organization: String? = nil,
        role: String? = nil,
        relationshipType: RelationshipType? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.organization = organization
        self.role = role
        self.relationshipType = relationshipType
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Display string showing name and organization
    var displayName: String {
        if let org = organization, !org.isEmpty {
            return "\(name) • \(org)"
        }
        return name
    }
    
    /// Short display showing name and role
    var shortDisplay: String {
        if let role = role, !role.isEmpty {
            return "\(name), \(role)"
        }
        return name
    }
    
    /// Full display with all info
    var fullDisplay: String {
        var parts = [name]
        if let role = role, !role.isEmpty {
            parts.append(role)
        }
        if let org = organization, !org.isEmpty {
            parts.append(org)
        }
        if let type = relationshipType {
            parts.append(type.displayName)
        }
        return parts.joined(separator: " • ")
    }
    
    /// Count of active commitments (I Owe)
    var iOweCount: Int {
        commitments?.filter { $0.direction == .iOwe && $0.status.isActive }.count ?? 0
    }
    
    /// Count of active commitments (Waiting For)
    var waitingForCount: Int {
        commitments?.filter { $0.direction == .waitingFor && $0.status.isActive }.count ?? 0
    }
    
    /// Count of total active commitments
    var activeCommitmentCount: Int {
        commitments?.filter { $0.status.isActive }.count ?? 0
    }
    
    /// Count of entries involving this person
    var entryCount: Int {
        entries?.count ?? 0
    }
    
    /// Check if there are overdue commitments
    var hasOverdueCommitments: Bool {
        commitments?.contains { $0.isOverdue } ?? false
    }
    
    /// Most recent entry date
    var lastInteractionDate: Date? {
        entries?.compactMap { $0.occurredAt }.max()
    }
    
    /// Days since last interaction
    var daysSinceLastInteraction: Int? {
        guard let lastDate = lastInteractionDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
}


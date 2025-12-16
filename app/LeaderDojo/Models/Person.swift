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
    
    /// NEW: Reflections about this person/relationship
    @Relationship(deleteRule: .nullify)
    var reflections: [Reflection]?
    
    /// Projects where this person is marked as a key stakeholder/participant
    /// Note: Inverse is declared on `Project.keyPeople` to avoid SwiftData macro circular reference.
    @Relationship(deleteRule: .nullify)
    var keyProjects: [Project]?
    
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
    
    /// Human-readable display text for last interaction (e.g., "2d ago", "1w ago")
    var lastInteractionDisplayText: String? {
        guard let days = daysSinceLastInteraction else { return nil }
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days)d ago" }
        if days < 30 { return "\(days / 7)w ago" }
        return "\(days / 30)mo ago"
    }
    
    // MARK: - Reflection Helpers (NEW)
    
    /// Count of reflections about this person
    var reflectionCount: Int {
        reflections?.count ?? 0
    }
    
    /// Most recent reflection about this relationship
    var lastReflection: Reflection? {
        reflections?.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    /// Date of last reflection about this relationship
    var lastReflectionDate: Date? {
        lastReflection?.createdAt
    }
    
    /// Days since last reflection on this relationship
    var daysSinceLastReflection: Int? {
        guard let lastDate = lastReflectionDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
    
    /// Whether this relationship needs attention (no recent reflection + active commitments)
    var needsReflection: Bool {
        let hasActiveCommitments = activeCommitmentCount > 0
        let noRecentReflection = (daysSinceLastReflection ?? 30) > 14  // More than 2 weeks
        return hasActiveCommitments && noRecentReflection
    }
    
    /// Projects this person is involved in (via entries)
    var activeProjects: [Project] {
        let projectSet = Set(entries?.compactMap { $0.project } ?? [])
        return Array(projectSet).filter { $0.status == .active }
    }
    
    // MARK: - Relationship Health (Phase 2)
    
    /// Commitment balance: ratio of I Owe to Waiting For
    /// Returns -1 to 1 where negative = you owe more, positive = they owe more
    var commitmentBalance: Double {
        let total = Double(iOweCount + waitingForCount)
        guard total > 0 else { return 0 }
        return Double(waitingForCount - iOweCount) / total
    }
    
    /// Health score: 0-100 based on interaction recency, commitment balance, overdue status
    var relationshipHealthScore: Int {
        var score = 100
        
        // Deduct for staleness (no recent interaction)
        if let days = daysSinceLastInteraction {
            if days > 30 { score -= 30 }
            else if days > 14 { score -= 15 }
            else if days > 7 { score -= 5 }
        } else {
            // No interactions at all
            score -= 20
        }
        
        // Deduct for overdue commitments
        if hasOverdueCommitments { score -= 25 }
        
        // Deduct for severe commitment imbalance (you owe too much or they owe too much)
        if abs(commitmentBalance) > 0.6 { score -= 20 }
        else if abs(commitmentBalance) > 0.3 { score -= 10 }
        
        // Bonus for having reflections (shows intentional relationship management)
        if (daysSinceLastReflection ?? 100) < 30 { score += 5 }
        
        return max(0, min(100, score))
    }
    
    /// Health status enum for UI display
    var healthStatus: RelationshipHealthStatus {
        switch relationshipHealthScore {
        case 80...100: return .healthy
        case 50..<80: return .needsAttention
        default: return .atRisk
        }
    }
}

// MARK: - Relationship Health Status

enum RelationshipHealthStatus: String, CaseIterable {
    case healthy
    case needsAttention
    case atRisk
    
    var color: String {
        switch self {
        case .healthy: return "green"
        case .needsAttention: return "yellow"
        case .atRisk: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .healthy: return "heart.fill"
        case .needsAttention: return "exclamationmark.circle.fill"
        case .atRisk: return "exclamationmark.triangle.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .healthy: return "Healthy"
        case .needsAttention: return "Needs Attention"
        case .atRisk: return "At Risk"
        }
    }
}


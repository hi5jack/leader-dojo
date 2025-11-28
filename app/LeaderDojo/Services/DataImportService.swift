import Foundation
import SwiftData

/// Service for importing data from the web app JSON export
actor DataImportService {
    static let shared = DataImportService()
    
    struct ImportResult {
        var projects: Int = 0
        var entries: Int = 0
        var commitments: Int = 0
        var reflections: Int = 0
    }
    
    /// Import data from JSON string
    func importFromJSON(_ jsonString: String, into context: ModelContext) async throws -> ImportResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw ImportError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(WebAppExport.self, from: data)
        
        var result = ImportResult()
        
        // Import projects
        var projectMap: [String: Project] = [:]
        for webProject in importData.projects ?? [] {
            let project = Project(
                id: UUID(uuidString: webProject.id) ?? UUID(),
                name: webProject.name,
                projectDescription: webProject.description,
                type: ProjectType(rawValue: webProject.type ?? "project") ?? .project,
                status: ProjectStatus(rawValue: webProject.status ?? "active") ?? .active,
                priority: webProject.priority ?? 3,
                ownerNotes: webProject.ownerNotes,
                lastActiveAt: webProject.lastActiveAt,
                createdAt: webProject.createdAt ?? Date(),
                updatedAt: webProject.updatedAt ?? Date()
            )
            context.insert(project)
            projectMap[webProject.id] = project
            result.projects += 1
        }
        
        // Import entries
        var entryMap: [String: Entry] = [:]
        for webEntry in importData.entries ?? [] {
            let entry = Entry(
                id: UUID(uuidString: webEntry.id) ?? UUID(),
                kind: EntryKind(rawValue: webEntry.kind ?? "note") ?? .note,
                title: webEntry.title,
                occurredAt: webEntry.occurredAt ?? Date(),
                rawContent: webEntry.rawContent,
                aiSummary: webEntry.aiSummary,
                decisions: webEntry.decisions,
                isDecision: webEntry.isDecision ?? false,
                createdAt: webEntry.createdAt ?? Date(),
                updatedAt: webEntry.updatedAt ?? Date()
            )
            
            if let projectId = webEntry.projectId, let project = projectMap[projectId] {
                entry.project = project
            }
            
            context.insert(entry)
            entryMap[webEntry.id] = entry
            result.entries += 1
        }
        
        // Import commitments
        for webCommitment in importData.commitments ?? [] {
            let commitment = Commitment(
                id: UUID(uuidString: webCommitment.id) ?? UUID(),
                title: webCommitment.title,
                direction: CommitmentDirection(rawValue: webCommitment.direction ?? "i_owe") ?? .iOwe,
                status: CommitmentStatus(rawValue: webCommitment.status ?? "open") ?? .open,
                counterparty: webCommitment.counterparty,
                dueDate: webCommitment.dueDate,
                importance: webCommitment.importance ?? 3,
                urgency: webCommitment.urgency ?? 3,
                notes: webCommitment.notes,
                aiGenerated: webCommitment.aiGenerated ?? false,
                createdAt: webCommitment.createdAt ?? Date(),
                updatedAt: webCommitment.updatedAt ?? Date()
            )
            
            if let projectId = webCommitment.projectId, let project = projectMap[projectId] {
                commitment.project = project
            }
            
            if let entryId = webCommitment.entryId, let entry = entryMap[entryId] {
                commitment.sourceEntry = entry
            }
            
            context.insert(commitment)
            result.commitments += 1
        }
        
        // Import reflections
        for webReflection in importData.reflections ?? [] {
            let qa = webReflection.questionsAnswers?.map { qa in
                ReflectionQA(
                    id: UUID(),
                    question: qa.question,
                    answer: qa.answer
                )
            } ?? []
            
            let reflection = Reflection(
                id: UUID(uuidString: webReflection.id) ?? UUID(),
                periodType: webReflection.periodType.flatMap { ReflectionPeriodType(rawValue: $0) },
                periodStart: webReflection.periodStart,
                periodEnd: webReflection.periodEnd,
                questionsAnswers: qa,
                createdAt: webReflection.createdAt ?? Date()
            )
            
            if let projectId = webReflection.projectId, let project = projectMap[projectId] {
                reflection.project = project
            }
            
            context.insert(reflection)
            result.reflections += 1
        }
        
        try context.save()
        
        return result
    }
}

// MARK: - Web App Export Types

struct WebAppExport: Codable {
    var projects: [WebProject]?
    var entries: [WebEntry]?
    var commitments: [WebCommitment]?
    var reflections: [WebReflection]?
}

struct WebProject: Codable {
    var id: String
    var name: String
    var description: String?
    var type: String?
    var status: String?
    var priority: Int?
    var ownerNotes: String?
    var lastActiveAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
}

struct WebEntry: Codable {
    var id: String
    var projectId: String?
    var kind: String?
    var title: String
    var occurredAt: Date?
    var rawContent: String?
    var aiSummary: String?
    var decisions: String?
    var isDecision: Bool?
    var createdAt: Date?
    var updatedAt: Date?
}

struct WebCommitment: Codable {
    var id: String
    var projectId: String?
    var entryId: String?
    var title: String
    var direction: String?
    var status: String?
    var counterparty: String?
    var dueDate: Date?
    var importance: Int?
    var urgency: Int?
    var notes: String?
    var aiGenerated: Bool?
    var createdAt: Date?
    var updatedAt: Date?
}

struct WebReflection: Codable {
    var id: String
    var projectId: String?
    var periodType: String?
    var periodStart: Date?
    var periodEnd: Date?
    var questionsAnswers: [WebQA]?
    var createdAt: Date?
}

struct WebQA: Codable {
    var question: String
    var answer: String
}

// MARK: - Errors

enum ImportError: LocalizedError {
    case invalidJSON
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON format"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}




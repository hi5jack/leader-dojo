import Foundation

struct CreateProjectInput: Encodable {
    let name: String
    let description: String?
    let type: Project.ProjectType
    let status: Project.Status
    let priority: Int
    let ownerNotes: String?

    init(name: String,
         description: String? = nil,
         type: Project.ProjectType = .project,
         status: Project.Status = .active,
         priority: Int = 3,
         ownerNotes: String? = nil) {
        self.name = name
        self.description = description
        self.type = type
        self.status = status
        self.priority = priority
        self.ownerNotes = ownerNotes
    }
}

struct UpdateProjectInput: Encodable {
    let name: String?
    let description: String?
    let type: Project.ProjectType?
    let status: Project.Status?
    let priority: Int?
    let ownerNotes: String?
}

struct CreateEntryInput: Encodable {
    let kind: Entry.Kind
    let title: String
    let occurredAt: Date
    let rawContent: String?
}

struct ProjectsService {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listProjects() async throws -> [Project] {
        try await apiClient.request(.projects(), responseType: [Project].self)
    }

    func fetchProject(id: String) async throws -> Project {
        try await apiClient.request(.project(id: id), responseType: Project.self)
    }

    func createProject(input: CreateProjectInput) async throws -> Project {
        try await apiClient.request(.createProject(payload: AnyEncodable(input)), responseType: Project.self)
    }

    func updateProject(id: String, input: UpdateProjectInput) async throws -> Project {
        try await apiClient.request(.updateProject(id: id, payload: AnyEncodable(input)), responseType: Project.self)
    }

    func listEntries(projectId: String) async throws -> [Entry] {
        try await apiClient.request(.projectEntries(id: projectId), responseType: [Entry].self)
    }

    func createEntry(projectId: String, input: CreateEntryInput) async throws -> Entry {
        try await apiClient.request(.createEntry(projectId: projectId, payload: AnyEncodable(input)), responseType: Entry.self)
    }
}

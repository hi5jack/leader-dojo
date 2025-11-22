import Foundation

struct SummarizeEntryResponse: Decodable {
    let summary: String
    let suggestedActions: [Entry.SuggestedAction]
}

struct EntrySuggestionInput: Encodable {
    let projectId: String
    let actions: [Action]

    struct Action: Encodable {
        let title: String
        let direction: Commitment.Direction
        let counterparty: String?
        let dueDate: Date?
        let importance: Int?
        let urgency: Int?
        let notes: String?
    }
}

struct EntriesService {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listEntries(projectId: String) async throws -> [Entry] {
        try await apiClient.request(.projectEntries(id: projectId), responseType: [Entry].self)
    }

    func createEntry(projectId: String, input: CreateEntryInput) async throws -> Entry {
        try await apiClient.request(.createEntry(projectId: projectId, payload: AnyEncodable(input)), responseType: Entry.self)
    }

    func summarizeEntry(entryId: String) async throws -> SummarizeEntryResponse {
        try await apiClient.request(.summarizeEntry(entryId: entryId), responseType: SummarizeEntryResponse.self)
    }

    func createCommitmentsFromSuggestions(entryId: String, payload: EntrySuggestionInput) async throws -> [Commitment] {
        try await apiClient.request(.createCommitments(entryId: entryId, payload: AnyEncodable(payload)), responseType: [Commitment].self)
    }
}

import Foundation

struct CommitmentFilters {
    var direction: Commitment.Direction?
    var status: Commitment.Status?
    var projectId: String?
}

struct CreateCommitmentInput: Encodable {
    let title: String
    let projectId: String
    let direction: Commitment.Direction
    let counterparty: String?
    let dueDate: Date?
    let importance: Int
    let urgency: Int
    let notes: String?
}

struct UpdateCommitmentInput: Encodable {
    let status: Commitment.Status?
    let counterparty: String?
    let dueDate: Date?
    let importance: Int?
    let urgency: Int?
    let notes: String?
}

struct CommitmentsService {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listCommitments(filters: CommitmentFilters = CommitmentFilters()) async throws -> [Commitment] {
        let endpoint = APIEndpoint.commitments(
            direction: filters.direction?.rawValue,
            status: filters.status?.rawValue,
            projectId: filters.projectId
        )
        return try await apiClient.request(endpoint, responseType: [Commitment].self)
    }

    func createCommitment(input: CreateCommitmentInput) async throws -> Commitment {
        try await apiClient.request(.createCommitment(payload: AnyEncodable(input)), responseType: Commitment.self)
    }

    func updateCommitment(id: String, input: UpdateCommitmentInput) async throws -> Commitment {
        try await apiClient.request(.updateCommitment(id: id, payload: AnyEncodable(input)), responseType: Commitment.self)
    }
}

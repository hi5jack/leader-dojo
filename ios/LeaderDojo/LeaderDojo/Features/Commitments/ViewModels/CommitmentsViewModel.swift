import Foundation

@MainActor
final class CommitmentsViewModel: ObservableObject {
    @Published var iOwe: [Commitment] = []
    @Published var waitingFor: [Commitment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var service: CommitmentsService?

    func configure(service: CommitmentsService) {
        self.service = service
    }

    func load() async {
        guard let service, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let mine = try await service.listCommitments(filters: CommitmentFilters(direction: .i_owe, status: .open, projectId: nil))
            let theirs = try await service.listCommitments(filters: CommitmentFilters(direction: .waiting_for, status: .open, projectId: nil))
            iOwe = mine
            waitingFor = theirs
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(commitment: Commitment, input: UpdateCommitmentInput) async {
        guard let service else { return }
        do {
            let updated = try await service.updateCommitment(id: commitment.id, input: input)
            if updated.direction == .i_owe {
                iOwe = iOwe.map { $0.id == updated.id ? updated : $0 }
            } else {
                waitingFor = waitingFor.map { $0.id == updated.id ? updated : $0 }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

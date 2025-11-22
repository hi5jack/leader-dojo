import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(DashboardData)
        case failed(String)
    }

    @Published var state: State = .idle
    private var service: DashboardService?

    func configure(service: DashboardService) {
        self.service = service
    }

    func load() async {
        guard let service else { return }
        state = .loading
        do {
            let data = try await service.fetchDashboard()
            state = .loaded(data)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

import Foundation

struct DashboardService {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchDashboard() async throws -> DashboardData {
        try await apiClient.request(.dashboard(), responseType: DashboardData.self)
    }
}

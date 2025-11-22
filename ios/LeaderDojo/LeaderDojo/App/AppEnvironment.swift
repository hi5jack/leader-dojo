import Foundation
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    enum MainTab: Hashable {
        case dashboard
        case projects
        case commitments
        case reflections
        case capture
    }

    @Published var isAuthenticated: Bool
    @Published var activeTab: MainTab = .dashboard
    @Published var currentUser: User?

    let apiClient: APIClient
    let authService: AuthService
    let dashboardService: DashboardService
    let projectsService: ProjectsService
    let commitmentsService: CommitmentsService
    let reflectionsService: ReflectionsService
    let entriesService: EntriesService

    init() {
        let apiClient = APIClient()
        self.apiClient = apiClient
        self.authService = AuthService(apiClient: apiClient)
        self.dashboardService = DashboardService(apiClient: apiClient)
        self.projectsService = ProjectsService(apiClient: apiClient)
        self.commitmentsService = CommitmentsService(apiClient: apiClient)
        self.reflectionsService = ReflectionsService(apiClient: apiClient)
        self.entriesService = EntriesService(apiClient: apiClient)
        self.isAuthenticated = authService.isAuthenticated
        self.currentUser = authService.currentUser
    }

    func bootstrap() async {
        if authService.isAuthenticated {
            refreshUser()
        }
    }

    func refreshUser() {
        do {
            let profile = try authService.getStoredUser()
            currentUser = profile
            isAuthenticated = authService.isAuthenticated
        } catch {
            handleLogout()
        }
    }

    func handleLogout() {
        authService.logout()
        currentUser = nil
        isAuthenticated = false
    }
}

import Foundation

@MainActor
final class ProjectsListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var service: ProjectsService?

    func configure(service: ProjectsService) {
        self.service = service
    }

    func load() async {
        guard let service else { return }
        isLoading = true
        do {
            projects = try await service.listProjects()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createProject(input: CreateProjectInput) async throws {
        guard let service else { return }
        _ = try await service.createProject(input: input)
        await load()
    }
}

import Foundation

@MainActor
final class ProjectDetailViewModel: ObservableObject {
    @Published var project: Project?
    @Published var entries: [Entry] = []
    @Published var commitments: [Commitment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var projectId: String?
    private var projectsService: ProjectsService?
    private var entriesService: EntriesService?
    private var commitmentsService: CommitmentsService?

    func configure(projectsService: ProjectsService,
                   entriesService: EntriesService,
                   commitmentsService: CommitmentsService) {
        self.projectsService = projectsService
        self.entriesService = entriesService
        self.commitmentsService = commitmentsService
    }

    func load(projectId: String) async {
        guard projectsService != nil else { return }
        self.projectId = projectId
        isLoading = true
        defer { isLoading = false }
        await fetchProject()
        await fetchEntries()
        await fetchCommitments()
    }

    func fetchProject() async {
        guard let projectId, let projectsService else { return }
        do {
            project = try await projectsService.fetchProject(id: projectId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchEntries() async {
        guard let projectId, let entriesService else { return }
        do {
            entries = try await entriesService.listEntries(projectId: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchCommitments() async {
        guard let projectId, let commitmentsService else { return }
        do {
            commitments = try await commitmentsService.listCommitments(
                filters: CommitmentFilters(direction: nil, status: .open, projectId: projectId)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

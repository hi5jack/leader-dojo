import Foundation

@MainActor
final class CaptureViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProjectId: String?
    @Published var newProjectName: String = ""
    @Published var note: String = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    private var projectsService: ProjectsService?

    func configure(service: ProjectsService) {
        self.projectsService = service
    }

    func loadProjects() async {
        guard let service = projectsService else { return }
        do {
            projects = try await service.listProjects()
            if selectedProjectId == nil {
                selectedProjectId = projects.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveNote() async throws {
        guard let service = projectsService else { return }
        isSaving = true
        defer { isSaving = false }

        var projectId: String
        if let selectedProjectId, !selectedProjectId.isEmpty, newProjectName.isEmpty {
            projectId = selectedProjectId
        } else {
            let created = try await service.createProject(input: CreateProjectInput(name: newProjectName.isEmpty ? "Untitled" : newProjectName, description: nil, type: .project, status: .active, priority: 3, ownerNotes: nil))
            projects.append(created)
            projectId = created.id
            selectedProjectId = created.id
            newProjectName = ""
        }

        let entryInput = CreateEntryInput(kind: .self_note, title: "Quick capture", occurredAt: Date(), rawContent: note)
        _ = try await service.createEntry(projectId: projectId, input: entryInput)
        note = ""
        Haptics.success()
    }
}

import Foundation

@MainActor
final class ReflectionsViewModel: ObservableObject {
    @Published var reflections: [Reflection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var service: ReflectionsService?

    func configure(service: ReflectionsService) {
        self.service = service
    }

    func load() async {
        guard let service else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            reflections = try await service.listReflections()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

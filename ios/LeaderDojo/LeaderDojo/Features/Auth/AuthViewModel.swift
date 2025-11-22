import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private weak var appEnvironment: AppEnvironment?

    func bind(environment: AppEnvironment) {
        self.appEnvironment = environment
    }

    func signIn() async {
        guard let environment = appEnvironment else {
            errorMessage = "Missing environment"
            return
        }

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        errorMessage = nil
        isLoading = true

        do {
            try await environment.authService.login(email: email, password: password)
            environment.refreshUser()
            environment.isAuthenticated = true
            isLoading = false
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            Haptics.error()
        }
    }
}

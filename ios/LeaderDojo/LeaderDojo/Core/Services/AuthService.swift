import Foundation

struct MobileLoginResponse: Decodable {
    let token: String
    let user: User
}

final class AuthService {
    private let apiClient: APIClient
    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool = false
    private let userEncoder = JSONEncoder()
    private let userDecoder = JSONDecoder()

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        if let tokenData = KeychainManager.read(for: .token),
           let token = String(data: tokenData, encoding: .utf8) {
            apiClient.updateToken(token)
            isAuthenticated = true
        }
        if let userData = KeychainManager.read(for: .user),
           let storedUser = try? userDecoder.decode(User.self, from: userData) {
            currentUser = storedUser
        }
    }

    func login(email: String, password: String) async throws {
        let response: MobileLoginResponse = try await apiClient.request(
            .mobileLogin(email: email.lowercased(), password: password),
            responseType: MobileLoginResponse.self
        )

        KeychainManager.save(Data(response.token.utf8), for: .token)
        let encodedUser = try userEncoder.encode(response.user)
        KeychainManager.save(encodedUser, for: .user)
        currentUser = response.user
        isAuthenticated = true
        apiClient.updateToken(response.token)
    }

    func logout() {
        KeychainManager.delete(key: .token)
        KeychainManager.delete(key: .user)
        currentUser = nil
        isAuthenticated = false
        apiClient.updateToken(nil)
    }

    func getStoredUser() throws -> User {
        if let currentUser {
            return currentUser
        }
        guard
            let data = KeychainManager.read(for: .user),
            let user = try? userDecoder.decode(User.self, from: data)
        else {
            throw APIClient.APIError.unauthorized
        }
        currentUser = user
        return user
    }
}

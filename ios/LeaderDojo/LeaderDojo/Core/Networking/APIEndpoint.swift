import Foundation

struct APIEndpoint {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
    }

    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let body: AnyEncodable?
    let headers: [String: String]

    init(path: String,
         method: HTTPMethod = .get,
         queryItems: [URLQueryItem] = [],
         body: AnyEncodable? = nil,
         headers: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }
}

extension APIEndpoint {
    static func mobileLogin(email: String, password: String) -> APIEndpoint {
        struct Payload: Encodable {
            let email: String
            let password: String
        }
        return APIEndpoint(
            path: "/api/auth/mobile/login",
            method: .post,
            body: AnyEncodable(Payload(email: email, password: password))
        )
    }

    static func dashboard() -> APIEndpoint {
        APIEndpoint(path: "/api/secure/dashboard")
    }

    static func projects() -> APIEndpoint {
        APIEndpoint(path: "/api/secure/projects")
    }

    static func project(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/projects/\(id)")
    }

    static func createProject(payload: AnyEncodable) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/projects", method: .post, body: payload)
    }

    static func updateProject(id: String, payload: AnyEncodable) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/projects/\(id)", method: .patch, body: payload)
    }

    static func projectEntries(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/projects/\(id)/entries")
    }

    static func createEntry(projectId: String, payload: AnyEncodable) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/projects/\(projectId)/entries", method: .post, body: payload)
    }

    static func summarizeEntry(entryId: String) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/entries/\(entryId)/summarize", method: .post)
    }

    static func createCommitments(entryId: String, payload: AnyEncodable) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/entries/\(entryId)/commitments", method: .post, body: payload)
    }

    static func commitments(direction: String?, status: String?, projectId: String?) -> APIEndpoint {
        var items: [URLQueryItem] = []
        if let direction {
            items.append(URLQueryItem(name: "direction", value: direction))
        }
        if let status {
            items.append(URLQueryItem(name: "status", value: status))
        }
        if let projectId {
            items.append(URLQueryItem(name: "projectId", value: projectId))
        }
        return APIEndpoint(path: "/api/secure/commitments", queryItems: items)
    }

    static func createCommitment(payload: AnyEncodable) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/commitments", method: .post, body: payload)
    }

    static func updateCommitment(id: String, payload: AnyEncodable) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/commitments/\(id)", method: .patch, body: payload)
    }

    static func listReflections() -> APIEndpoint {
        APIEndpoint(path: "/api/secure/reflections")
    }

    static func createReflection(payload: AnyEncodable) -> APIEndpoint {
        APIEndpoint(path: "/api/secure/reflections", method: .post, body: payload)
    }
}

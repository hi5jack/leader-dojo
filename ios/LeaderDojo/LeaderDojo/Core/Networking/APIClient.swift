import Foundation

struct EmptyResponse: Decodable {}

final class APIClient {
    enum APIError: Error, LocalizedError {
        case invalidURL
        case requestFailed(Int)
        case decodingFailed
        case unauthorized

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case let .requestFailed(code):
                return "Request failed with status code \(code)"
            case .decodingFailed:
                return "Failed to decode response"
            case .unauthorized:
                return "Session expired. Please sign in again."
            }
        }
    }

    private let urlSession: URLSession
    private(set) var token: String?
    private let baseURL: URL
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    init(baseURL: URL = URL(string: "https://leader-dojo.vercel.app")!,
         urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.jsonDecoder = JSONDecoder()
        self.jsonEncoder = JSONEncoder()
        jsonDecoder.dateDecodingStrategy = .iso8601withFractionalSeconds
        jsonEncoder.dateEncodingStrategy = .iso8601withFractionalSeconds
    }

    func updateToken(_ token: String?) {
        self.token = token
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint,
                               responseType: T.Type = T.self) async throws -> T {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        var basePath = baseURL.path
        if basePath.hasSuffix("/") { basePath.removeLast() }
        var endpointPath = endpoint.path
        if !endpointPath.hasPrefix("/") {
            endpointPath = "/" + endpointPath
        }
        components.path = basePath + endpointPath
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.httpBody = try jsonEncoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            print("APIClient request failed:", url)
            print("Error:", error)
            throw error
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(-1)
        }

        switch httpResponse.statusCode {
        case 200 ..< 300:
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            if data.isEmpty {
                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
            }
            do {
                return try jsonDecoder.decode(T.self, from: data)
            } catch {
                print("APIClient decoding failed for", url)
                if let raw = String(data: data, encoding: .utf8) {
                    print("Body:", raw)
                }
                print("Decoding error:", error)
                throw APIError.decodingFailed
            }
        case 401:
            print("APIClient unauthorized response:", httpResponse.statusCode)
            if let body = String(data: data, encoding: .utf8) {
                print("Body:", body)
            }
            throw APIError.unauthorized
        default:
            print("APIClient non-success response:", httpResponse.statusCode)
            if let body = String(data: data, encoding: .utf8) {
                print("Body:", body)
            }
            throw APIError.requestFailed(httpResponse.statusCode)
        }
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    static var iso8601withFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let fallback = formatter.date(from: value) {
                return fallback
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date \(value)")
        }
    }
}

private extension JSONEncoder.DateEncodingStrategy {
    static var iso8601withFractionalSeconds: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: date))
        }
    }
}

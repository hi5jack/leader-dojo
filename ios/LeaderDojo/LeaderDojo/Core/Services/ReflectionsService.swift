import Foundation

struct ReflectionPromptResponse: Decodable {
    let stats: [String: Int]
    let questions: [String]
    let suggestions: [String]
}

struct ReflectionAnswerInput: Encodable {
    let question: String
    let answer: String
}

struct ReflectionRequestInput: Encodable {
    let periodType: Reflection.PeriodType
    let periodStart: Date
    let periodEnd: Date
    let answers: [ReflectionAnswerInput]?
}

struct ReflectionsService {
    let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listReflections() async throws -> [Reflection] {
        try await apiClient.request(.listReflections(), responseType: [Reflection].self)
    }

    func generateReflection(periodType: Reflection.PeriodType,
                            periodStart: Date,
                            periodEnd: Date) async throws -> ReflectionPromptResponse {
        let payload = ReflectionRequestInput(periodType: periodType,
                                             periodStart: periodStart,
                                             periodEnd: periodEnd,
                                             answers: nil)
        return try await apiClient.request(.createReflection(payload: AnyEncodable(payload)), responseType: ReflectionPromptResponse.self)
    }

    func saveReflection(payload: ReflectionRequestInput) async throws -> ReflectionPromptResponse {
        try await apiClient.request(.createReflection(payload: AnyEncodable(payload)), responseType: ReflectionPromptResponse.self)
    }
}

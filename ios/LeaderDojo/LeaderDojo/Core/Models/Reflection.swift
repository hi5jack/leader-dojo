import Foundation

struct Reflection: Codable, Identifiable, Equatable {
    enum PeriodType: String, Codable {
        case week
        case month
        case quarter
    }

    struct QA: Codable, Identifiable, Equatable {
        var id = UUID()
        let question: String
        let answer: String
    }

    let id: String
    let periodType: PeriodType
    let periodStart: Date
    let periodEnd: Date
    let stats: [String: Int]
    let questionsAndAnswers: [QA]
    let aiQuestions: [String]
    let createdAt: Date
}

import Foundation

struct DashboardData: Codable, Equatable {
    struct Pending: Codable, Equatable {
        let decisionsNeedingReview: Int
        let pendingReflections: Int
    }

    let weeklyFocus: [Commitment]
    let idleProjects: [Project]
    let pending: Pending
}

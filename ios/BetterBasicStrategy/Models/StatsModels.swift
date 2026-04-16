import Foundation

struct OutcomeCounts: Codable {
    var wins: Int = 0
    var losses: Int = 0
    var pushes: Int = 0
    var blackjacks: Int = 0
    var surrenders: Int = 0
}

struct AccuracyByHandType: Codable, Identifiable {
    var id: String { label }
    let label: String
    let accuracy: Double
    let total: Int
}

struct AccuracyByDealerUpcard: Codable, Identifiable {
    var id: String { rank }
    let rank: String
    let accuracy: Double
    let total: Int
}

struct TopMistake: Codable, Identifiable {
    var id: String { label }
    let label: String
    let count: Int
    let correctAction: String
}

struct GameSession: Codable, Identifiable {
    let id: String
    let userId: String
    let startedAt: String
    let endedAt: String?
    let handsPlayed: Int
    let correctDecisions: Int
    let incorrectDecisions: Int

    var accuracy: Double {
        let total = correctDecisions + incorrectDecisions
        return total > 0 ? Double(correctDecisions) / Double(total) * 100 : 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case handsPlayed = "hands_played"
        case correctDecisions = "correct_decisions"
        case incorrectDecisions = "incorrect_decisions"
    }
}

struct StatsData: Codable {
    var lifetimeHands: Int = 0
    var lifetimeDecisions: Int = 0
    var lifetimeAccuracy: Double = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var shoesPlayed: Int = 0
    var outcomeCounts: OutcomeCounts = OutcomeCounts()
    var accuracyByHandType: [AccuracyByHandType] = []
    var accuracyByDealerUpcard: [AccuracyByDealerUpcard] = []
    var topMistakes: [TopMistake] = []
    var recentSessions: [GameSession] = []
}

struct BBSUser: Codable, Identifiable {
    let id: String
    let username: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, username
        case createdAt = "created_at"
    }
}

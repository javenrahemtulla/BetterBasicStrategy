import Foundation
import SwiftData

@Model
final class GameSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var rulesSnapshot: Data          // JSON-encoded RuleSet
    var handsPlayed: Int
    var correctDecisions: Int
    var incorrectDecisions: Int
    var spotsPlayed: Int

    @Relationship(deleteRule: .cascade)
    var handRecords: [HandRecord] = []

    var accuracyPercent: Double {
        let total = correctDecisions + incorrectDecisions
        guard total > 0 else { return 0 }
        return Double(correctDecisions) / Double(total) * 100
    }

    init(rules: RuleSet) {
        self.id = UUID()
        self.startedAt = Date()
        self.rulesSnapshot = (try? JSONEncoder().encode(rules)) ?? Data()
        self.handsPlayed = 0
        self.correctDecisions = 0
        self.incorrectDecisions = 0
        self.spotsPlayed = 0
    }
}

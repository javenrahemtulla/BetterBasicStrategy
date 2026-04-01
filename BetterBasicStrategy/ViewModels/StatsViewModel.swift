import Foundation
import SwiftData
import Observation

struct AccuracyByCategory: Identifiable {
    let id = UUID()
    let label: String
    let accuracy: Double
    let total: Int
}

struct MistakeEntry: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let correctAction: String
}

struct DealerHeatCell: Identifiable {
    let id = UUID()
    let dealerRank: String
    let accuracy: Double
    let sampleSize: Int
}

@Observable
final class StatsViewModel {
    private var modelContext: ModelContext?

    private(set) var lifetimeHands: Int = 0
    private(set) var lifetimeDecisions: Int = 0
    private(set) var lifetimeAccuracy: Double = 0
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var accuracyByHandType: [AccuracyByCategory] = []
    private(set) var accuracyByDealerUpcard: [DealerHeatCell] = []
    private(set) var topMistakes: [MistakeEntry] = []
    private(set) var recentSessions: [GameSession] = []

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refresh()
    }

    func refresh() {
        guard let context = modelContext else { return }

        let sessions = (try? context.fetch(FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        ))) ?? []

        let records = (try? context.fetch(FetchDescriptor<HandRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .ascending)]
        ))) ?? []

        recentSessions = Array(sessions.prefix(20))

        // Lifetime totals
        lifetimeHands = sessions.reduce(0) { $0 + $1.handsPlayed }
        let totalCorrect = sessions.reduce(0) { $0 + $1.correctDecisions }
        let totalIncorrect = sessions.reduce(0) { $0 + $1.incorrectDecisions }
        lifetimeDecisions = totalCorrect + totalIncorrect
        lifetimeAccuracy = lifetimeDecisions > 0
            ? Double(totalCorrect) / Double(lifetimeDecisions) * 100 : 0

        // Streaks
        computeStreaks(from: records)

        // Accuracy by hand type
        let types = ["hard", "soft", "pair"]
        accuracyByHandType = types.map { type in
            let filtered = records.filter { $0.handTypeRaw == type }
            let c = filtered.reduce(0) { $0 + $1.correctCount }
            let t = filtered.reduce(0) { $0 + $1.correctCount + $1.incorrectCount }
            return AccuracyByCategory(
                label: type.capitalized,
                accuracy: t > 0 ? Double(c) / Double(t) * 100 : 0,
                total: t
            )
        }

        // Accuracy by dealer upcard
        let rankSymbols = ["2","3","4","5","6","7","8","9","10","A"]
        accuracyByDealerUpcard = rankSymbols.map { sym in
            let filtered = records.filter { record in
                let upcard = (try? JSONDecoder().decode(Card.self, from: record.dealerUpcardData))
                return upcard?.rank.symbol == sym || (sym == "10" && ["10","J","Q","K"].contains(upcard?.rank.symbol ?? ""))
            }
            let c = filtered.reduce(0) { $0 + $1.correctCount }
            let t = filtered.reduce(0) { $0 + $1.correctCount + $1.incorrectCount }
            return DealerHeatCell(
                dealerRank: sym,
                accuracy: t > 0 ? Double(c) / Double(t) * 100 : 0,
                sampleSize: t
            )
        }

        // Top mistakes
        var mistakeMap: [String: (count: Int, correct: String)] = [:]
        for record in records {
            for action in record.actions where !action.wasCorrect {
                let upcard = (try? JSONDecoder().decode(Card.self, from: record.dealerUpcardData))?.rank.symbol ?? "?"
                let key = "\(record.handTypeRaw.capitalized) \(record.playerTotal) vs \(upcard)"
                let existing = mistakeMap[key] ?? (0, action.correctAction.displayName)
                mistakeMap[key] = (existing.count + 1, action.correctAction.displayName)
            }
        }
        topMistakes = mistakeMap
            .sorted { $0.value.count > $1.value.count }
            .prefix(10)
            .map { key, val in MistakeEntry(label: key, count: val.count, correctAction: val.correct) }
    }

    private func computeStreaks(from records: [HandRecord]) {
        var current = 0
        var longest = 0
        for record in records {
            for action in record.actions {
                if action.wasCorrect {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 0
                }
            }
        }
        currentStreak = current
        longestStreak = longest
    }
}

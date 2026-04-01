import Foundation
import SwiftData

struct ActionRecord: Codable {
    let action: Action
    let wasCorrect: Bool
    let correctAction: Action
    let explanation: String
}

@Model
final class HandRecord {
    var id: UUID
    var timestamp: Date
    var spotNumber: Int

    // Card data stored as JSON
    var playerCardsData: Data    // [Card]
    var dealerUpcardData: Data   // Card
    var dealerHoleCardData: Data // Card
    var dealerFinalHandData: Data // [Card]

    // Hand classification
    var handTypeRaw: String      // "hard", "soft", "pair"
    var playerTotal: Int

    // Actions taken this hand
    var actionsData: Data        // [ActionRecord]

    // Outcome
    var outcomeRaw: String       // "win", "lose", "push", "blackjack", "surrender"
    var wasSplit: Bool
    var wasDoubled: Bool
    var wasSurrendered: Bool

    var session: GameSession?

    var actions: [ActionRecord] {
        (try? JSONDecoder().decode([ActionRecord].self, from: actionsData)) ?? []
    }

    var correctCount: Int { actions.filter { $0.wasCorrect }.count }
    var incorrectCount: Int { actions.filter { !$0.wasCorrect }.count }

    init(
        spotNumber: Int,
        playerCards: [Card],
        dealerUpcard: Card,
        dealerHoleCard: Card,
        dealerFinalHand: [Card],
        handType: String,
        playerTotal: Int,
        actions: [ActionRecord],
        outcome: String,
        wasSplit: Bool,
        wasDoubled: Bool,
        wasSurrendered: Bool
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.spotNumber = spotNumber
        self.playerCardsData = (try? JSONEncoder().encode(playerCards)) ?? Data()
        self.dealerUpcardData = (try? JSONEncoder().encode(dealerUpcard)) ?? Data()
        self.dealerHoleCardData = (try? JSONEncoder().encode(dealerHoleCard)) ?? Data()
        self.dealerFinalHandData = (try? JSONEncoder().encode(dealerFinalHand)) ?? Data()
        self.handTypeRaw = handType
        self.playerTotal = playerTotal
        self.actionsData = (try? JSONEncoder().encode(actions)) ?? Data()
        self.outcomeRaw = outcome
        self.wasSplit = wasSplit
        self.wasDoubled = wasDoubled
        self.wasSurrendered = wasSurrendered
    }
}

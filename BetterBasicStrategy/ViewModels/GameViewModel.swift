import Foundation
import SwiftData
import Observation

@Observable
final class GameViewModel {
    // MARK: - Dependencies
    private(set) var shoe: Shoe
    private(set) var rules: RuleSet
    private(set) var engine: GameEngine

    // MARK: - Session tracking
    private var modelContext: ModelContext?
    private var currentSession: GameSession?

    // MARK: - UI State
    var showStrategyDrawer: Bool = false
    var showCoachingCard: Bool = false
    var coachingEntry: StrategyEntry? = nil

    // Session stats (updated each hand)
    private(set) var sessionCorrect: Int = 0
    private(set) var sessionTotal: Int = 0
    var sessionAccuracy: Double {
        guard sessionTotal > 0 else { return 0 }
        return Double(sessionCorrect) / Double(sessionTotal) * 100
    }

    init() {
        let savedRules = GameViewModel.loadRules()
        self.rules = savedRules
        let shoe = Shoe(penetrationTrigger: savedRules.penetrationPercent)
        self.shoe = shoe
        self.engine = GameEngine(shoe: shoe, rules: savedRules)
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        startSession()
    }

    // MARK: - Session

    private func startSession() {
        let session = GameSession(rules: rules)
        currentSession = session
        modelContext?.insert(session)
    }

    // MARK: - Actions

    func dealNewRound() {
        showCoachingCard = false
        coachingEntry = nil
        engine.dealNewRound()
    }

    func performAction(_ category: DecisionCategory) {
        engine.performAction(category)

        let wasCorrect = engine.lastActionWasCorrect
        sessionTotal += 1
        if wasCorrect {
            sessionCorrect += 1
            HapticManager.correct()
            showCoachingCard = false
        } else {
            HapticManager.incorrect()
            coachingEntry = engine.lastCoachingEntry
            showCoachingCard = true
        }

        if engine.phase == .roundOver {
            finalizeRound()
        }
    }

    func dismissCoachingCard() {
        showCoachingCard = false
        // If round is over, allow new deal; else continue player turn
    }

    // MARK: - Rules

    func updateRules(_ newRules: RuleSet) {
        rules = newRules
        GameViewModel.saveRules(newRules)
        shoe.penetrationTrigger = newRules.penetrationPercent
        shoe.resetAndReshuffle()
        engine.updateRules(newRules)
        engine.resetToIdle()
        endSession()
        startSession()
    }

    // MARK: - Persistence helpers

    private func finalizeRound() {
        guard let session = currentSession, let context = modelContext else { return }

        session.handsPlayed += engine.spots.count
        session.spotsPlayed += engine.spots.count

        for (spotIdx, spot) in engine.spots.enumerated() {
            for (handIdx, hand) in spot.hands.enumerated() {
                let actions = spot.actions[safe: handIdx] ?? []
                let correct = actions.filter { $0.wasCorrect }.count
                let incorrect = actions.filter { !$0.wasCorrect }.count
                session.correctDecisions += correct
                session.incorrectDecisions += incorrect

                let outcome = spot.outcomes[safe: handIdx] ?? .lose
                let record = HandRecord(
                    spotNumber: spotIdx,
                    playerCards: hand.cards,
                    dealerUpcard: engine.dealerHand.cards.first ?? Card(suit: .spades, rank: .two),
                    dealerHoleCard: engine.dealerHoleCard ?? Card(suit: .spades, rank: .two),
                    dealerFinalHand: engine.dealerHand.cards,
                    handType: handKey(hand),
                    playerTotal: hand.total,
                    actions: actions,
                    outcome: outcome.rawValue,
                    wasSplit: spot.hands.count > 1,
                    wasDoubled: actions.contains { $0.action == .doubleOrHit || $0.action == .doubleOrStand },
                    wasSurrendered: outcome == .surrender
                )
                record.session = session
                context.insert(record)
            }
        }

        try? context.save()
    }

    private func handKey(_ hand: Hand) -> String {
        switch hand.handKey {
        case .hard: return "hard"
        case .soft: return "soft"
        case .pair: return "pair"
        }
    }

    private func endSession() {
        currentSession?.endedAt = Date()
        try? modelContext?.save()
        currentSession = nil
    }

    private static let rulesKey = "saved_rules"

    private static func loadRules() -> RuleSet {
        guard let data = UserDefaults.standard.data(forKey: rulesKey),
              let rules = try? JSONDecoder().decode(RuleSet.self, from: data) else {
            return .default
        }
        return rules
    }

    private static func saveRules(_ rules: RuleSet) {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: rulesKey)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

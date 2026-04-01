import Foundation
import SwiftData

// MARK: - Game State

enum GamePhase {
    case idle           // Waiting to deal
    case playerTurn     // Active spot needs decision
    case dealerTurn     // All spots resolved; dealer playing
    case roundOver      // Show results
}

enum Outcome: String {
    case win, lose, push, blackjack, surrender, bust
}

struct SpotState: Identifiable {
    let id: UUID = UUID()
    var hands: [Hand]           // 1 hand normally; up to 4 after splits
    var activeHandIndex: Int = 0
    var outcomes: [Outcome] = []
    var actions: [[ActionRecord]] = [[]]  // per-hand action history
    var isComplete: Bool = false

    var activeHand: Hand? { hands[safe: activeHandIndex] }
}

// MARK: - Game Engine

@Observable
final class GameEngine {
    private(set) var phase: GamePhase = .idle
    private(set) var spots: [SpotState] = []
    private(set) var activeSpotIndex: Int = 0
    private(set) var dealerHand: Hand = Hand(isDealer: true)
    private(set) var dealerHoleCard: Card? = nil
    private(set) var lastCoachingEntry: StrategyEntry? = nil
    private(set) var lastActionWasCorrect: Bool = true

    private var shoe: Shoe
    private var rules: RuleSet
    private var strategyEngine: BasicStrategyEngine

    var activeSpot: SpotState? { spots[safe: activeSpotIndex] }
    var activeHand: Hand? { activeSpot?.activeHand }

    init(shoe: Shoe, rules: RuleSet) {
        self.shoe = shoe
        self.rules = rules
        self.strategyEngine = BasicStrategyEngine(rules: rules)
    }

    func updateRules(_ newRules: RuleSet) {
        rules = newRules
        strategyEngine = BasicStrategyEngine(rules: newRules)
    }

    // MARK: - Deal

    func dealNewRound() {
        guard phase == .idle || phase == .roundOver else { return }

        if shoe.needsReshuffle { shoe.shuffle() }

        // Build empty spots
        spots = (0..<rules.numberOfSpots).map { _ in
            SpotState(hands: [Hand()])
        }
        dealerHand = Hand(isDealer: true)
        lastCoachingEntry = nil

        // Deal: player card, dealer card, player card, dealer hole card (2 passes)
        for _ in 0..<2 {
            for i in 0..<spots.count {
                if let card = shoe.deal() {
                    spots[i].hands[0].cards.append(card)
                }
            }
            if let card = shoe.deal() {
                dealerHand.cards.append(card)
            }
        }
        dealerHoleCard = dealerHand.cards[safe: 1]

        activeSpotIndex = 0
        phase = .playerTurn

        // Auto-complete spots with blackjack
        checkForBlackjacks()
    }

    private func checkForBlackjacks() {
        for i in 0..<spots.count {
            if spots[i].hands[0].isBlackjack {
                spots[i].isComplete = true
                spots[i].outcomes = [.blackjack]
            }
        }
        advanceIfNeeded()
    }

    // MARK: - Player Actions

    /// Available actions for the current active hand
    var availableActions: Set<DecisionCategory> {
        guard let hand = activeHand, phase == .playerTurn else { return [] }
        var actions: Set<DecisionCategory> = [.hit, .stand]

        // Double: only on first two cards of a hand
        if hand.cards.count == 2 {
            let isAfterSplit = activeSpot?.hands.count ?? 1 > 1
            if !isAfterSplit || rules.doubleAfterSplit {
                actions.insert(.double)
            }
        }

        // Split: only 2 cards, same strategy rank, within split limit
        if hand.cards.count == 2,
           hand.cards[0].rank.strategyRank == hand.cards[1].rank.strategyRank {
            let handsInSpot = activeSpot?.hands.count ?? 1
            let isAcePair = hand.cards[0].rank == .ace
            if handsInSpot < 4 && (!isAcePair || rules.resplitAces) || handsInSpot == 1 {
                actions.insert(.split)
            }
        }

        // Surrender: only on first two cards, first action
        if hand.cards.count == 2,
           let spot = activeSpot,
           spot.actions[spot.activeHandIndex].isEmpty {
            if rules.surrenderRule != .none {
                actions.insert(.surrender)
            }
        }

        return actions
    }

    func performAction(_ category: DecisionCategory) {
        guard phase == .playerTurn,
              var spot = activeSpot,
              var hand = spot.activeHand,
              let dealerUp = dealerHand.cards.first else { return }

        let canDouble = availableActions.contains(.double)
        let canSplit = availableActions.contains(.split)
        let canSurrender = availableActions.contains(.surrender)

        // Evaluate correctness
        let rawCorrect = strategyEngine.correctAction(hand: hand, dealerUpcard: dealerUp)
        let resolvedCorrect = rawCorrect.resolved(canDouble: canDouble, canSplit: canSplit, canSurrender: canSurrender)
        let isCorrect = resolvedCorrect.primaryDecisionCategory == category

        let entry = strategyEngine.correctEntry(hand: hand, dealerUpcard: dealerUp)
        lastCoachingEntry = isCorrect ? nil : entry
        lastActionWasCorrect = isCorrect

        // Record action
        let record = ActionRecord(
            action: category.asAction,
            wasCorrect: isCorrect,
            correctAction: resolvedCorrect,
            explanation: entry?.explanation ?? ""
        )
        spots[activeSpotIndex].actions[spot.activeHandIndex].append(record)

        // Execute action
        switch category {
        case .hit:
            if let card = shoe.deal() {
                spots[activeSpotIndex].hands[spot.activeHandIndex].cards.append(card)
            }
            if spots[activeSpotIndex].hands[spot.activeHandIndex].total >= 21 {
                advanceHand()
            }

        case .stand:
            advanceHand()

        case .double:
            spots[activeSpotIndex].hands[spot.activeHandIndex].cards.append(shoe.deal() ?? Card(suit: .spades, rank: .two))
            advanceHand()

        case .split:
            let splitCard = spots[activeSpotIndex].hands[spot.activeHandIndex].cards.removeLast()
            var newHand = Hand()
            newHand.cards = [splitCard]
            if let fill = shoe.deal() { spots[activeSpotIndex].hands[spot.activeHandIndex].cards.append(fill) }
            if let fill2 = shoe.deal() { newHand.cards.append(fill2) }
            spots[activeSpotIndex].hands.append(newHand)
            spots[activeSpotIndex].actions.append([])
            spots[activeSpotIndex].outcomes.append(.lose)  // placeholder
            // If split aces, auto-advance (one card each)
            if splitCard.rank == .ace && !rules.resplitAces {
                advanceHand()
            }

        case .surrender:
            spots[activeSpotIndex].outcomes = [.surrender]
            spots[activeSpotIndex].isComplete = true
            advanceIfNeeded()
        }
    }

    private func advanceHand() {
        guard let spot = activeSpot else { return }
        let nextHandIndex = spot.activeHandIndex + 1
        if nextHandIndex < spot.hands.count {
            spots[activeSpotIndex].activeHandIndex = nextHandIndex
        } else {
            spots[activeSpotIndex].isComplete = true
            advanceIfNeeded()
        }
    }

    private func advanceIfNeeded() {
        // Find next incomplete spot
        if let nextSpot = spots.indices.first(where: { !spots[$0].isComplete && $0 > activeSpotIndex }) {
            activeSpotIndex = nextSpot
        } else if spots.allSatisfy({ $0.isComplete }) {
            playDealer()
        }
    }

    // MARK: - Dealer Turn

    private func playDealer() {
        phase = .dealerTurn
        // Dealer plays until 17+ (H17: hits soft 17; S17: stands on soft 17)
        while shouldDealerHit() {
            if let card = shoe.deal() {
                dealerHand.cards.append(card)
            } else { break }
        }
        resolveOutcomes()
    }

    private func shouldDealerHit() -> Bool {
        let total = dealerHand.total
        if total < 17 { return true }
        if total == 17 && dealerHand.isSoft && rules.dealerRule == .h17 { return true }
        return false
    }

    // MARK: - Outcomes

    private func resolveOutcomes() {
        let dealerTotal = dealerHand.total
        let dealerBust = dealerTotal > 21

        for i in 0..<spots.count {
            guard !spots[i].isComplete || spots[i].outcomes.isEmpty else { continue }
            var outcomes: [Outcome] = []
            for hand in spots[i].hands {
                if hand.isBlackjack { outcomes.append(.blackjack); continue }
                if hand.total > 21 { outcomes.append(.bust); continue }
                if dealerBust { outcomes.append(.win); continue }
                if hand.total > dealerTotal { outcomes.append(.win) }
                else if hand.total == dealerTotal { outcomes.append(.push) }
                else { outcomes.append(.lose) }
            }
            spots[i].outcomes = outcomes
            spots[i].isComplete = true
        }
        phase = .roundOver
    }

    func resetToIdle() {
        phase = .idle
        spots = []
        dealerHand = Hand(isDealer: true)
        lastCoachingEntry = nil
    }
}

// MARK: - Helpers

private extension DecisionCategory {
    var asAction: Action {
        switch self {
        case .hit: return .hit
        case .stand: return .stand
        case .double: return .doubleOrHit
        case .split: return .split
        case .surrender: return .surrenderOrHit
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

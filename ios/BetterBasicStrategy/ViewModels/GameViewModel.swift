import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var shoe: ShoeState = ShoeState.load()
    @Published var sessionCorrect = 0
    @Published var sessionTotal   = 0
    @Published var showCoaching   = false

    let rules = RuleSet()
    private(set) var engine: BasicStrategyEngine
    private var currentSession: GameSession?
    private(set) var currentUser: BBSUser?

    init() { engine = BasicStrategyEngine(rules: RuleSet()) }

    var sessionAccuracy: Double {
        sessionTotal > 0 ? Double(sessionCorrect) / Double(sessionTotal) * 100 : 0
    }
    var availableActions: Set<DecisionCategory> {
        GameEngine.getAvailableActions(state: gameState, rules: rules)
    }
    var activeSpot: SpotState? { gameState.spots[safe: gameState.activeSpotIndex] }
    var activeHand: HandState? { activeSpot.flatMap { $0.hands[safe: $0.activeHandIndex] } }
    var dealerUpcard: Card?   { gameState.dealerCards.first }
    var dealerTotal: Int? {
        gameState.dealerCards.isEmpty ? nil : calcTotal(gameState.dealerCards).total
    }

    // MARK: - Session

    func startSession(user: BBSUser) async {
        currentUser = user
        guard let session = try? await SupabaseService.shared.createSession(userId: user.id, rules: rules) else { return }
        currentSession = session
    }

    // MARK: - Game actions

    func deal() {
        let (newState, reshuffled) = GameEngine.dealNewRound(state: gameState, shoe: &shoe, rules: rules)
        gameState = newState
        showCoaching = false
        if reshuffled, let user = currentUser, let session = currentSession {
            Task { try? await SupabaseService.shared.saveShoeEvent(userId: user.id, sessionId: session.id) }
        }
    }

    func performAction(_ category: DecisionCategory) {
        guard gameState.phase == .playerTurn, !showCoaching else { return }
        let newState = GameEngine.performAction(
            state: gameState, shoe: &shoe, category: category, rules: rules, engine: engine
        )
        if newState.lastActionWasCorrect == true { sessionCorrect += 1 }
        sessionTotal += 1
        gameState = newState
        if newState.lastCoachingEntry != nil { showCoaching = true }
        if newState.phase == .roundOver { persistRound(state: newState) }
    }

    func dismissCoaching() { showCoaching = false }

    // MARK: - Persistence

    private func persistRound(state: GameState) {
        guard let user = currentUser, let session = currentSession else { return }
        Task {
            for (si, spot) in state.spots.enumerated() {
                for (hi, hand) in spot.hands.enumerated() {
                    let outcome   = spot.outcomes[safe: hi] ?? .lose
                    let actions   = spot.actions[safe: hi] ?? []
                    try? await SupabaseService.shared.saveHandRecord(
                        sessionId: session.id, userId: user.id, spotNumber: si,
                        playerCards: hand.cards, dealerUpcard: state.dealerCards[0],
                        dealerFinalHand: state.dealerCards, handType: hand.handType,
                        playerTotal: hand.total, actionsTaken: actions, outcome: outcome,
                        wasSplit: spot.hands.count > 1,
                        wasDoubled: actions.contains { $0.action == .double },
                        wasSurrendered: outcome == .surrender
                    )
                }
            }
            try? await SupabaseService.shared.updateSession(
                sessionId: session.id,
                handsPlayed: sessionTotal,
                correctDecisions: sessionCorrect,
                incorrectDecisions: sessionTotal - sessionCorrect
            )
        }
    }
}

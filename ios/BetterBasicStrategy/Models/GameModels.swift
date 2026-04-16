import Foundation

enum GamePhase: String, Codable { case idle, playerTurn, dealerTurn, roundOver }

enum Outcome: String, Codable {
    case win, lose, push, blackjack, surrender, bust

    var display: String {
        switch self {
        case .win:       return "WIN"
        case .lose:      return "LOSE"
        case .push:      return "PUSH"
        case .blackjack: return "BLACKJACK"
        case .surrender: return "SURRENDER"
        case .bust:      return "BUST"
        }
    }
}

enum RawAction: String, Codable, Equatable {
    case hit, stand, doubleOrHit, doubleOrStand, split
    case surrenderOrHit, surrenderOrStand, surrenderOrSplit
}

enum DecisionCategory: String, Codable, CaseIterable, Equatable {
    case hit, stand, double, split, surrender
    var display: String { rawValue.capitalized }
}

enum DealerRule: String, Codable  { case H17, S17 }
enum SurrenderRule: String, Codable { case none, late, early }

struct RuleSet: Codable {
    var dealerRule: DealerRule = .H17
    var doubleAfterSplit: Bool = true
    var resplitAces: Bool = false
    var surrenderRule: SurrenderRule = .late
    var blackjackPays: String = "3:2"
    var numberOfSpots: Int = 1
    var penetrationPercent: Double = 0.75
}

struct StrategyEntry: Codable {
    let action: RawAction
    let explanation: String
}

struct ActionRecord: Codable, Identifiable {
    var id: String = UUID().uuidString
    let action: DecisionCategory
    let wasCorrect: Bool
    let correctAction: RawAction
    let explanation: String

    // Explicit keys so convertFromSnakeCase is bypassed for camelCase JSONB storage
    enum CodingKeys: String, CodingKey {
        case id, action, wasCorrect, correctAction, explanation
    }
}

struct SpotState: Codable, Identifiable {
    let id: String
    var hands: [HandState]
    var activeHandIndex: Int
    var outcomes: [Outcome]
    var actions: [[ActionRecord]]
    var isComplete: Bool
}

struct GameState: Codable {
    var phase: GamePhase = .idle
    var spots: [SpotState] = []
    var activeSpotIndex: Int = 0
    var dealerCards: [Card] = []
    var dealerHoleRevealed: Bool = false
    var lastActionWasCorrect: Bool? = nil
    var lastCoachingEntry: StrategyEntry? = nil
}

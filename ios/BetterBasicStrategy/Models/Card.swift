import Foundation

enum Suit: String, CaseIterable, Codable {
    case hearts, diamonds, clubs, spades

    var symbol: String {
        switch self {
        case .hearts:   return "♥"
        case .diamonds: return "♦"
        case .clubs:    return "♣"
        case .spades:   return "♠"
        }
    }

    var isRed: Bool { self == .hearts || self == .diamonds }
}

struct Card: Identifiable, Codable, Equatable, Hashable {
    let suit: Suit
    let rank: Int  // 2–14 (14=Ace, 11=J, 12=Q, 13=K)
    let id: String

    var displayRank: String {
        switch rank {
        case 14: return "A"
        case 13: return "K"
        case 12: return "Q"
        case 11: return "J"
        default: return "\(rank)"
        }
    }

    // Blackjack point value (Ace = 11 initially)
    var rankValue: Int {
        switch rank {
        case 14:       return 11
        case 11, 12, 13: return 10
        default:       return rank
        }
    }

    // Strategy-table rank (J/Q/K all map to 10)
    var strategyRank: Int {
        (11...13).contains(rank) ? 10 : rank
    }

    var suitSymbol: String { suit.symbol }
    var isRed: Bool { suit.isRed }
}

let allSuits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
let allRanks: [Int]  = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

private var _cardIdCounter = 0
func makeCard(suit: Suit, rank: Int) -> Card {
    _cardIdCounter += 1
    return Card(suit: suit, rank: rank, id: "\(suit.rawValue)-\(rank)-\(_cardIdCounter)")
}

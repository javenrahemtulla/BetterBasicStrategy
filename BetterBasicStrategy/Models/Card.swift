import Foundation

enum Suit: String, CaseIterable, Codable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"

    var isRed: Bool { self == .hearts || self == .diamonds }
}

enum Rank: Int, CaseIterable, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Face value (J/Q/K = 10, Ace = 11)
    var value: Int {
        switch self {
        case .jack, .queen, .king: return 10
        case .ace: return 11
        default: return rawValue
        }
    }

    /// For strategy table lookup — J/Q/K all collapse to .ten
    var strategyRank: Rank {
        switch self {
        case .jack, .queen, .king: return .ten
        default: return self
        }
    }

    var symbol: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }
}

struct Card: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let suit: Suit
    let rank: Rank

    init(suit: Suit, rank: Rank) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
    }
}

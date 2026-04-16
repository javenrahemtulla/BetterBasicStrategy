import Foundation

enum HandType: String, Codable, Equatable {
    case hard, soft, pair
}

enum HandKey: Codable, Equatable {
    case hard(Int)
    case soft(Int)
    case pair(Int)  // strategy rank (J/Q/K → 10)

    var keyString: String {
        switch self {
        case .hard(let v): return "hard-\(v)"
        case .soft(let v): return "soft-\(v)"
        case .pair(let v): return "pair-\(v)"
        }
    }
}

struct HandState: Codable, Equatable {
    var cards: [Card]
    let total: Int
    let isSoft: Bool
    let isBust: Bool
    let isBlackjack: Bool
    let handType: HandType
    let handKey: HandKey

    static func build(from cards: [Card]) -> HandState {
        let (total, isSoft) = calcTotal(cards)
        let key = getHandKey(cards: cards, total: total, isSoft: isSoft)
        let type_: HandType
        switch key {
        case .pair: type_ = .pair
        case .soft: type_ = .soft
        case .hard: type_ = .hard
        }
        return HandState(
            cards: cards,
            total: total,
            isSoft: isSoft,
            isBust: total > 21,
            isBlackjack: cards.count == 2 && total == 21,
            handType: type_,
            handKey: key
        )
    }
}

func calcTotal(_ cards: [Card]) -> (total: Int, isSoft: Bool) {
    var sum = 0
    var aces = 0
    for card in cards {
        if card.rank == 14 { aces += 1 }
        sum += card.rankValue
    }
    var reduced = 0
    while sum > 21 && reduced < aces {
        sum -= 10
        reduced += 1
    }
    return (sum, reduced < aces)
}

func getHandKey(cards: [Card], total: Int, isSoft: Bool) -> HandKey {
    if cards.count == 2 {
        let r1 = cards[0].strategyRank
        let r2 = cards[1].strategyRank
        if r1 == r2 { return .pair(r1) }
    }
    if isSoft && total >= 13 && total <= 21 { return .soft(total) }
    return .hard(total)
}

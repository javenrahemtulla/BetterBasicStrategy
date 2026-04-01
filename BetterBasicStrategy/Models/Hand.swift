import Foundation

enum HandKey: Hashable {
    case hard(Int)   // total 5–21
    case soft(Int)   // 13–21 (ace counted as 11, e.g. A+2=soft 13)
    case pair(Rank)  // exactly 2 cards of identical rank (J/Q/K all treated as ten-pair)
}

struct Hand: Identifiable {
    let id: UUID
    var cards: [Card]
    var isDealer: Bool
    var isBust: Bool { total > 21 }
    var isBlackjack: Bool { cards.count == 2 && total == 21 }
    var isSoft17: Bool { softTotal == 17 }

    init(cards: [Card] = [], isDealer: Bool = false) {
        self.id = UUID()
        self.cards = cards
        self.isDealer = isDealer
    }

    /// Hard total (aces count as 1 if needed to avoid bust)
    var total: Int {
        var sum = 0
        var aceCount = 0
        for card in cards {
            if card.rank == .ace {
                aceCount += 1
                sum += 11
            } else {
                sum += card.rank.value
            }
        }
        while sum > 21 && aceCount > 0 {
            sum -= 10
            aceCount -= 1
        }
        return sum
    }

    /// True if hand has a soft total (at least one ace counting as 11)
    var isSoft: Bool {
        var sum = 0
        var aceCount = 0
        for card in cards {
            if card.rank == .ace {
                aceCount += 1
                sum += 11
            } else {
                sum += card.rank.value
            }
        }
        var reducedAces = 0
        while sum > 21 && reducedAces < aceCount {
            sum -= 10
            reducedAces += 1
        }
        return reducedAces < aceCount  // at least one ace still counting as 11
    }

    private var softTotal: Int { total }

    /// Canonical HandKey for strategy lookup
    var handKey: HandKey {
        // Pair: exactly 2 cards, same strategy rank (J=Q=K=10)
        if cards.count == 2 {
            let r1 = cards[0].rank.strategyRank
            let r2 = cards[1].rank.strategyRank
            if r1 == r2 { return .pair(r1) }
        }
        let t = total
        if isSoft && t >= 13 && t <= 21 { return .soft(t) }
        return .hard(t)
    }
}

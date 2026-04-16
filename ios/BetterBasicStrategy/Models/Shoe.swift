import Foundation

struct ShoeState: Codable {
    var cards: [Card]
    var currentIndex: Int
    var penetrationTrigger: Double

    static func create(penetrationTrigger: Double = 0.75) -> ShoeState {
        var deck: [Card] = []
        for _ in 0..<6 {
            for suit in allSuits {
                for rank in allRanks {
                    deck.append(makeCard(suit: suit, rank: rank))
                }
            }
        }
        // Fisher-Yates shuffle
        for i in stride(from: deck.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            deck.swapAt(i, j)
        }
        return ShoeState(cards: deck, currentIndex: 0, penetrationTrigger: penetrationTrigger)
    }

    var needsReshuffle: Bool {
        let pen = cards.isEmpty ? 1.0 : Double(currentIndex) / Double(cards.count)
        return pen >= penetrationTrigger || currentIndex >= cards.count
    }

    var penetration: Double {
        cards.isEmpty ? 0 : Double(currentIndex) / Double(cards.count)
    }

    var remainingCount: Int { cards.count - currentIndex }

    mutating func deal() -> Card? {
        guard currentIndex < cards.count else { return nil }
        defer { currentIndex += 1 }
        return cards[currentIndex]
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "bbs_shoe")
        }
    }

    static func load(penetrationTrigger: Double = 0.75) -> ShoeState {
        if let data = UserDefaults.standard.data(forKey: "bbs_shoe"),
           let shoe = try? JSONDecoder().decode(ShoeState.self, from: data),
           shoe.cards.count == 312 {
            return shoe
        }
        return create(penetrationTrigger: penetrationTrigger)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: "bbs_shoe")
    }
}

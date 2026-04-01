import Foundation
import Observation

@Observable
final class Shoe {
    private(set) var cards: [Card] = []
    private(set) var currentIndex: Int = 0
    var penetrationTrigger: Double = 0.75

    var totalCards: Int { cards.count }
    var dealtCount: Int { currentIndex }
    var remainingCount: Int { totalCards - currentIndex }
    var penetration: Double {
        guard totalCards > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCards)
    }
    var needsReshuffle: Bool { penetration >= penetrationTrigger || currentIndex >= totalCards }

    private static let saveKey = "shoe_state"

    init(penetrationTrigger: Double = 0.75) {
        self.penetrationTrigger = penetrationTrigger
        if !loadFromDisk() {
            shuffle()
        }
    }

    func shuffle() {
        var deck: [Card] = []
        for _ in 0..<6 {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    deck.append(Card(suit: suit, rank: rank))
                }
            }
        }
        // Fisher-Yates
        for i in stride(from: deck.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            deck.swapAt(i, j)
        }
        cards = deck
        currentIndex = 0
        saveToDisk()
    }

    func deal() -> Card? {
        guard currentIndex < cards.count else { return nil }
        let card = cards[currentIndex]
        currentIndex += 1
        saveToDisk()
        return card
    }

    // MARK: - Persistence

    private struct ShoeState: Codable {
        let cards: [Card]
        let currentIndex: Int
    }

    private func saveToDisk() {
        let state = ShoeState(cards: cards, currentIndex: currentIndex)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    private func loadFromDisk() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey),
              let state = try? JSONDecoder().decode(ShoeState.self, from: data),
              !state.cards.isEmpty else {
            return false
        }
        cards = state.cards
        currentIndex = state.currentIndex
        return true
    }

    func resetAndReshuffle() {
        UserDefaults.standard.removeObject(forKey: Self.saveKey)
        shuffle()
    }
}

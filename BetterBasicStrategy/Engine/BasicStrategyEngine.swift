import Foundation

struct BasicStrategyEngine {
    private let table: StrategyTableMap

    init(rules: RuleSet) {
        self.table = StrategyTable.build(rules: rules)
    }

    /// Returns the raw strategy action (may be compound). Call .resolved() to get concrete action.
    func correctEntry(hand: Hand, dealerUpcard: Card) -> StrategyEntry? {
        let key = hand.handKey
        let dealerRank = dealerUpcard.rank.strategyRank
        return table[key]?[dealerRank]
    }

    func correctAction(hand: Hand, dealerUpcard: Card) -> Action {
        correctEntry(hand: hand, dealerUpcard: dealerUpcard)?.action ?? .hit
    }

    func explanation(hand: Hand, dealerUpcard: Card) -> String {
        correctEntry(hand: hand, dealerUpcard: dealerUpcard)?.explanation
            ?? "Hit when in doubt."
    }
}

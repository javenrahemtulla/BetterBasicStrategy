import SwiftUI

struct DealerHandView: View {
    let hand: Hand
    let phase: GamePhase

    private var visibleCards: [Card?] {
        guard !hand.cards.isEmpty else { return [] }
        if phase == .playerTurn {
            // Hole card face-down
            return [hand.cards.first].compactMap { $0 } + (hand.cards.count > 1 ? [nil] : [])
        }
        return hand.cards.map { Optional($0) }
    }

    private var totalText: String {
        guard phase != .playerTurn else {
            return hand.cards.first.map { "\($0.rank.value)" } ?? ""
        }
        return hand.isBust ? "BUST" : "\(hand.total)"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("DEALER")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .tracking(2)

            CardStack(cards: visibleCards, cardWidth: 58, cardHeight: 80, overlap: 20)

            if phase != .idle {
                Text(totalText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(hand.isBust ? Theme.actionStand : Theme.textPrimary)
                    .animation(.easeInOut, value: totalText)
            }
        }
    }
}

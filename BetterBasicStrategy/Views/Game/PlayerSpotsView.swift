import SwiftUI

struct PlayerSpotsView: View {
    let spots: [SpotState]
    let activeSpotIndex: Int
    let phase: GamePhase

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(spots.enumerated()), id: \.element.id) { idx, spot in
                SpotView(
                    spot: spot,
                    isActive: idx == activeSpotIndex && phase == .playerTurn,
                    phase: phase
                )
            }
        }
    }
}

private struct SpotView: View {
    let spot: SpotState
    let isActive: Bool
    let phase: GamePhase

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(spot.hands.enumerated()), id: \.element.id) { handIdx, hand in
                VStack(spacing: 4) {
                    CardStack(
                        cards: hand.cards.map { Optional($0) },
                        cardWidth: 55,
                        cardHeight: 77,
                        overlap: 18
                    )

                    // Total
                    let total = hand.total
                    let isActiveHand = handIdx == spot.activeHandIndex && isActive
                    Text(hand.isBust ? "BUST" : "\(total)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(hand.isBust ? Theme.actionStand : (isActiveHand ? Theme.gold : Theme.textPrimary))

                    // Outcome badge
                    if phase == .roundOver, let outcome = spot.outcomes[safe: handIdx] {
                        OutcomeBadge(outcome: outcome)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isActiveHand(handIdx) ? Color.white.opacity(0.07) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isActiveHand(handIdx) ? Theme.gold.opacity(0.5) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                )
            }
        }
    }

    private func isActiveHand(_ idx: Int) -> Bool {
        isActive && idx == spot.activeHandIndex
    }
}

private struct OutcomeBadge: View {
    let outcome: Outcome

    var body: some View {
        Text(outcome.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(outcome.badgeColor))
    }
}

extension Outcome {
    var displayName: String {
        switch self {
        case .win: return "WIN"
        case .lose: return "LOSE"
        case .push: return "PUSH"
        case .blackjack: return "BLACKJACK"
        case .surrender: return "SURRENDER"
        case .bust: return "BUST"
        }
    }

    var badgeColor: Color {
        switch self {
        case .win, .blackjack: return Theme.actionHit
        case .lose, .bust: return Theme.actionStand
        case .push: return Theme.textSecondary
        case .surrender: return Theme.actionSurrender
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

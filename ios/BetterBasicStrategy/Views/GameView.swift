import SwiftUI

struct GameView: View {
    let user: BBSUser
    let onStats: () -> Void
    let onExit:  () -> Void

    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                ScrollView {
                    VStack(spacing: 12) {
                        dealerArea
                            .padding(.horizontal)

                        ForEach(Array(vm.gameState.spots.enumerated()), id: \.offset) { idx, spot in
                            spotView(spot: spot, isActive: idx == vm.gameState.activeSpotIndex)
                                .padding(.horizontal)
                        }

                        controlsArea
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                }
            }

            if vm.showCoaching, let entry = vm.gameState.lastCoachingEntry {
                CoachingCardView(entry: entry, onDismiss: vm.dismissCoaching)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .task { await vm.startSession(user: user) }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: onExit) {
                Label("Exit", systemImage: "chevron.left").foregroundColor(.muted)
            }
            .font(.system(size: 15))

            Spacer()

            Text(user.username)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.cream)

            Spacer()

            Button(action: onStats) {
                Label("Stats", systemImage: "chart.bar").foregroundColor(.gold)
            }
            .font(.system(size: 15))
        }
    }

    // MARK: - Dealer area

    private var dealerArea: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Dealer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.muted)
                Spacer()
                if vm.gameState.dealerHoleRevealed, let total = vm.dealerTotal {
                    Text("\(total)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.cream)
                } else if let upcard = vm.dealerUpcard {
                    Text("\(upcard.rankValue)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.muted)
                }
            }

            HStack {
                if vm.gameState.dealerCards.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.feltDark.opacity(0.5))
                        .frame(width: 140, height: 90)
                        .overlay(Text("Waiting…").foregroundColor(.muted.opacity(0.4)).font(.caption))
                } else {
                    CardStack(
                        cards: vm.gameState.dealerCards,
                        holeRevealed: vm.gameState.dealerHoleRevealed,
                        cardWidth: 60, cardHeight: 88
                    )
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color.feltDark.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Spot / hand views

    @ViewBuilder
    private func spotView(spot: SpotState, isActive: Bool) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(spot.hands.enumerated()), id: \.offset) { hi, hand in
                handCard(
                    hand: hand, spot: spot, handIdx: hi,
                    isActive: isActive && hi == spot.activeHandIndex
                )
            }
        }
    }

    @ViewBuilder
    private func handCard(hand: HandState, spot: SpotState, handIdx: Int, isActive: Bool) -> some View {
        let outcome = spot.outcomes[safe: handIdx]

        VStack(spacing: 6) {
            HStack(spacing: 6) {
                if !hand.cards.isEmpty {
                    Text("\(hand.total)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(hand.isBust ? .red : .cream)
                    if hand.isSoft      { Text("soft").font(.caption).foregroundColor(.muted) }
                    if hand.isBlackjack { Text("BLACKJACK").font(.caption2).foregroundColor(.gold).fontWeight(.bold) }
                }
                Spacer()
                if let outcome = outcome, spot.isComplete {
                    Text(outcome.display)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(outcome.color)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(outcome.color.opacity(0.15))
                        .cornerRadius(6)
                }
            }

            HStack {
                CardStack(cards: hand.cards, cardWidth: 54, cardHeight: 78)
                Spacer()
            }
        }
        .padding(10)
        .background(Color.feltDark.opacity(0.5))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isActive ? Color.gold : .clear, lineWidth: 2))
    }

    // MARK: - Controls

    private var controlsArea: some View {
        VStack(spacing: 10) {
            // Session stats + penetration bar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.0f%%", vm.sessionAccuracy))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.gold)
                    Text("\(vm.sessionCorrect)/\(vm.sessionTotal) correct")
                        .font(.caption)
                        .foregroundColor(.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    PenetrationBarView(
                        penetration: vm.shoe.penetration,
                        trigger: vm.shoe.penetrationTrigger
                    )
                    .frame(width: 110)
                    Text("\(vm.shoe.remainingCount) cards")
                        .font(.caption2)
                        .foregroundColor(.muted)
                }
            }
            .padding(12)
            .background(Color.feltDark.opacity(0.5))
            .cornerRadius(10)

            // Action buttons / deal button
            switch (vm.gameState.phase, vm.showCoaching) {
            case (.playerTurn, false):
                ActionButtonsView(available: vm.availableActions, onAction: vm.performAction)
            default:
                Button(action: {
                    guard !vm.showCoaching else { return }
                    vm.deal()
                }) {
                    Text(vm.gameState.phase == .roundOver ? "Next Hand ▶" : "Deal ▶")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.feltDark)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(vm.showCoaching ? Color.gold.opacity(0.4) : Color.gold)
                        .cornerRadius(10)
                }
                .disabled(vm.showCoaching)
            }
        }
    }
}

import SwiftUI
import SwiftData

struct GameView: View {
    @State private var vm = GameViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Felt background
            Theme.felt
                .overlay(feltGrain)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top: penetration bar
                PenetrationBarView(
                    penetration: vm.shoe.penetration,
                    remaining: vm.shoe.remainingCount,
                    trigger: vm.rules.penetrationPercent
                )
                .padding(.top, 8)

                Spacer()

                // Dealer hand
                DealerHandView(hand: vm.engine.dealerHand, phase: vm.engine.phase)

                Spacer()

                // Player spots
                if !vm.engine.spots.isEmpty {
                    PlayerSpotsView(
                        spots: vm.engine.spots,
                        activeSpotIndex: vm.engine.activeSpotIndex,
                        phase: vm.engine.phase
                    )
                } else {
                    idlePlaceholder
                }

                Spacer()

                // Session accuracy strip
                SessionAccuracyStripView(
                    correct: vm.sessionCorrect,
                    total: vm.sessionTotal,
                    accuracy: vm.sessionAccuracy
                )
                .padding(.bottom, 8)

                // Action buttons or Deal button
                bottomControls
                    .padding(.bottom, 24)
            }

            // Strategy reference button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        vm.showStrategyDrawer = true
                    } label: {
                        Image(systemName: "tablecells")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.gold)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(.trailing, Theme.padding)
                }
                .padding(.top, 52)
                Spacer()
            }

            // Coaching card overlay
            if vm.showCoachingCard, let entry = vm.coachingEntry {
                CoachingCardView(entry: entry) {
                    withAnimation(.spring()) {
                        vm.dismissCoachingCard()
                        if vm.engine.phase == .roundOver {
                            // auto-deal next round after dismissal
                        }
                    }
                }
                .zIndex(10)
                .transition(.opacity)
            }
        }
        .onAppear {
            vm.setModelContext(modelContext)
        }
        .sheet(isPresented: $vm.showStrategyDrawer) {
            StrategyReferenceDrawer(
                activeKey: vm.engine.activeHand?.handKey,
                dealerUpcard: vm.engine.dealerHand.cards.first,
                rules: vm.rules
            )
        }
        .animation(.easeInOut(duration: 0.2), value: vm.showCoachingCard)
    }

    // MARK: - Subviews

    private var feltGrain: some View {
        Canvas { context, size in
            // Subtle noise texture via tiny random dots
            let step: CGFloat = 4
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let opacity = Double.random(in: 0...0.03)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.white.opacity(opacity))
                    )
                    y += step
                }
                x += step
            }
        }
        .allowsHitTesting(false)
    }

    private var idlePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "suit.club.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.gold.opacity(0.4))
            Text("Tap Deal to begin")
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private var bottomControls: some View {
        if vm.engine.phase == .playerTurn {
            ActionButtonsView(
                available: vm.engine.availableActions,
                onAction: { category in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        vm.performAction(category)
                    }
                }
            )
        } else {
            // Deal / Next Hand button
            Button {
                withAnimation {
                    vm.dealNewRound()
                }
            } label: {
                Text(vm.engine.phase == .idle ? "Deal" : "Next Hand")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.buttonCornerRadius)
                            .fill(Theme.gold)
                    )
                    .foregroundColor(.black)
            }
            .padding(.horizontal, Theme.padding)
        }
    }
}

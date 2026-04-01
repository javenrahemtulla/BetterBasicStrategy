import SwiftUI

struct SettingsView: View {
    @Bindable var vm: GameViewModel
    @State private var localRules: RuleSet
    @State private var showResetConfirm = false
    @Environment(\.modelContext) private var modelContext

    init(vm: GameViewModel) {
        self.vm = vm
        self._localRules = State(initialValue: vm.rules)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.07, blue: 0.09).ignoresSafeArea()

                Form {
                    Section("DEALER RULES") {
                        Picker("Dealer Rule", selection: $localRules.dealerRule) {
                            ForEach(DealerRule.allCases, id: \.self) { rule in
                                Text(rule.rawValue).tag(rule)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(rowBackground)

                        Toggle("Double After Split (DAS)", isOn: $localRules.doubleAfterSplit)
                            .tint(Theme.gold)
                            .listRowBackground(rowBackground)

                        Toggle("Resplit Aces", isOn: $localRules.resplitAces)
                            .tint(Theme.gold)
                            .listRowBackground(rowBackground)
                    }
                    .listSectionSpacing(12)

                    Section("SURRENDER") {
                        Picker("Surrender", selection: $localRules.surrenderRule) {
                            ForEach(SurrenderRule.allCases, id: \.self) { rule in
                                Text(rule.rawValue).tag(rule)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(rowBackground)
                    }

                    Section("BLACKJACK PAYS") {
                        Picker("Blackjack Pays", selection: $localRules.blackjackPays) {
                            ForEach(BlackjackPays.allCases, id: \.self) { pays in
                                Text(pays.rawValue).tag(pays)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(rowBackground)
                        Text("Display only — no money involved")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                            .listRowBackground(rowBackground)
                    }

                    Section("GAME") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Spots")
                                Spacer()
                                Text("\(localRules.numberOfSpots)")
                                    .foregroundColor(Theme.gold)
                            }
                            Stepper("", value: $localRules.numberOfSpots, in: 1...3)
                                .labelsHidden()
                        }
                        .listRowBackground(rowBackground)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Penetration")
                                Spacer()
                                Text("\(Int(localRules.penetrationPercent * 100))%")
                                    .foregroundColor(Theme.gold)
                            }
                            Slider(value: $localRules.penetrationPercent, in: 0.5...0.85, step: 0.05)
                                .tint(Theme.gold)
                        }
                        .listRowBackground(rowBackground)

                        HStack {
                            Text("Decks")
                            Spacer()
                            Text("6 (fixed)")
                                .foregroundColor(Theme.textSecondary)
                        }
                        .listRowBackground(rowBackground)
                    }

                    Section {
                        Button("Apply & Reshuffle") {
                            vm.updateRules(localRules)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .listRowBackground(Theme.gold)

                        Button("Reset All Statistics", role: .destructive) {
                            showResetConfirm = true
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(rowBackground)
                    }
                }
                .scrollContentBackground(.hidden)
                .foregroundColor(Theme.textPrimary)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog(
            "Reset all statistics?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Statistics", role: .destructive) {
                resetStats()
            }
        } message: {
            Text("This will permanently delete all session and hand history. The shoe will not be affected.")
        }
    }

    private var rowBackground: some View {
        Color.white.opacity(0.05)
    }

    private func resetStats() {
        guard let sessions = try? modelContext.fetch(FetchDescriptor<GameSession>()) else { return }
        sessions.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

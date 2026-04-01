import SwiftUI

struct StrategyReferenceDrawer: View {
    let activeKey: HandKey?
    let dealerUpcard: Card?
    let rules: RuleSet

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Legend
                    legendRow
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    Divider().overlay(Color.white.opacity(0.1))

                    StrategyTableView(
                        rules: rules,
                        highlightKey: activeKey,
                        highlightDealer: dealerUpcard?.rank
                    )
                }
            }
            .navigationTitle("Basic Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.gold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var legendRow: some View {
        HStack(spacing: 12) {
            ForEach([DecisionCategory.hit, .stand, .double, .split, .surrender], id: \.self) { cat in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cat.themeColor)
                        .frame(width: 14, height: 14)
                    Text(cat.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

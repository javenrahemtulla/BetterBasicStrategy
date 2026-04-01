import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @State private var statsVM = StatsViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.07, blue: 0.09).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Summary cards
                        summarySection

                        // Streak
                        streakSection

                        // Accuracy by hand type
                        AccuracyChartsView(data: statsVM.accuracyByHandType)

                        // Dealer upcard heat map
                        DealerHeatMapView(cells: statsVM.accuracyByDealerUpcard)

                        // Mistakes
                        MistakeListView(mistakes: statsVM.topMistakes)

                        // Session history
                        sessionHistorySection
                    }
                    .padding(.horizontal, Theme.padding)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            statsVM.setModelContext(modelContext)
        }
    }

    // MARK: - Subviews

    private var summarySection: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "HANDS", value: "\(statsVM.lifetimeHands)")
            SummaryCard(title: "DECISIONS", value: "\(statsVM.lifetimeDecisions)")
            SummaryCard(
                title: "ACCURACY",
                value: "\(Int(statsVM.lifetimeAccuracy.rounded()))%",
                highlight: true
            )
        }
    }

    private var streakSection: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "CURRENT STREAK", value: "\(statsVM.currentStreak) ✓")
            SummaryCard(title: "LONGEST STREAK", value: "\(statsVM.longestStreak) ✓")
        }
    }

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECENT SESSIONS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .tracking(2)

            ForEach(statsVM.recentSessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.startedAt, style: .date)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("\(session.handsPlayed) hands")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(session.accuracyPercent.rounded()))%")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(accuracyColor(session.accuracyPercent))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
    }

    private func accuracyColor(_ pct: Double) -> Color {
        if pct >= 90 { return Theme.actionHit }
        if pct >= 70 { return Theme.gold }
        return Theme.actionStand
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(highlight ? Theme.gold : Theme.textPrimary)
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(highlight ? 0.08 : 0.05))
                .overlay(
                    highlight
                    ? RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1)
                    : nil
                )
        )
    }
}

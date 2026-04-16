import SwiftUI

struct StatsView: View {
    let user: BBSUser
    let onBack: () -> Void

    @StateObject private var vm = StatsViewModel()

    var body: some View {
        ZStack {
            Color.felt.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar.padding(.horizontal).padding(.top, 8).padding(.bottom, 6)

                Group {
                    if vm.isLoading {
                        Spacer(); ProgressView().tint(.gold); Spacer()
                    } else if let err = vm.error {
                        Spacer()
                        Text("Error: \(err)").foregroundColor(.red).padding().multilineTextAlignment(.center)
                        Button("Retry") { Task { await vm.load(userId: user.id) } }
                            .foregroundColor(.gold)
                        Spacer()
                    } else if let stats = vm.stats {
                        statsContent(stats)
                    } else {
                        Spacer()
                        Text("No data yet. Play some hands first!")
                            .foregroundColor(.muted).padding()
                        Spacer()
                    }
                }
            }
        }
        .task { await vm.load(userId: user.id) }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: onBack) {
                Label("Back", systemImage: "chevron.left").foregroundColor(.gold)
            }
            .font(.system(size: 15))

            Spacer()
            Text(user.username).font(.system(size: 14, weight: .semibold)).foregroundColor(.cream)
            Spacer()
            // Balance spacer
            Label("Back", systemImage: "chevron.left").opacity(0).font(.system(size: 15))
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func statsContent(_ s: StatsData) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryBar(s)

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 12) {
                        outcomesSection(s)
                        handTypeSection(s)
                    }
                    VStack(spacing: 12) {
                        dealerUpcardSection(s)
                        if !s.topMistakes.isEmpty { mistakesSection(s) }
                    }
                }

                if !s.recentSessions.isEmpty { recentSessionsSection(s) }
            }
            .padding()
        }
    }

    // MARK: - Summary bar

    private func summaryBar(_ s: StatsData) -> some View {
        HStack(spacing: 0) {
            StatCell(label: "Hands",    value: "\(s.lifetimeHands)")
            divider
            StatCell(label: "Accuracy", value: String(format: "%.1f%%", s.lifetimeAccuracy), highlight: true)
            divider
            StatCell(label: "Streak",   value: "\(s.currentStreak)")
            divider
            StatCell(label: "Best",     value: "\(s.longestStreak)")
            divider
            StatCell(label: "Shoes",    value: "\(s.shoesPlayed)")
        }
        .background(Color.feltDark)
        .cornerRadius(10)
    }

    private var divider: some View {
        Rectangle().fill(Color.felt).frame(width: 1).padding(.vertical, 8)
    }

    // MARK: - Sections

    private func outcomesSection(_ s: StatsData) -> some View {
        StatsSection(title: "Outcomes") {
            VStack(spacing: 5) {
                OutcomeRow(label: "Win",       value: s.outcomeCounts.wins,       color: .green)
                OutcomeRow(label: "Blackjack", value: s.outcomeCounts.blackjacks, color: .gold)
                OutcomeRow(label: "Push",      value: s.outcomeCounts.pushes,     color: .muted)
                OutcomeRow(label: "Surrender", value: s.outcomeCounts.surrenders, color: .surrenderPurple)
                OutcomeRow(label: "Loss",      value: s.outcomeCounts.losses,     color: .red)
            }
        }
    }

    private func handTypeSection(_ s: StatsData) -> some View {
        StatsSection(title: "By Hand Type") {
            VStack(spacing: 8) {
                ForEach(s.accuracyByHandType) { item in
                    VStack(spacing: 3) {
                        HStack {
                            Text(item.label).font(.system(size: 13)).foregroundColor(.cream)
                            Spacer()
                            Text(item.total > 0 ? String(format: "%.0f%%", item.accuracy) : "—")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(accuracyColor(item.accuracy))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.felt).frame(height: 6)
                                if item.total > 0 {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(accuracyColor(item.accuracy))
                                        .frame(width: geo.size.width * item.accuracy / 100, height: 6)
                                }
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }

    private func dealerUpcardSection(_ s: StatsData) -> some View {
        StatsSection(title: "By Dealer Upcard") {
            let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(s.accuracyByDealerUpcard) { item in
                    VStack(spacing: 2) {
                        Text(item.rank).font(.caption).foregroundColor(.muted)
                        Text(item.total > 0 ? String(format: "%.0f", item.accuracy) : "—")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(item.total > 0 ? accuracyColor(item.accuracy) : .muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(item.total > 0 ? accuracyColor(item.accuracy).opacity(0.15) : .clear)
                    .cornerRadius(4)
                }
            }
        }
    }

    private func mistakesSection(_ s: StatsData) -> some View {
        StatsSection(title: "Top Mistakes") {
            VStack(spacing: 4) {
                ForEach(s.topMistakes.prefix(8)) { m in
                    HStack {
                        Text(m.label).font(.system(size: 11)).foregroundColor(.cream)
                        Spacer()
                        Text("×\(m.count)").font(.caption2).foregroundColor(.red)
                        Text(m.correctAction).font(.caption2).foregroundColor(.gold)
                    }
                }
            }
        }
    }

    private func recentSessionsSection(_ s: StatsData) -> some View {
        StatsSection(title: "Recent Sessions") {
            VStack(spacing: 6) {
                ForEach(s.recentSessions.prefix(10)) { session in
                    HStack {
                        Text(fmtDate(session.startedAt)).font(.caption).foregroundColor(.muted)
                        Spacer()
                        Text("\(session.handsPlayed) hands").font(.caption).foregroundColor(.cream)
                        Text(String(format: "%.0f%%", session.accuracy))
                            .font(.caption)
                            .foregroundColor(accuracyColor(session.accuracy))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func accuracyColor(_ pct: Double) -> Color {
        pct >= 90 ? .green : pct >= 70 ? .gold : .red
    }

    private func fmtDate(_ iso: String) -> String {
        let isoFmt = ISO8601DateFormatter()
        guard let date = isoFmt.date(from: iso) else { return iso }
        let fmt = DateFormatter(); fmt.dateStyle = .short
        return fmt.string(from: date)
    }
}

// MARK: - Sub-views

private struct StatCell: View {
    let label: String; let value: String; var highlight = false
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: highlight ? 20 : 17, weight: .bold))
                .foregroundColor(highlight ? .gold : .cream)
            Text(label).font(.caption2).foregroundColor(.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
    }
}

private struct OutcomeRow: View {
    let label: String; let value: Int; let color: Color
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.cream)
            Spacer()
            Text("\(value)").font(.system(size: 13, weight: .semibold)).foregroundColor(color)
        }
    }
}

private struct StatsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.muted)
                .textCase(.uppercase)
                .tracking(0.8)
            content()
        }
        .padding(12)
        .background(Color.feltDark)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
}

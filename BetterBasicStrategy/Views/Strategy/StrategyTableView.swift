import SwiftUI

struct StrategyTableView: View {
    let rules: RuleSet
    let highlightKey: HandKey?
    let highlightDealer: Rank?

    private let table: StrategyTableMap
    private let dealerRanks: [Rank] = [.two,.three,.four,.five,.six,.seven,.eight,.nine,.ten,.ace]

    init(rules: RuleSet, highlightKey: HandKey? = nil, highlightDealer: Rank? = nil) {
        self.rules = rules
        self.highlightKey = highlightKey
        self.highlightDealer = highlightDealer?.strategyRank
        self.table = StrategyTable.build(rules: rules)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                sectionView(title: "HARD TOTALS", keys: hardKeys)
                sectionSpacer
                sectionView(title: "SOFT TOTALS", keys: softKeys)
                sectionSpacer
                sectionView(title: "PAIRS", keys: pairKeys)
            }
            .padding(8)
        }
    }

    // MARK: - Sections

    private var hardKeys: [HandKey] { (5...21).map { .hard($0) } }
    private var softKeys: [HandKey] { (13...20).map { .soft($0) } }
    private var pairKeys: [HandKey] {
        [Rank.two,.three,.four,.five,.six,.seven,.eight,.nine,.ten,.ace].map { .pair($0) }
    }

    private func sectionView(title: String, keys: [HandKey]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .tracking(2)
                .padding(.vertical, 6)

            // Header row
            HStack(spacing: 1) {
                headerCell(text: "")
                ForEach(dealerRanks, id: \.self) { rank in
                    headerCell(text: rank.symbol)
                }
            }

            ForEach(keys, id: \.self) { key in
                HStack(spacing: 1) {
                    rowLabelCell(key: key)
                    ForEach(dealerRanks, id: \.self) { dealer in
                        tableCell(key: key, dealer: dealer)
                    }
                }
            }
        }
    }

    private var sectionSpacer: some View {
        Color.clear.frame(height: 12)
    }

    // MARK: - Cells

    private func headerCell(text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Theme.textSecondary)
            .frame(width: text.isEmpty ? 36 : 28, height: 22)
            .background(Color.white.opacity(0.05))
    }

    private func rowLabelCell(key: HandKey) -> some View {
        Text(rowLabel(key))
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Theme.textPrimary)
            .frame(width: 36, height: 22)
            .background(Color.white.opacity(0.07))
    }

    private func tableCell(key: HandKey, dealer: Rank) -> some View {
        let entry = table[key]?[dealer.strategyRank]
        let action = entry?.action
        let category = action?.primaryDecisionCategory ?? .hit
        let isHighlighted = key == highlightKey && dealer.strategyRank == highlightDealer

        return Text(cellLabel(action))
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 28, height: 22)
            .background(category.themeColor.opacity(isHighlighted ? 1.0 : 0.75))
            .overlay(
                isHighlighted
                ? RoundedRectangle(cornerRadius: 2).strokeBorder(.white, lineWidth: 2)
                : nil
            )
            .scaleEffect(isHighlighted ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: isHighlighted)
    }

    // MARK: - Labels

    private func rowLabel(_ key: HandKey) -> String {
        switch key {
        case .hard(let n): return "\(n)"
        case .soft(let n): return "A\(n-11)"
        case .pair(let r): return "\(r.symbol)\(r.symbol)"
        }
    }

    private func cellLabel(_ action: Action?) -> String {
        switch action {
        case .hit: return "H"
        case .stand: return "S"
        case .doubleOrHit, .doubleOrStand: return "D"
        case .split: return "SP"
        case .surrenderOrHit, .surrenderOrStand, .surrenderOrSplit: return "R"
        case .none: return "H"
        }
    }
}

extension HandKey: Hashable {
    static func == (lhs: HandKey, rhs: HandKey) -> Bool {
        switch (lhs, rhs) {
        case (.hard(let a), .hard(let b)): return a == b
        case (.soft(let a), .soft(let b)): return a == b
        case (.pair(let a), .pair(let b)): return a == b
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .hard(let n): hasher.combine(0); hasher.combine(n)
        case .soft(let n): hasher.combine(1); hasher.combine(n)
        case .pair(let r): hasher.combine(2); hasher.combine(r)
        }
    }
}

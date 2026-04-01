import SwiftUI

struct DealerHeatMapView: View {
    let cells: [DealerHeatCell]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCURACY BY DEALER UPCARD")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .tracking(2)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(cells) { cell in
                    VStack(spacing: 2) {
                        Text(cell.dealerRank)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(Int(cell.accuracy.rounded()))%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        Text("\(cell.sampleSize)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(heatColor(cell.accuracy, sampleSize: cell.sampleSize))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func heatColor(_ pct: Double, sampleSize: Int) -> Color {
        guard sampleSize > 0 else {
            return Color.white.opacity(0.06)
        }
        // Interpolate red→yellow→green across 0–100%
        if pct >= 90 { return Theme.actionHit.opacity(0.8) }
        if pct >= 70 { return Theme.gold.opacity(0.7) }
        return Theme.actionStand.opacity(0.7)
    }
}

import SwiftUI

struct SessionAccuracyStripView: View {
    let correct: Int
    let total: Int
    let accuracy: Double

    var body: some View {
        HStack(spacing: 16) {
            StatPill(label: "SESSION", value: "\(Int(accuracy.rounded()))%",
                     color: accuracyColor(accuracy))
            StatPill(label: "CORRECT", value: "\(correct)", color: Theme.actionHit)
            StatPill(label: "HANDS", value: "\(total)", color: Theme.textSecondary)
        }
        .padding(.horizontal, Theme.padding)
    }

    private func accuracyColor(_ pct: Double) -> Color {
        if pct >= 90 { return Theme.actionHit }
        if pct >= 70 { return Theme.gold }
        return Theme.actionStand
    }
}

private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

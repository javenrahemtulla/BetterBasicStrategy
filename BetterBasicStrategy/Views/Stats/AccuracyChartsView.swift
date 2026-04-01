import SwiftUI
import Charts

struct AccuracyChartsView: View {
    let data: [AccuracyByCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCURACY BY HAND TYPE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .tracking(2)

            Chart(data) { item in
                BarMark(
                    x: .value("Accuracy", item.accuracy),
                    y: .value("Type", item.label)
                )
                .foregroundStyle(barColor(item.accuracy))
                .annotation(position: .trailing) {
                    Text("\(Int(item.accuracy.rounded()))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                .cornerRadius(4)
            }
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { val in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel {
                        Text("\(val.as(Int.self) ?? 0)%")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        Text(val.as(String.self) ?? "")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .frame(height: CGFloat(data.count) * 50)
            .padding(.trailing, 40)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func barColor(_ pct: Double) -> Color {
        if pct >= 90 { return Theme.actionHit }
        if pct >= 70 { return Theme.gold }
        return Theme.actionStand
    }
}

import SwiftUI

struct MistakeListView: View {
    let mistakes: [MistakeEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOP MISTAKES")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .tracking(2)

            if mistakes.isEmpty {
                Text("No mistakes yet — keep it up!")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(mistakes.enumerated()), id: \.element.id) { idx, mistake in
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(mistake.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Text("Should: \(mistake.correctAction)")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.gold)
                        }

                        Spacer()

                        Text("\(mistake.count)×")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.actionStand)
                    }
                    .padding(.vertical, 6)

                    if idx < mistakes.count - 1 {
                        Divider().overlay(Color.white.opacity(0.08))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

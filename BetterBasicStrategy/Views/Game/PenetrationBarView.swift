import SwiftUI

struct PenetrationBarView: View {
    let penetration: Double   // 0.0–1.0
    let remaining: Int
    let trigger: Double

    private var barColor: Color {
        if penetration >= trigger { return .red }
        if penetration >= trigger - 0.1 { return .orange }
        return Theme.gold
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * penetration)
                    // Trigger marker
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1.5)
                        .offset(x: geo.size.width * trigger - 0.75)
                }
            }
            .frame(height: 6)

            HStack {
                Text("SHOE")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(remaining) cards")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, Theme.padding)
    }
}

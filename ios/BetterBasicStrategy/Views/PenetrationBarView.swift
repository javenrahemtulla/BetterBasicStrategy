import SwiftUI

struct PenetrationBarView: View {
    let penetration: Double  // 0.0 – 1.0
    let trigger: Double      // reshuffle marker position

    private var barColor: Color {
        penetration > trigger * 0.9 ? .red.opacity(0.8) : .gold
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.feltDark).frame(height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: max(0, geo.size.width * min(penetration, 1.0)), height: 10)
                    .animation(.linear(duration: 0.3), value: penetration)

                // Reshuffle trigger marker
                Rectangle()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 2, height: 16)
                    .offset(x: geo.size.width * trigger - 1, y: -3)
            }
        }
        .frame(height: 10)
    }
}

import SwiftUI

struct CoachingCardView: View {
    let entry: StrategyEntry
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    Text("Incorrect")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Correct play: \(actionCategory(entry.action).display)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gold)

                    Text(entry.explanation)
                        .font(.system(size: 14))
                        .foregroundColor(.cream)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.feltDark)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.gold)
                        .cornerRadius(8)
                }
            }
            .padding(24)
            .background(Color.feltDark)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gold.opacity(0.5), lineWidth: 1))
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
    }
}

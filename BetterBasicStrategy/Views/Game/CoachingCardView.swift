import SwiftUI

struct CoachingCardView: View {
    let entry: StrategyEntry
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Theme.gold)
                    Text("CORRECT PLAY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .tracking(2)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Text(entry.action.displayName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(entry.explanation)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.gold))
                        .foregroundColor(.black)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .onTapGesture { onDismiss() }
    }
}

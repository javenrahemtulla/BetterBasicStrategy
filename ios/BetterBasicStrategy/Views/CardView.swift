import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceDown = false
    var width: CGFloat  = 56
    var height: CGFloat = 80

    private var fontSize: CGFloat { max(10, width * 0.22) }
    private var suitSize: CGFloat { max(14, width * 0.35) }
    private var redColor:   Color { Color(hex: "#c0392b") }
    private var blackColor: Color { Color(hex: "#1a1a1a") }

    var body: some View {
        ZStack {
            if isFaceDown { holeCard } else { faceCard }
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)
    }

    private var holeCard: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(LinearGradient(colors: [.holeCardTop, .holeCardBot], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .overlay(
                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: width * 0.55, height: 2)
                    }
                }
            )
    }

    private var faceCard: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.cardFace)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))
            .overlay(
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 1) {
                        Text(card.displayRank).font(.system(size: fontSize, weight: .bold))
                        Text(card.suitSymbol).font(.system(size: max(8, width * 0.18)))
                    }
                    .foregroundColor(card.isRed ? redColor : blackColor)
                    .padding([.top, .leading], 4)

                    Spacer()

                    Text(card.suitSymbol)
                        .font(.system(size: suitSize))
                        .foregroundColor(card.isRed ? redColor : blackColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                }
            )
    }
}

struct CardStack: View {
    let cards: [Card]
    var holeRevealed = true
    var cardWidth: CGFloat  = 56
    var cardHeight: CGFloat = 80

    var body: some View {
        HStack(spacing: -cardWidth * 0.28) {
            ForEach(Array(cards.enumerated()), id: \.offset) { idx, card in
                CardView(
                    card: card,
                    isFaceDown: (idx == 1 && !holeRevealed),
                    width: cardWidth, height: cardHeight
                )
                .zIndex(Double(idx))
            }
        }
    }
}

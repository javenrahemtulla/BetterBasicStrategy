import SwiftUI

struct CardView: View {
    let card: Card?        // nil = face down
    var width: CGFloat = 60
    var height: CGFloat = 84

    private var isFaceDown: Bool { card == nil }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(isFaceDown ? Color(red: 0.14, green: 0.32, blue: 0.55) : Theme.cardFace)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 4, x: 2, y: 3)

            if isFaceDown {
                // Back pattern
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius - 3)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 2)
                    .padding(5)
            } else if let card = card {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: -2) {
                            Text(card.rank.symbol)
                                .font(Theme.cardRank(size: width * 0.28))
                                .foregroundColor(card.suit.isRed ? .red : .black)
                            Text(card.suit.rawValue)
                                .font(Theme.cardSuit(size: width * 0.22))
                                .foregroundColor(card.suit.isRed ? .red : .black)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 5)
                    .padding(.top, 4)

                    Spacer()

                    // Center pip
                    Text(card.suit.rawValue)
                        .font(Theme.cardSuit(size: width * 0.45))
                        .foregroundColor(card.suit.isRed ? Color.red.opacity(0.6) : Color.black.opacity(0.4))

                    Spacer()

                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: -2) {
                            Text(card.suit.rawValue)
                                .font(Theme.cardSuit(size: width * 0.22))
                                .foregroundColor(card.suit.isRed ? .red : .black)
                            Text(card.rank.symbol)
                                .font(Theme.cardRank(size: width * 0.28))
                                .foregroundColor(card.suit.isRed ? .red : .black)
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.bottom, 4)
                    .rotationEffect(.degrees(180))
                }
            }
        }
        .frame(width: width, height: height)
    }
}

struct CardStack: View {
    let cards: [Card?]   // nil entries are face-down
    var cardWidth: CGFloat = 60
    var cardHeight: CGFloat = 84
    var overlap: CGFloat = 22

    var body: some View {
        let totalWidth = cardWidth + CGFloat(max(cards.count - 1, 0)) * overlap
        ZStack(alignment: .leading) {
            ForEach(Array(cards.enumerated()), id: \.offset) { idx, card in
                CardView(card: card, width: cardWidth, height: cardHeight)
                    .offset(x: CGFloat(idx) * overlap)
            }
        }
        .frame(width: totalWidth, height: cardHeight)
    }
}

#Preview {
    HStack {
        CardView(card: Card(suit: .hearts, rank: .ace), width: 70, height: 98)
        CardView(card: Card(suit: .spades, rank: .king), width: 70, height: 98)
        CardView(card: nil, width: 70, height: 98)
    }
    .padding()
    .background(Theme.felt)
}

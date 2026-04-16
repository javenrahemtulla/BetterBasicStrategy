import SwiftUI

extension Color {
    static let felt         = Color(hex: "#0f3818")
    static let feltDark     = Color(hex: "#0a2810")
    static let cream        = Color(hex: "#f9f5e3")
    static let gold         = Color(hex: "#b89a4d")
    static let goldBright   = Color(hex: "#c9a84c")
    static let muted        = Color(hex: "#a09880")
    static let hitGreen     = Color(hex: "#1a6627")
    static let standRed     = Color(hex: "#8b1a1a")
    static let doubleBlue   = Color(hex: "#1a3f8a")
    static let splitBrown   = Color(hex: "#7a4d0a")
    static let surrenderPurple = Color(hex: "#4a1f6e")
    static let cardFace     = Color(hex: "#f9f5e3")
    static let cardBorder   = Color(hex: "#d4ceb8")
    static let holeCardTop  = Color(hex: "#1a4a8a")
    static let holeCardBot  = Color(hex: "#0d2d5a")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

extension DecisionCategory {
    var color: Color {
        switch self {
        case .hit:       return .hitGreen
        case .stand:     return .standRed
        case .double:    return .doubleBlue
        case .split:     return .splitBrown
        case .surrender: return .surrenderPurple
        }
    }
}

extension Outcome {
    var color: Color {
        switch self {
        case .win, .blackjack: return .green
        case .lose, .bust:     return .red
        case .push:            return .muted
        case .surrender:       return .surrenderPurple
        }
    }
}

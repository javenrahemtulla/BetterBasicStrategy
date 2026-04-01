import SwiftUI

enum Theme {
    // MARK: - Colors
    static let felt = Color(red: 0.06, green: 0.22, blue: 0.10)
    static let feltGrain = Color(red: 0.07, green: 0.24, blue: 0.11)
    static let cardFace = Color(red: 0.98, green: 0.96, blue: 0.88)
    static let cardBorder = Color(red: 0.85, green: 0.83, blue: 0.76)
    static let gold = Color(red: 0.72, green: 0.60, blue: 0.30)
    static let goldDim = Color(red: 0.50, green: 0.42, blue: 0.21)
    static let textPrimary = Color(red: 0.95, green: 0.92, blue: 0.85)
    static let textSecondary = Color(red: 0.65, green: 0.62, blue: 0.55)

    // Action button colors
    static let actionHit = Color(red: 0.20, green: 0.55, blue: 0.25)
    static let actionStand = Color(red: 0.70, green: 0.18, blue: 0.18)
    static let actionDouble = Color(red: 0.15, green: 0.40, blue: 0.72)
    static let actionSplit = Color(red: 0.65, green: 0.42, blue: 0.10)
    static let actionSurrender = Color(red: 0.40, green: 0.20, blue: 0.55)

    // Strategy table cell colors
    static let cellHit = Color(red: 0.18, green: 0.48, blue: 0.22)
    static let cellStand = Color(red: 0.60, green: 0.15, blue: 0.15)
    static let cellDouble = Color(red: 0.12, green: 0.35, blue: 0.65)
    static let cellSplit = Color(red: 0.58, green: 0.38, blue: 0.08)
    static let cellSurrender = Color(red: 0.35, green: 0.18, blue: 0.50)

    // MARK: - Fonts
    static func cardRank(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size)
    }
    static func cardSuit(size: CGFloat) -> Font {
        .custom("Georgia", size: size)
    }
    static func ui(_ style: Font.TextStyle) -> Font {
        .system(style, design: .rounded)
    }

    // MARK: - Metrics
    static let cardCornerRadius: CGFloat = 10
    static let buttonCornerRadius: CGFloat = 14
    static let padding: CGFloat = 16
}

extension DecisionCategory {
    var themeColor: Color {
        switch self {
        case .hit: return Theme.cellHit
        case .stand: return Theme.cellStand
        case .double: return Theme.cellDouble
        case .split: return Theme.cellSplit
        case .surrender: return Theme.cellSurrender
        }
    }

    var buttonColor: Color {
        switch self {
        case .hit: return Theme.actionHit
        case .stand: return Theme.actionStand
        case .double: return Theme.actionDouble
        case .split: return Theme.actionSplit
        case .surrender: return Theme.actionSurrender
        }
    }
}

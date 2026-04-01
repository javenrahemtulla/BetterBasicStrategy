import Foundation

enum DealerRule: String, Codable, CaseIterable {
    case h17 = "H17"  // Dealer hits soft 17
    case s17 = "S17"  // Dealer stands on soft 17
}

enum SurrenderRule: String, Codable, CaseIterable {
    case none = "None"
    case late = "Late"
    case early = "Early"
}

enum BlackjackPays: String, Codable, CaseIterable {
    case threeToTwo = "3:2"
    case sixToFive = "6:5"
}

struct RuleSet: Codable, Equatable {
    var dealerRule: DealerRule = .h17
    var doubleAfterSplit: Bool = true
    var resplitAces: Bool = false
    var surrenderRule: SurrenderRule = .late
    var blackjackPays: BlackjackPays = .threeToTwo
    var numberOfSpots: Int = 1
    var penetrationPercent: Double = 0.75  // Reshuffle trigger
    let numberOfDecks: Int = 6             // Locked per spec

    static let `default` = RuleSet()
}

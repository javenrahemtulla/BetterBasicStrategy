import Foundation

/// Raw strategy table action — may be compound (fallback if primary unavailable)
enum Action: String, Codable, Equatable {
    case hit
    case stand
    case doubleOrHit    // Double if allowed, else Hit
    case doubleOrStand  // Double if allowed, else Stand
    case split
    case surrenderOrHit
    case surrenderOrStand
    case surrenderOrSplit

    /// Display name for coaching card and buttons
    var displayName: String {
        switch self {
        case .hit: return "Hit"
        case .stand: return "Stand"
        case .doubleOrHit, .doubleOrStand: return "Double"
        case .split: return "Split"
        case .surrenderOrHit, .surrenderOrStand, .surrenderOrSplit: return "Surrender"
        }
    }

    /// Resolved concrete action given what's available right now
    func resolved(canDouble: Bool, canSplit: Bool, canSurrender: Bool) -> Action {
        switch self {
        case .doubleOrHit: return canDouble ? .doubleOrHit : .hit
        case .doubleOrStand: return canDouble ? .doubleOrStand : .stand
        case .surrenderOrHit: return canSurrender ? .surrenderOrHit : .hit
        case .surrenderOrStand: return canSurrender ? .surrenderOrStand : .stand
        case .surrenderOrSplit: return canSurrender ? .surrenderOrSplit : (canSplit ? .split : .hit)
        default: return self
        }
    }

    /// The "primary" decision for comparison — ignores fallback variant
    var primaryDecisionCategory: DecisionCategory {
        switch self {
        case .hit: return .hit
        case .stand: return .stand
        case .doubleOrHit, .doubleOrStand: return .double
        case .split: return .split
        case .surrenderOrHit, .surrenderOrStand, .surrenderOrSplit: return .surrender
        }
    }
}

enum DecisionCategory: String, Codable {
    case hit, stand, double, split, surrender

    var displayName: String { rawValue.capitalized }

    /// Color code for strategy table cells
    var colorToken: String {
        switch self {
        case .hit: return "actionHit"
        case .stand: return "actionStand"
        case .double: return "actionDouble"
        case .split: return "actionSplit"
        case .surrender: return "actionSurrender"
        }
    }
}

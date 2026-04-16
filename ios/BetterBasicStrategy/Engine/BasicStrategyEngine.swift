import Foundation

class BasicStrategyEngine {
    private let table: StrategyTableMap

    init(rules: RuleSet = RuleSet()) {
        table = buildStrategyTable(rules: rules)
    }

    func getEntry(handKey: HandKey, dealerUpcard: Card) -> StrategyEntry? {
        lookupEntry(table: table, handKey: handKey, dealerStrategyRank: dealerUpcard.strategyRank)
    }

    func correctAction(handKey: HandKey, dealerUpcard: Card) -> RawAction {
        getEntry(handKey: handKey, dealerUpcard: dealerUpcard)?.action ?? .hit
    }

    func explanation(handKey: HandKey, dealerUpcard: Card) -> String {
        getEntry(handKey: handKey, dealerUpcard: dealerUpcard)?.explanation ?? "Hit when in doubt."
    }
}

func resolveAction(_ raw: RawAction, canDouble: Bool, canSplit: Bool, canSurrender: Bool) -> RawAction {
    switch raw {
    case .doubleOrHit:      return canDouble    ? .doubleOrHit    : .hit
    case .doubleOrStand:    return canDouble    ? .doubleOrStand   : .stand
    case .surrenderOrHit:   return canSurrender ? .surrenderOrHit  : .hit
    case .surrenderOrStand: return canSurrender ? .surrenderOrStand : .stand
    case .surrenderOrSplit: return canSurrender ? .surrenderOrSplit : (canSplit ? .split : .hit)
    default: return raw
    }
}

func actionCategory(_ raw: RawAction) -> DecisionCategory {
    switch raw {
    case .hit:                                                    return .hit
    case .stand:                                                  return .stand
    case .doubleOrHit, .doubleOrStand:                            return .double
    case .split:                                                  return .split
    case .surrenderOrHit, .surrenderOrStand, .surrenderOrSplit:   return .surrender
    }
}

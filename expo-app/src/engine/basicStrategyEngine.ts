import type { Card, DecisionCategory, HandKey, RawAction, RuleSet, StrategyEntry } from '../types'
import { strategyRank } from './card'
import { buildStrategyTable, lookupEntry } from './strategyTable'
import type { StrategyTableMap } from '../types'

export class BasicStrategyEngine {
  private table: StrategyTableMap

  constructor(rules: RuleSet) {
    this.table = buildStrategyTable(rules)
  }

  getEntry(handKey: HandKey, dealerUpcard: Card): StrategyEntry | undefined {
    const dr = strategyRank(dealerUpcard.rank)
    return lookupEntry(this.table, handKey as { type: string; total?: number; rank?: number }, dr)
  }

  correctAction(handKey: HandKey, dealerUpcard: Card): RawAction {
    return this.getEntry(handKey, dealerUpcard)?.action ?? 'hit'
  }

  explanation(handKey: HandKey, dealerUpcard: Card): string {
    return this.getEntry(handKey, dealerUpcard)?.explanation ?? 'Hit when in doubt.'
  }
}

export function resolveAction(
  raw: RawAction, canDouble: boolean, canSplit: boolean, canSurrender: boolean
): RawAction {
  switch (raw) {
    case 'doubleOrHit':      return canDouble    ? 'doubleOrHit'    : 'hit'
    case 'doubleOrStand':    return canDouble    ? 'doubleOrStand'   : 'stand'
    case 'surrenderOrHit':   return canSurrender ? 'surrenderOrHit'  : 'hit'
    case 'surrenderOrStand': return canSurrender ? 'surrenderOrStand' : 'stand'
    case 'surrenderOrSplit': return canSurrender ? 'surrenderOrSplit' : (canSplit ? 'split' : 'hit')
    default: return raw
  }
}

export function actionCategory(raw: RawAction): DecisionCategory {
  switch (raw) {
    case 'hit':                                                    return 'hit'
    case 'stand':                                                  return 'stand'
    case 'doubleOrHit': case 'doubleOrStand':                      return 'double'
    case 'split':                                                  return 'split'
    case 'surrenderOrHit': case 'surrenderOrStand': case 'surrenderOrSplit': return 'surrender'
  }
}

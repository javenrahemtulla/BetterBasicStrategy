import type { Card, HandKey, HandState, HandType } from '@/lib/types'
import { rankValue, strategyRank } from './card'

export function calcTotal(cards: Card[]): { total: number; isSoft: boolean } {
  let sum = 0
  let aces = 0
  for (const card of cards) {
    const v = rankValue(card.rank)
    if (card.rank === 14) aces++
    sum += v
  }
  let reduced = 0
  while (sum > 21 && reduced < aces) {
    sum -= 10
    reduced++
  }
  const isSoft = reduced < aces // at least one ace still counting as 11
  return { total: sum, isSoft }
}

export function getHandKey(cards: Card[]): HandKey {
  const { total, isSoft } = calcTotal(cards)

  // Pair: exactly 2 cards, same strategy rank
  if (cards.length === 2) {
    const r1 = strategyRank(cards[0].rank)
    const r2 = strategyRank(cards[1].rank)
    if (r1 === r2) return { type: 'pair', rank: r1 }
  }

  if (isSoft && total >= 13 && total <= 21) {
    return { type: 'soft', total }
  }
  return { type: 'hard', total }
}

export function handKeyString(key: HandKey): string {
  if (key.type === 'hard') return `hard-${key.total}`
  if (key.type === 'soft') return `soft-${key.total}`
  return `pair-${key.rank}`
}

export function getHandType(cards: Card[]): HandType {
  const key = getHandKey(cards)
  return key.type
}

export function buildHandState(cards: Card[]): HandState {
  const { total, isSoft } = calcTotal(cards)
  return {
    cards,
    total,
    isSoft,
    isBust: total > 21,
    isBlackjack: cards.length === 2 && total === 21,
    handType: getHandType(cards),
    handKey: getHandKey(cards),
  }
}

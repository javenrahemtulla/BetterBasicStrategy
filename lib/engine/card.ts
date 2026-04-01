import type { Card, Rank, Suit } from '@/lib/types'

export const SUITS: Suit[] = ['hearts', 'diamonds', 'clubs', 'spades']
export const RANKS: Rank[] = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

export function rankValue(rank: Rank): number {
  if (rank === 14) return 11   // Ace
  if (rank >= 11) return 10    // J/Q/K
  return rank
}

export function strategyRank(rank: Rank): number {
  if (rank >= 11 && rank <= 13) return 10  // J/Q/K → 10
  return rank
}

export function rankSymbol(rank: Rank): string {
  if (rank === 14) return 'A'
  if (rank === 13) return 'K'
  if (rank === 12) return 'Q'
  if (rank === 11) return 'J'
  return String(rank)
}

export function suitSymbol(suit: Suit): string {
  const map = { hearts: '♥', diamonds: '♦', clubs: '♣', spades: '♠' }
  return map[suit]
}

export function isRed(suit: Suit): boolean {
  return suit === 'hearts' || suit === 'diamonds'
}

export function cardLabel(card: Card): string {
  return `${rankSymbol(card.rank)}${suitSymbol(card.suit)}`
}

let _idCounter = 0
export function makeCard(suit: Suit, rank: Rank): Card {
  return { suit, rank, id: `${suit}-${rank}-${_idCounter++}` }
}

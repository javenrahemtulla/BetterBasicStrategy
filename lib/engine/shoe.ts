import type { Card } from '@/lib/types'
import { SUITS, RANKS, makeCard } from './card'

const STORAGE_KEY = 'bbs_shoe'

export interface ShoeState {
  cards: Card[]
  currentIndex: number
  penetrationTrigger: number
}

export function createShoe(penetrationTrigger = 0.75): ShoeState {
  const deck: Card[] = []
  for (let i = 0; i < 6; i++) {
    for (const suit of SUITS) {
      for (const rank of RANKS) {
        deck.push(makeCard(suit, rank))
      }
    }
  }
  // Fisher-Yates shuffle
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[deck[i], deck[j]] = [deck[j], deck[i]]
  }
  return { cards: deck, currentIndex: 0, penetrationTrigger }
}

export function dealCard(shoe: ShoeState): { card: Card; shoe: ShoeState } | null {
  if (shoe.currentIndex >= shoe.cards.length) return null
  const card = shoe.cards[shoe.currentIndex]
  return {
    card,
    shoe: { ...shoe, currentIndex: shoe.currentIndex + 1 },
  }
}

export function needsReshuffle(shoe: ShoeState): boolean {
  const penetration = shoe.currentIndex / shoe.cards.length
  return penetration >= shoe.penetrationTrigger || shoe.currentIndex >= shoe.cards.length
}

export function penetration(shoe: ShoeState): number {
  return shoe.cards.length > 0 ? shoe.currentIndex / shoe.cards.length : 0
}

export function remainingCount(shoe: ShoeState): number {
  return shoe.cards.length - shoe.currentIndex
}

// ─── localStorage persistence ─────────────────────────────────────────────────

export function saveShoe(shoe: ShoeState): void {
  if (typeof window === 'undefined') return
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(shoe))
  } catch { /* quota exceeded */ }
}

export function loadShoe(penetrationTrigger = 0.75): ShoeState {
  if (typeof window === 'undefined') return createShoe(penetrationTrigger)
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const state = JSON.parse(raw) as ShoeState
      if (state.cards?.length === 312) return state
    }
  } catch { /* ignore */ }
  return createShoe(penetrationTrigger)
}

export function clearShoe(): void {
  if (typeof window === 'undefined') return
  localStorage.removeItem(STORAGE_KEY)
}

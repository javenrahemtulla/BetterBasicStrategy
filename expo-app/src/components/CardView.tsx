import React from 'react'
import { View, Text, StyleSheet } from 'react-native'
import type { Card } from '../types'
import { Colors } from '../theme'

const SUIT_SYMBOL: Record<string, string> = { hearts: '♥', diamonds: '♦', clubs: '♣', spades: '♠' }
const RED_SUITS = new Set(['hearts', 'diamonds'])

function rankLabel(rank: number): string {
  if (rank === 14) return 'A'
  if (rank === 13) return 'K'
  if (rank === 12) return 'Q'
  if (rank === 11) return 'J'
  return String(rank)
}

interface CardViewProps {
  card: Card
  small?: boolean
}

export function CardView({ card, small }: CardViewProps) {
  const isRed = RED_SUITS.has(card.suit)
  const color = isRed ? Colors.cardRed : Colors.cardBlack
  const label = rankLabel(card.rank)
  const suit  = SUIT_SYMBOL[card.suit]

  return (
    <View style={[styles.card, small && styles.cardSmall]}>
      <Text style={[styles.cornerLabel, { color }, small && styles.cornerLabelSmall]}>{label}{suit}</Text>
      <Text style={[styles.center, { color }, small && styles.centerSmall]}>{suit}</Text>
    </View>
  )
}

export function HoleCard({ small }: { small?: boolean }) {
  return (
    <View style={[styles.card, styles.hole, small && styles.cardSmall]}>
      <Text style={[styles.center, styles.holeText, small && styles.centerSmall]}>?</Text>
    </View>
  )
}

interface CardStackProps {
  cards: Card[]
  hideHole?: boolean
  small?: boolean
}

export function CardStack({ cards, hideHole, small }: CardStackProps) {
  return (
    <View style={styles.stack}>
      {cards.map((c, i) => (
        i === 1 && hideHole
          ? <HoleCard key={c.id} small={small} />
          : <CardView key={c.id} card={c} small={small} />
      ))}
    </View>
  )
}

const W = 54, H = 76
const WS = 38, HS = 54

const styles = StyleSheet.create({
  stack: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  card: {
    width: W, height: H,
    backgroundColor: Colors.cardFace,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: Colors.cardBorder,
    padding: 4,
    justifyContent: 'space-between',
  },
  cardSmall: { width: WS, height: HS, padding: 2 },
  hole: { backgroundColor: Colors.holeBottom, borderColor: Colors.holeTop },
  cornerLabel: { fontSize: 13, fontWeight: '700', lineHeight: 14 },
  cornerLabelSmall: { fontSize: 10, lineHeight: 11 },
  center: { fontSize: 22, textAlign: 'center', fontWeight: '600' },
  centerSmall: { fontSize: 16 },
  holeText: { color: Colors.white, opacity: 0.5 },
})

import { StyleSheet } from 'react-native'

export const Colors = {
  felt:            '#0f3818',
  feltDark:        '#0a2810',
  cream:           '#f9f5e3',
  gold:            '#b89a4d',
  goldBright:      '#c9a84c',
  muted:           '#a09880',
  hit:             '#1a6627',
  stand:           '#8b1a1a',
  double:          '#1a3f8a',
  split:           '#7a4d0a',
  surrender:       '#4a1f6e',
  cardFace:        '#f9f5e3',
  cardBorder:      '#d4ceb8',
  cardRed:         '#c0392b',
  cardBlack:       '#1a1a1a',
  holeTop:         '#1a4a8a',
  holeBottom:      '#0d2d5a',
  white:           '#ffffff',
  red:             '#e74c3c',
  green:           '#27ae60',
} as const

export const actionColor: Record<string, string> = {
  hit:       Colors.hit,
  stand:     Colors.stand,
  double:    Colors.double,
  split:     Colors.split,
  surrender: Colors.surrender,
}

export const outcomeColor: Record<string, string> = {
  win:       Colors.green,
  blackjack: Colors.gold,
  push:      Colors.muted,
  surrender: Colors.surrender,
  lose:      Colors.red,
  bust:      Colors.red,
}

export const outcomeLabel: Record<string, string> = {
  win:       'WIN',
  blackjack: 'BLACKJACK',
  push:      'PUSH',
  surrender: 'SURRENDER',
  lose:      'LOSE',
  bust:      'BUST',
}

export const shared = StyleSheet.create({
  fill:  { flex: 1 },
  row:   { flexDirection: 'row' },
  center: { alignItems: 'center', justifyContent: 'center' },
  screenBg: { flex: 1, backgroundColor: Colors.felt },
  card: {
    backgroundColor: Colors.feltDark,
    borderRadius: 10,
    padding: 12,
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '600',
    color: Colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginBottom: 8,
  },
})

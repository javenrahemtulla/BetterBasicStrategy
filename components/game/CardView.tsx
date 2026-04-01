'use client'

import type { Card } from '@/lib/types'
import { rankSymbol, suitSymbol, isRed } from '@/lib/engine/card'

interface Props {
  card?: Card   // undefined = face down
  width?: number
  className?: string
}

export default function CardView({ card, width = 60, className = '' }: Props) {
  const h = Math.round(width * 1.4)
  const isFaceDown = !card

  if (isFaceDown) {
    return (
      <div
        className={`rounded-xl border border-white/20 flex items-center justify-center flex-shrink-0 ${className}`}
        style={{ width, height: h, background: 'linear-gradient(135deg, #1a4a8a 0%, #0d2d5a 100%)', boxShadow: '2px 3px 8px rgba(0,0,0,0.5)' }}
      >
        <div className="rounded-lg border border-white/15 w-[85%] h-[85%]" />
      </div>
    )
  }

  const red = isRed(card.suit)
  const textColor = red ? '#c0392b' : '#1a1a1a'
  const fontSize = Math.round(width * 0.26)
  const suitSize = Math.round(width * 0.20)
  const bigSuitSize = Math.round(width * 0.42)

  return (
    <div
      className={`rounded-xl border flex-shrink-0 relative select-none ${className}`}
      style={{ width, height: h, backgroundColor: '#f9f5e3', borderColor: '#d4ceb8', boxShadow: '2px 3px 8px rgba(0,0,0,0.5)' }}
    >
      {/* Top-left */}
      <div className="absolute top-1 left-1.5 flex flex-col items-center leading-none" style={{ color: textColor }}>
        <span className="font-bold" style={{ fontSize }}>{rankSymbol(card.rank)}</span>
        <span style={{ fontSize: suitSize }}>{suitSymbol(card.suit)}</span>
      </div>

      {/* Center pip */}
      <div className="absolute inset-0 flex items-center justify-center" style={{ color: textColor, opacity: 0.5 }}>
        <span style={{ fontSize: bigSuitSize }}>{suitSymbol(card.suit)}</span>
      </div>

      {/* Bottom-right (rotated) */}
      <div className="absolute bottom-1 right-1.5 flex flex-col items-center leading-none rotate-180" style={{ color: textColor }}>
        <span className="font-bold" style={{ fontSize }}>{rankSymbol(card.rank)}</span>
        <span style={{ fontSize: suitSize }}>{suitSymbol(card.suit)}</span>
      </div>
    </div>
  )
}

interface StackProps {
  cards: (Card | undefined)[]
  cardWidth?: number
  overlap?: number
}

export function CardStack({ cards, cardWidth = 58, overlap = 22 }: StackProps) {
  const h = Math.round(cardWidth * 1.4)
  const totalW = cardWidth + (cards.length - 1) * overlap

  return (
    <div className="relative flex-shrink-0" style={{ width: totalW, height: h }}>
      {cards.map((card, i) => (
        <div key={i} className="absolute" style={{ left: i * overlap }}>
          <CardView card={card} width={cardWidth} />
        </div>
      ))}
    </div>
  )
}

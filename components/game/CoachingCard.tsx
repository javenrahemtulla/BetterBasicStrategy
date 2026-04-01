'use client'

import type { StrategyEntry } from '@/lib/types'

interface Props {
  entry: StrategyEntry
  onDismiss: () => void
}

export default function CoachingCard({ entry, onDismiss }: Props) {
  const actionLabel = entry.action
    .replace('OrHit', '').replace('OrStand', '').replace('OrSplit', '')
    .replace(/^./, c => c.toUpperCase())

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center pb-6 px-4"
      style={{ backgroundColor: 'rgba(0,0,0,0.6)' }}
      onClick={onDismiss}
    >
      <div
        className="w-full max-w-sm rounded-2xl p-6 space-y-4"
        style={{ backgroundColor: '#121214', border: '1px solid rgba(184,154,77,0.3)' }}
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-[#b89a4d]">💡</span>
            <span className="text-[#b89a4d] text-xs font-bold tracking-widest">CORRECT PLAY</span>
          </div>
          <button onClick={onDismiss} className="text-[#a09880] text-lg leading-none">×</button>
        </div>

        <div className="text-[#f9f5e3] text-4xl font-bold">{actionLabel}</div>

        <p className="text-[#f9f5e3] text-sm leading-relaxed">{entry.explanation}</p>

        <button
          onClick={onDismiss}
          className="w-full py-3 rounded-xl bg-[#b89a4d] text-black font-bold text-base"
        >
          Got it
        </button>
      </div>
    </div>
  )
}

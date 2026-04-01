'use client'

import type { DecisionCategory } from '@/lib/types'

const ACTIONS: { category: DecisionCategory; label: string; bg: string }[] = [
  { category: 'hit',       label: 'Hit',       bg: '#1a6627' },
  { category: 'stand',     label: 'Stand',     bg: '#8b1a1a' },
  { category: 'double',    label: 'Double',    bg: '#1a3f8a' },
  { category: 'split',     label: 'Split',     bg: '#7a4d0a' },
  { category: 'surrender', label: 'Surrender', bg: '#4a1f6e' },
]

interface Props {
  available: Set<DecisionCategory>
  onAction: (category: DecisionCategory) => void
}

export default function ActionButtons({ available, onAction }: Props) {
  return (
    <div className="flex flex-col gap-2">
      <div className="grid grid-cols-2 gap-2">
        {ACTIONS.slice(0, 2).map(({ category, label, bg }) => (
          <ActionButton key={category} label={label} bg={bg}
            enabled={available.has(category)} onClick={() => onAction(category)} />
        ))}
      </div>
      <div className="grid grid-cols-3 gap-2">
        {ACTIONS.slice(2).map(({ category, label, bg }) => (
          <ActionButton key={category} label={label} bg={bg}
            enabled={available.has(category)} onClick={() => onAction(category)} />
        ))}
      </div>
    </div>
  )
}

function ActionButton({ label, bg, enabled, onClick }: {
  label: string; bg: string; enabled: boolean; onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      disabled={!enabled}
      className="py-3.5 rounded-xl font-semibold text-sm text-white transition-opacity"
      style={{ backgroundColor: enabled ? bg : 'rgba(255,255,255,0.05)', opacity: enabled ? 1 : 0.35 }}
    >
      {label}
    </button>
  )
}

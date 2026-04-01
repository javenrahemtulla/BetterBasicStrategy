'use client'

import type { DecisionCategory } from '@/lib/types'

const ACTIONS: { category: DecisionCategory; label: string; color: string }[] = [
  { category: 'hit', label: 'Hit', color: '#1e7a2a' },
  { category: 'stand', label: 'Stand', color: '#a02020' },
  { category: 'double', label: 'Double', color: '#1a4fa0' },
  { category: 'split', label: 'Split', color: '#8a5c10' },
  { category: 'surrender', label: 'Surrender', color: '#5c2880' },
]

interface Props {
  available: Set<DecisionCategory>
  onAction: (category: DecisionCategory) => void
}

export default function ActionButtons({ available, onAction }: Props) {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex gap-2">
        {ACTIONS.slice(0, 2).map(({ category, label, color }) => (
          <ActionButton key={category} label={label} color={color}
            enabled={available.has(category)} onClick={() => onAction(category)} />
        ))}
      </div>
      <div className="flex gap-2">
        {ACTIONS.slice(2).map(({ category, label, color }) => (
          <ActionButton key={category} label={label} color={color}
            enabled={available.has(category)} onClick={() => onAction(category)} />
        ))}
      </div>
    </div>
  )
}

function ActionButton({ label, color, enabled, onClick }: {
  label: string; color: string; enabled: boolean; onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      disabled={!enabled}
      className="flex-1 py-4 rounded-2xl font-bold text-lg text-white transition"
      style={{ backgroundColor: enabled ? color : 'rgba(255,255,255,0.06)', opacity: enabled ? 1 : 0.4 }}
    >
      {label}
    </button>
  )
}

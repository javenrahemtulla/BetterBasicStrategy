'use client'

interface Props {
  penetration: number   // 0–1
  remaining: number
  trigger: number       // 0–1
}

export default function PenetrationBar({ penetration, remaining, trigger }: Props) {
  const barColor = penetration >= trigger ? '#e74c3c' : penetration >= trigger - 0.1 ? '#e67e22' : '#b89a4d'

  return (
    <div className="px-4 py-2 space-y-1">
      <div className="relative h-1.5 rounded-full bg-white/10">
        <div
          className="absolute left-0 top-0 h-full rounded-full transition-all duration-300"
          style={{ width: `${penetration * 100}%`, backgroundColor: barColor }}
        />
        {/* Trigger marker */}
        <div
          className="absolute top-0 h-full w-px bg-white/30"
          style={{ left: `${trigger * 100}%` }}
        />
      </div>
      <div className="flex justify-between text-[10px] text-[#a09880] font-medium">
        <span>SHOE</span>
        <span>{remaining} cards left</span>
      </div>
    </div>
  )
}

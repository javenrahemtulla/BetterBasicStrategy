'use client'

interface Props {
  penetration: number   // 0–1
  remaining: number
  trigger: number       // 0–1
}

export default function PenetrationBar({ penetration, remaining, trigger }: Props) {
  const barColor = penetration >= trigger
    ? '#e74c3c'
    : penetration >= trigger - 0.1
      ? '#e67e22'
      : '#c9a84c'

  return (
    <div className="space-y-1.5">
      <div className="relative h-1.5 rounded-full bg-white/10">
        <div
          className="absolute left-0 top-0 h-full rounded-full transition-all duration-300"
          style={{ width: `${penetration * 100}%`, backgroundColor: barColor }}
        />
        <div
          className="absolute top-0 h-full w-px bg-white/25"
          style={{ left: `${trigger * 100}%` }}
        />
      </div>
      <div className="flex justify-between text-[10px] text-[#6b8f71] font-medium">
        <span>SHOE</span>
        <span>{remaining} cards</span>
      </div>
    </div>
  )
}

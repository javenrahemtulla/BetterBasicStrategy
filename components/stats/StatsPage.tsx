'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import type { StatsData, User } from '@/lib/types'

export default function StatsPage() {
  const router = useRouter()
  const [user, setUser] = useState<User | null>(null)
  const [stats, setStats] = useState<StatsData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const stored = sessionStorage.getItem('bbs_user')
    if (!stored) { router.push('/'); return }
    const u: User = JSON.parse(stored)
    setUser(u)

    fetch(`/api/stats?user_id=${u.id}`)
      .then(r => r.json())
      .then(d => { setStats(d.stats); setLoading(false) })
      .catch(() => setLoading(false))
  }, [router])

  if (loading) {
    return (
      <div className="min-h-screen bg-[#080f0a] flex items-center justify-center">
        <span className="text-[#b89a4d]">Loading stats...</span>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#080f0a] text-[#f9f5e3]" style={{ maxWidth: 480, margin: '0 auto' }}>
      {/* Header */}
      <div className="flex items-center justify-between px-4 pt-5 pb-4">
        <button onClick={() => router.push('/game')} className="text-[#a09880] text-sm">← Back</button>
        <h1 className="text-lg font-bold text-[#f9f5e3]">Statistics</h1>
        <span className="text-[#b89a4d] text-sm">{user?.username}</span>
      </div>

      <div className="px-4 pb-12 space-y-5">
        {/* Summary cards */}
        <div className="grid grid-cols-3 gap-3">
          <SummaryCard title="HANDS" value={String(stats?.lifetimeHands ?? 0)} />
          <SummaryCard title="DECISIONS" value={String(stats?.lifetimeDecisions ?? 0)} />
          <SummaryCard title="ACCURACY" value={`${Math.round(stats?.lifetimeAccuracy ?? 0)}%`} highlight />
        </div>

        {/* Streaks + Shoes */}
        <div className="grid grid-cols-3 gap-3">
          <SummaryCard title="STREAK" value={`${stats?.currentStreak ?? 0} ✓`} />
          <SummaryCard title="BEST STREAK" value={`${stats?.longestStreak ?? 0} ✓`} />
          <SummaryCard title="SHOES" value={String(stats?.shoesPlayed ?? 0)} />
        </div>

        {/* Outcome breakdown */}
        <Section title="HAND OUTCOMES">
          <div className="grid grid-cols-5 gap-2 text-center">
            {[
              { label: 'Win', value: stats?.outcomeCounts?.wins ?? 0, color: '#27ae60' },
              { label: 'Loss', value: stats?.outcomeCounts?.losses ?? 0, color: '#c0392b' },
              { label: 'Push', value: stats?.outcomeCounts?.pushes ?? 0, color: '#a09880' },
              { label: 'BJ', value: stats?.outcomeCounts?.blackjacks ?? 0, color: '#b89a4d' },
              { label: 'Surr.', value: stats?.outcomeCounts?.surrenders ?? 0, color: '#8e44ad' },
            ].map(({ label, value, color }) => (
              <div key={label} className="rounded-lg py-3" style={{ backgroundColor: 'rgba(255,255,255,0.05)' }}>
                <div className="text-lg font-bold" style={{ color }}>{value}</div>
                <div className="text-[10px] text-[#a09880] font-semibold mt-0.5">{label}</div>
              </div>
            ))}
          </div>
        </Section>

        {/* Accuracy by hand type */}
        <Section title="ACCURACY BY HAND TYPE">
          {(stats?.accuracyByHandType ?? []).map(item => (
            <div key={item.label} className="space-y-1">
              <div className="flex justify-between text-sm">
                <span className="text-[#f9f5e3]">{item.label}</span>
                <span className="font-bold" style={{ color: pctColor(item.accuracy) }}>
                  {item.total > 0 ? `${Math.round(item.accuracy)}%` : '—'}
                </span>
              </div>
              <div className="h-2 rounded-full bg-white/10">
                <div
                  className="h-full rounded-full transition-all"
                  style={{ width: `${item.accuracy}%`, backgroundColor: pctColor(item.accuracy) }}
                />
              </div>
            </div>
          ))}
        </Section>

        {/* Dealer upcard heat map */}
        <Section title="ACCURACY BY DEALER UPCARD">
          <div className="grid grid-cols-5 gap-2">
            {(stats?.accuracyByDealerUpcard ?? []).map(cell => (
              <div
                key={cell.rank}
                className="rounded-lg p-2 flex flex-col items-center gap-0.5"
                style={{ backgroundColor: heatColor(cell.accuracy, cell.total) }}
              >
                <span className="text-white font-bold text-sm">{cell.rank}</span>
                <span className="text-white/90 text-xs font-medium">
                  {cell.total > 0 ? `${Math.round(cell.accuracy)}%` : '—'}
                </span>
                <span className="text-white/50 text-[10px]">{cell.total}</span>
              </div>
            ))}
          </div>
        </Section>

        {/* Top mistakes */}
        <Section title="TOP MISTAKES">
          {(stats?.topMistakes ?? []).length === 0 ? (
            <p className="text-[#a09880] text-sm">No mistakes yet — keep it up!</p>
          ) : (
            (stats?.topMistakes ?? []).map((m, i) => (
              <div key={m.label} className="flex items-center gap-3 py-2 border-b border-white/5 last:border-0">
                <span className="text-[#a09880] text-xs w-5">{i + 1}</span>
                <div className="flex-1">
                  <p className="text-sm text-[#f9f5e3]">{m.label}</p>
                  <p className="text-xs text-[#b89a4d]">Should: {m.correctAction}</p>
                </div>
                <span className="text-red-400 font-bold text-sm">{m.count}×</span>
              </div>
            ))
          )}
        </Section>

        {/* Session history */}
        <Section title="RECENT SESSIONS">
          {(stats?.recentSessions ?? []).length === 0 ? (
            <p className="text-[#a09880] text-sm">No sessions yet.</p>
          ) : (
            (stats?.recentSessions ?? []).map(s => {
              const total = s.correct_decisions + s.incorrect_decisions
              const acc = total > 0 ? Math.round((s.correct_decisions / total) * 100) : 0
              return (
                <div key={s.id} className="flex items-center justify-between py-3 border-b border-white/5 last:border-0">
                  <div>
                    <p className="text-sm text-[#f9f5e3]">{new Date(s.started_at).toLocaleDateString()}</p>
                    <p className="text-xs text-[#a09880]">{s.hands_played} hands</p>
                  </div>
                  <span className="font-bold text-lg" style={{ color: pctColor(acc) }}>{acc}%</span>
                </div>
              )
            })
          )}
        </Section>
      </div>
    </div>
  )
}

function SummaryCard({ title, value, highlight }: { title: string; value: string; highlight?: boolean }) {
  return (
    <div
      className="rounded-xl py-4 flex flex-col items-center gap-1"
      style={{
        backgroundColor: highlight ? 'rgba(184,154,77,0.12)' : 'rgba(255,255,255,0.05)',
        border: highlight ? '1px solid rgba(184,154,77,0.3)' : '1px solid transparent',
      }}
    >
      <span className="text-xl font-bold" style={{ color: highlight ? '#b89a4d' : '#f9f5e3' }}>{value}</span>
      <span className="text-[9px] font-bold text-[#a09880] tracking-widest">{title}</span>
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl p-4 space-y-3" style={{ backgroundColor: 'rgba(255,255,255,0.04)' }}>
      <h2 className="text-[10px] font-bold text-[#a09880] tracking-widest">{title}</h2>
      {children}
    </div>
  )
}

function pctColor(pct: number): string {
  if (pct >= 90) return '#27ae60'
  if (pct >= 70) return '#b89a4d'
  return '#c0392b'
}

function heatColor(pct: number, total: number): string {
  if (total === 0) return 'rgba(255,255,255,0.06)'
  if (pct >= 90) return 'rgba(39,174,96,0.7)'
  if (pct >= 70) return 'rgba(184,154,77,0.7)'
  return 'rgba(192,57,43,0.7)'
}

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
        <span className="text-[#c9a84c]">Loading…</span>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#080f0a] text-[#f0ead0]">

      {/* Header */}
      <header className="border-b border-white/[0.06] px-6 py-3">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <button
            onClick={() => router.push('/game')}
            className="text-sm text-[#6b8f71] hover:text-[#f0ead0] transition-colors"
          >
            ← Back
          </button>
          <h1 className="text-sm font-semibold text-[#f0ead0]">Statistics</h1>
          <span className="text-sm text-[#c9a84c]">{user?.username}</span>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-4 py-8 space-y-6">

        {/* Top summary row */}
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
          <SummaryCard title="HANDS"     value={String(stats?.lifetimeHands ?? 0)} />
          <SummaryCard title="DECISIONS" value={String(stats?.lifetimeDecisions ?? 0)} />
          <SummaryCard title="ACCURACY"  value={`${Math.round(stats?.lifetimeAccuracy ?? 0)}%`} highlight />
          <SummaryCard title="STREAK"    value={String(stats?.currentStreak ?? 0)} />
          <SummaryCard title="BEST"      value={String(stats?.longestStreak ?? 0)} />
          <SummaryCard title="SHOES"     value={String(stats?.shoesPlayed ?? 0)} />
        </div>

        {/* Two-column layout on large screens */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

          {/* Outcome breakdown */}
          <Section title="HAND OUTCOMES">
            <div className="grid grid-cols-5 gap-2 text-center">
              {[
                { label: 'Win',   value: stats?.outcomeCounts?.wins       ?? 0, color: '#27ae60' },
                { label: 'Loss',  value: stats?.outcomeCounts?.losses     ?? 0, color: '#c0392b' },
                { label: 'Push',  value: stats?.outcomeCounts?.pushes     ?? 0, color: '#8a9e8d' },
                { label: 'BJ',    value: stats?.outcomeCounts?.blackjacks ?? 0, color: '#c9a84c' },
                { label: 'Surr.', value: stats?.outcomeCounts?.surrenders ?? 0, color: '#7c4dbb' },
              ].map(({ label, value, color }) => (
                <div key={label} className="rounded-lg py-3 bg-white/[0.04]">
                  <div className="text-xl font-bold" style={{ color }}>{value}</div>
                  <div className="text-[10px] text-[#6b8f71] font-semibold mt-1">{label}</div>
                </div>
              ))}
            </div>
          </Section>

          {/* Accuracy by hand type */}
          <Section title="ACCURACY BY HAND TYPE">
            <div className="space-y-4">
              {(stats?.accuracyByHandType ?? []).map(item => (
                <div key={item.label}>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="text-[#f0ead0]">{item.label}</span>
                    <span className="font-semibold" style={{ color: pctColor(item.accuracy) }}>
                      {item.total > 0 ? `${Math.round(item.accuracy)}%` : '—'}
                    </span>
                  </div>
                  <div className="h-1.5 rounded-full bg-white/10">
                    <div
                      className="h-full rounded-full transition-all"
                      style={{ width: `${item.accuracy}%`, backgroundColor: pctColor(item.accuracy) }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </Section>

          {/* Dealer upcard heat map */}
          <Section title="ACCURACY BY DEALER UPCARD">
            <div className="grid grid-cols-5 gap-2">
              {(stats?.accuracyByDealerUpcard ?? []).map(cell => (
                <div
                  key={cell.rank}
                  className="rounded-lg p-2.5 flex flex-col items-center gap-0.5"
                  style={{ backgroundColor: heatColor(cell.accuracy, cell.total) }}
                >
                  <span className="text-white font-bold text-sm">{cell.rank}</span>
                  <span className="text-white/90 text-xs font-medium">
                    {cell.total > 0 ? `${Math.round(cell.accuracy)}%` : '—'}
                  </span>
                  <span className="text-white/40 text-[10px]">{cell.total}</span>
                </div>
              ))}
            </div>
          </Section>

          {/* Top mistakes */}
          <Section title="TOP MISTAKES">
            {(stats?.topMistakes ?? []).length === 0 ? (
              <p className="text-[#6b8f71] text-sm">No mistakes yet.</p>
            ) : (
              <div className="space-y-0">
                {(stats?.topMistakes ?? []).map((m, i) => (
                  <div key={m.label} className="flex items-center gap-3 py-2.5 border-b border-white/[0.05] last:border-0">
                    <span className="text-[#6b8f71] text-xs w-4 shrink-0">{i + 1}</span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-[#f0ead0] truncate">{m.label}</p>
                      <p className="text-xs text-[#c9a84c]">Should: {m.correctAction}</p>
                    </div>
                    <span className="text-red-400 font-semibold text-sm shrink-0">{m.count}×</span>
                  </div>
                ))}
              </div>
            )}
          </Section>
        </div>

        {/* Recent sessions — full width */}
        <Section title="RECENT SESSIONS">
          {(stats?.recentSessions ?? []).length === 0 ? (
            <p className="text-[#6b8f71] text-sm">No sessions yet.</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {(stats?.recentSessions ?? []).map(s => {
                const total = s.correct_decisions + s.incorrect_decisions
                const acc = total > 0 ? Math.round((s.correct_decisions / total) * 100) : 0
                return (
                  <div key={s.id} className="flex items-center justify-between p-3 rounded-lg bg-white/[0.03] border border-white/[0.05]">
                    <div>
                      <p className="text-sm text-[#f0ead0]">
                        {new Date(s.started_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
                      </p>
                      <p className="text-xs text-[#6b8f71] mt-0.5">{s.hands_played} hands</p>
                    </div>
                    <span className="font-bold text-xl" style={{ color: pctColor(acc) }}>{acc}%</span>
                  </div>
                )
              })}
            </div>
          )}
        </Section>

      </div>
    </div>
  )
}

function SummaryCard({ title, value, highlight }: { title: string; value: string; highlight?: boolean }) {
  return (
    <div className={`rounded-xl py-4 flex flex-col items-center gap-1 ${
      highlight ? 'bg-[#c9a84c]/10 ring-1 ring-[#c9a84c]/25' : 'bg-white/[0.04]'
    }`}>
      <span className="text-xl font-bold" style={{ color: highlight ? '#c9a84c' : '#f0ead0' }}>{value}</span>
      <span className="text-[9px] font-bold text-[#6b8f71] tracking-widest">{title}</span>
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-xl p-5 space-y-4 bg-white/[0.03] border border-white/[0.05]">
      <h2 className="text-[10px] font-bold text-[#6b8f71] tracking-widest">{title}</h2>
      {children}
    </div>
  )
}

function pctColor(pct: number): string {
  if (pct >= 90) return '#27ae60'
  if (pct >= 70) return '#c9a84c'
  return '#c0392b'
}

function heatColor(pct: number, total: number): string {
  if (total === 0) return 'rgba(255,255,255,0.05)'
  if (pct >= 90) return 'rgba(39,174,96,0.65)'
  if (pct >= 70) return 'rgba(201,168,76,0.65)'
  return 'rgba(192,57,43,0.65)'
}

import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'
import type { StatsData } from '@/lib/types'

// GET /api/stats?user_id=xxx
export async function GET(req: NextRequest) {
  const userId = req.nextUrl.searchParams.get('user_id')
  if (!userId) return NextResponse.json({ error: 'user_id required' }, { status: 400 })

  const [sessionsRes, handsRes, shoesRes] = await Promise.all([
    supabase
      .from('game_sessions')
      .select('*')
      .eq('user_id', userId)
      .order('started_at', { ascending: false })
      .limit(20),
    supabase
      .from('hand_records')
      .select('*')
      .eq('user_id', userId)
      .order('timestamp', { ascending: true }),
    supabase
      .from('shoe_events')
      .select('id', { count: 'exact' })
      .eq('user_id', userId),
  ])

  if (sessionsRes.error) return NextResponse.json({ error: sessionsRes.error.message }, { status: 500 })

  const sessions = sessionsRes.data ?? []
  const hands = handsRes.data ?? []
  const shoesPlayed = shoesRes.count ?? 0

  // Derive totals directly from hand records
  const lifetimeHands = hands.length
  let totalCorrect = 0, totalIncorrect = 0
  const outcomeCounts = { wins: 0, losses: 0, pushes: 0, blackjacks: 0, surrenders: 0 }

  for (const hand of hands) {
    for (const action of (hand.actions_taken ?? [])) {
      if (action.wasCorrect) totalCorrect++
      else totalIncorrect++
    }
    const outcome = hand.outcome as string
    if (outcome === 'win') outcomeCounts.wins++
    else if (outcome === 'lose' || outcome === 'bust') outcomeCounts.losses++
    else if (outcome === 'push') outcomeCounts.pushes++
    else if (outcome === 'blackjack') outcomeCounts.blackjacks++
    else if (outcome === 'surrender') outcomeCounts.surrenders++
  }

  const lifetimeDecisions = totalCorrect + totalIncorrect
  const lifetimeAccuracy = lifetimeDecisions > 0 ? (totalCorrect / lifetimeDecisions) * 100 : 0

  // Streaks
  let currentStreak = 0, longestStreak = 0, streak = 0
  for (const hand of hands) {
    for (const action of (hand.actions_taken ?? [])) {
      if (action.wasCorrect) { streak++; longestStreak = Math.max(longestStreak, streak) }
      else streak = 0
    }
  }
  currentStreak = streak

  // Accuracy by hand type
  const typeMap: Record<string, { correct: number; total: number }> = { hard: { correct: 0, total: 0 }, soft: { correct: 0, total: 0 }, pair: { correct: 0, total: 0 } }
  for (const hand of hands) {
    const type = hand.hand_type as string
    if (!typeMap[type]) continue
    for (const a of (hand.actions_taken ?? [])) {
      typeMap[type].total++
      if (a.wasCorrect) typeMap[type].correct++
    }
  }
  const accuracyByHandType = Object.entries(typeMap).map(([label, { correct, total }]) => ({
    label: label.charAt(0).toUpperCase() + label.slice(1),
    accuracy: total > 0 ? (correct / total) * 100 : 0,
    total,
  }))

  // Accuracy by dealer upcard
  const rankLabels = ['2','3','4','5','6','7','8','9','10','A']
  const rankValues: Record<string, number[]> = {
    '2': [2], '3': [3], '4': [4], '5': [5], '6': [6],
    '7': [7], '8': [8], '9': [9], '10': [10, 11, 12, 13], 'A': [14],
  }
  const accuracyByDealerUpcard = rankLabels.map(label => {
    const validRanks = rankValues[label]
    const filtered = hands.filter(h => validRanks.includes(h.dealer_upcard?.rank))
    const c = filtered.reduce((a, h) => a + (h.actions_taken ?? []).filter((x: { wasCorrect: boolean }) => x.wasCorrect).length, 0)
    const t = filtered.reduce((a, h) => a + (h.actions_taken ?? []).length, 0)
    return { rank: label, accuracy: t > 0 ? (c / t) * 100 : 0, total: t }
  })

  // Top mistakes
  const mistakeMap: Record<string, { count: number; correct: string }> = {}
  for (const hand of hands) {
    for (const action of (hand.actions_taken ?? [])) {
      if (!action.wasCorrect) {
        const key = `${hand.hand_type} ${hand.player_total} vs ${hand.dealer_upcard?.rank}`
        mistakeMap[key] = { count: (mistakeMap[key]?.count ?? 0) + 1, correct: action.correctAction }
      }
    }
  }
  const topMistakes = Object.entries(mistakeMap)
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 10)
    .map(([label, { count, correct }]) => ({ label, count, correctAction: correct }))

  const stats: StatsData = {
    lifetimeHands,
    lifetimeDecisions,
    lifetimeAccuracy,
    currentStreak,
    longestStreak,
    shoesPlayed,
    outcomeCounts,
    accuracyByHandType,
    accuracyByDealerUpcard,
    topMistakes,
    recentSessions: sessions,
  }

  return NextResponse.json({ stats })
}

import type { BBSUser, GameSession, StatsData, ActionRecord } from '../types'

const SUPABASE_URL  = 'https://YOUR_PROJECT.supabase.co'
const SUPABASE_ANON = 'YOUR_ANON_KEY'

const headers = {
  'Content-Type': 'application/json',
  'apikey': SUPABASE_ANON,
  'Authorization': `Bearer ${SUPABASE_ANON}`,
}

async function rpc<T>(path: string, opts: RequestInit): Promise<T> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, { ...opts, headers: { ...headers, ...((opts.headers ?? {}) as Record<string, string>) } })
  if (!res.ok) throw new Error(`Supabase ${path}: ${res.status}`)
  return res.json() as Promise<T>
}

// ─── Users ────────────────────────────────────────────────────────────────────

export async function getOrCreateUser(username: string): Promise<BBSUser> {
  const existing = await rpc<BBSUser[]>(`users?username=eq.${encodeURIComponent(username)}&limit=1`, { method: 'GET' })
  if (existing.length > 0) return existing[0]
  const created = await rpc<BBSUser[]>('users', {
    method: 'POST',
    body: JSON.stringify({ username }),
    headers: { 'Prefer': 'return=representation' },
  })
  return created[0]
}

// ─── Sessions ─────────────────────────────────────────────────────────────────

export async function createSession(userId: string): Promise<GameSession> {
  const rows = await rpc<GameSession[]>('game_sessions', {
    method: 'POST',
    body: JSON.stringify({ user_id: userId, hands_played: 0, correct_decisions: 0, incorrect_decisions: 0 }),
    headers: { 'Prefer': 'return=representation' },
  })
  return rows[0]
}

export async function updateSession(sessionId: string, patch: Partial<GameSession>): Promise<void> {
  await rpc<unknown>(`game_sessions?id=eq.${sessionId}`, {
    method: 'PATCH',
    body: JSON.stringify(patch),
  })
}

// ─── Hand records ─────────────────────────────────────────────────────────────

export interface HandPayload {
  session_id: string
  user_id: string
  hand_index: number
  hand_type: string
  player_total: number
  dealer_upcard_rank: number
  outcome: string
  actions_taken: ActionRecord[]
  was_correct: boolean
}

export async function upsertHand(hand: HandPayload): Promise<void> {
  await rpc<unknown>('hand_records', {
    method: 'POST',
    body: JSON.stringify(hand),
    headers: { 'Prefer': 'return=minimal' },
  })
}

// ─── Stats ────────────────────────────────────────────────────────────────────

interface MinAction { wasCorrect: boolean; correctAction: string; action: string }
interface MinHand {
  hand_type: string
  dealer_upcard_rank: number
  outcome: string
  actions_taken: MinAction[]
  session_id: string
}

function rankLabel(r: number): string {
  if (r === 14) return 'A'
  if (r === 13) return 'K'
  if (r === 12) return 'Q'
  if (r === 11) return 'J'
  return String(r)
}

export async function loadStats(userId: string): Promise<StatsData> {
  const [hands, sessions] = await Promise.all([
    rpc<MinHand[]>(`hand_records?user_id=eq.${userId}&select=hand_type,dealer_upcard_rank,outcome,actions_taken,session_id`, { method: 'GET' }),
    rpc<GameSession[]>(`game_sessions?user_id=eq.${userId}&order=started_at.desc&limit=10`, { method: 'GET' }),
  ])

  let correct = 0, total = 0
  const outcomes = { wins: 0, losses: 0, pushes: 0, blackjacks: 0, surrenders: 0 }
  const byType: Record<string, { c: number; t: number }> = {}
  const byUpcard: Record<number, { c: number; t: number }> = {}
  const mistakes: Record<string, { count: number; correctAction: string }> = {}
  let streak = 0, longest = 0, cur = 0

  for (const h of hands) {
    const actions = Array.isArray(h.actions_taken) ? h.actions_taken : []
    for (const a of actions) {
      total++
      if (a.wasCorrect) { correct++; cur++; if (cur > longest) longest = cur } else { cur = 0 }
      const bt = (byType[h.hand_type] ??= { c: 0, t: 0 })
      bt.t++; if (a.wasCorrect) bt.c++
      const bu = (byUpcard[h.dealer_upcard_rank] ??= { c: 0, t: 0 })
      bu.t++; if (a.wasCorrect) bu.c++
      if (!a.wasCorrect) {
        const label = `${h.hand_type} vs ${rankLabel(h.dealer_upcard_rank)}`
        const m = (mistakes[label] ??= { count: 0, correctAction: a.correctAction })
        m.count++
      }
    }
    switch (h.outcome) {
      case 'win':       outcomes.wins++;        break
      case 'blackjack': outcomes.blackjacks++;   break
      case 'push':      outcomes.pushes++;       break
      case 'surrender': outcomes.surrenders++;   break
      default:          outcomes.losses++;
    }
  }
  streak = cur

  const sessionIds = new Set(hands.map(h => h.session_id))

  return {
    lifetimeHands: hands.length,
    lifetimeDecisions: total,
    lifetimeAccuracy: total ? correct / total : 0,
    currentStreak: streak,
    longestStreak: longest,
    shoesPlayed: sessionIds.size,
    outcomeCounts: outcomes,
    accuracyByHandType: Object.entries(byType).map(([label, v]) => ({ label, accuracy: v.t ? v.c / v.t : 0, total: v.t })),
    accuracyByDealerUpcard: Object.entries(byUpcard).map(([rank, v]) => ({ rank: rankLabel(Number(rank)), accuracy: v.t ? v.c / v.t : 0, total: v.t })).sort((a, b) => Number(a.rank) - Number(b.rank)),
    topMistakes: Object.entries(mistakes).sort((a, b) => b[1].count - a[1].count).slice(0, 5).map(([label, v]) => ({ label, count: v.count, correctAction: v.correctAction })),
    recentSessions: sessions,
  }
}

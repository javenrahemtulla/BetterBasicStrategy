'use client'

import { useCallback, useEffect, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import type { DecisionCategory, GameState, RuleSet, User } from '@/lib/types'
import { DEFAULT_RULES } from '@/lib/types'
import { loadShoe } from '@/lib/engine/shoe'
import type { ShoeState } from '@/lib/engine/shoe'
import { dealNewRound, getAvailableActions, performAction } from '@/lib/engine/gameEngine'
import { BasicStrategyEngine } from '@/lib/engine/basicStrategyEngine'
import { buildHandState } from '@/lib/engine/hand'
import { CardStack } from './CardView'
import CoachingCard from './CoachingCard'
import PenetrationBar from './PenetrationBar'
import ActionButtons from './ActionButtons'
import { penetration, remainingCount } from '@/lib/engine/shoe'
import { calcTotal } from '@/lib/engine/hand'

const INITIAL_GAME_STATE: GameState = {
  phase: 'idle',
  spots: [],
  activeSpotIndex: 0,
  dealerCards: [],
  dealerHoleRevealed: false,
  lastActionWasCorrect: null,
  lastCoachingEntry: null,
}

export default function GamePage() {
  const router = useRouter()
  const [user, setUser] = useState<User | null>(null)
  const [rules] = useState<RuleSet>(DEFAULT_RULES)
  const [game, setGame] = useState<GameState>(INITIAL_GAME_STATE)
  const [shoe, setShoe] = useState<ShoeState | null>(null)
  const [engine, setEngine] = useState<BasicStrategyEngine | null>(null)
  const [showCoaching, setShowCoaching] = useState(false)
  const [sessionCorrect, setSessionCorrect] = useState(0)
  const [sessionTotal, setSessionTotal] = useState(0)
  const sessionIdRef = useRef<string | null>(null)

  useEffect(() => {
    const stored = sessionStorage.getItem('bbs_user')
    if (!stored) { router.push('/'); return }
    setUser(JSON.parse(stored))
    setShoe(loadShoe(DEFAULT_RULES.penetrationPercent))
    setEngine(new BasicStrategyEngine(DEFAULT_RULES))
  }, [router])

  useEffect(() => {
    if (!user) return
    fetch('/api/session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: user.id, rules_snapshot: rules }),
    })
      .then(r => r.json())
      .then(d => { if (d.session) sessionIdRef.current = d.session.id })
  }, [user, rules])

  const handleDeal = useCallback(() => {
    if (!shoe || !engine) return
    setShowCoaching(false)
    const result = dealNewRound(game, shoe, rules)
    setGame(result.state)
    setShoe(result.shoe)
    if (result.reshuffled && user) {
      fetch('/api/shoe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: user.id }),
      })
    }
  }, [shoe, engine, game, rules, user])

  const handleAction = useCallback((category: DecisionCategory) => {
    if (!shoe || !engine) return
    const result = performAction(game, shoe, category, rules, engine)

    const wasCorrect = result.state.lastActionWasCorrect
    setSessionTotal(t => t + 1)
    if (wasCorrect) setSessionCorrect(c => c + 1)

    setGame(result.state)
    setShoe(result.shoe)

    if (!wasCorrect && result.state.lastCoachingEntry) {
      setShowCoaching(true)
    }

    if (result.state.phase === 'roundOver' && user && sessionIdRef.current) {
      saveHandRecords(result.state, user.id, sessionIdRef.current, rules)
    }
  }, [shoe, engine, game, rules, user])

  const dismissCoaching = useCallback(() => setShowCoaching(false), [])

  const available = shoe && engine ? getAvailableActions(game, rules) : new Set<DecisionCategory>()
  const dealerTotal = game.dealerCards.length > 0 ? calcTotal(game.dealerCards) : null
  const visibleDealerCards = game.phase === 'playerTurn'
    ? [game.dealerCards[0], undefined]
    : game.dealerCards.map(c => c)
  const accuracy = sessionTotal > 0 ? Math.round((sessionCorrect / sessionTotal) * 100) : 0

  if (!user || !shoe) {
    return (
      <div className="min-h-screen bg-[#0a2410] flex items-center justify-center">
        <span className="text-[#c9a84c]">Loading…</span>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#0a2410] text-[#f0ead0] flex flex-col">

      {/* Header */}
      <header className="border-b border-white/[0.06] px-6 py-3">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <button
            onClick={() => router.push('/')}
            className="text-sm text-[#6b8f71] hover:text-[#f0ead0] transition-colors"
          >
            ← Exit
          </button>
          <span className="text-sm font-medium text-[#c9a84c]">{user.username}</span>
          <button
            onClick={() => router.push('/stats')}
            className="text-sm text-[#6b8f71] hover:text-[#f0ead0] transition-colors"
          >
            Stats →
          </button>
        </div>
      </header>

      {/* Body */}
      <div className="flex-1 max-w-5xl mx-auto w-full px-4 py-6 flex flex-col lg:flex-row lg:gap-10 lg:items-start">

        {/* Table — dealer + player */}
        <div className="flex-1 flex flex-col items-center gap-8 min-w-0">

          {/* Dealer area */}
          <section className="flex flex-col items-center gap-3 w-full">
            <span className="text-[10px] font-bold tracking-widest text-[#6b8f71]">DEALER</span>
            {game.dealerCards.length > 0
              ? <CardStack cards={visibleDealerCards} cardWidth={64} overlap={22} />
              : <div className="h-[90px] w-[64px] rounded-xl border-2 border-dashed border-white/10" />
            }
            {game.phase !== 'idle' && dealerTotal && (
              <span className={`text-2xl font-bold ${dealerTotal.total > 21 ? 'text-red-400' : 'text-[#f0ead0]'}`}>
                {game.phase === 'playerTurn'
                  ? (game.dealerCards[0] ? calcTotal([game.dealerCards[0]]).total : '')
                  : (dealerTotal.total > 21 ? 'Bust' : dealerTotal.total)}
              </span>
            )}
          </section>

          <div className="w-full max-w-xs border-t border-white/[0.06]" />

          {/* Player spots */}
          <section className="flex-1 w-full flex items-center justify-center">
            {game.spots.length === 0 ? (
              <div className="flex flex-col items-center gap-2 text-white/20 select-none">
                <span className="text-5xl">♠</span>
                <span className="text-sm">Deal to begin</span>
              </div>
            ) : (
              <div className="flex gap-6 flex-wrap justify-center">
                {game.spots.map((spot, spotIdx) => (
                  <div
                    key={spot.id}
                    className={`flex flex-col items-center gap-2 p-3 rounded-xl transition-colors ${
                      spotIdx === game.activeSpotIndex && game.phase === 'playerTurn'
                        ? 'bg-white/[0.06] ring-1 ring-[#c9a84c]/40'
                        : ''
                    }`}
                  >
                    {spot.hands.map((hand, handIdx) => (
                      <div key={handIdx} className="flex flex-col items-center gap-1.5">
                        <CardStack cards={hand.cards} cardWidth={62} overlap={20} />
                        <span className={`text-xl font-bold ${
                          hand.isBust ? 'text-red-400'
                          : (spotIdx === game.activeSpotIndex && handIdx === spot.activeHandIndex)
                            ? 'text-[#c9a84c]'
                            : 'text-[#f0ead0]'
                        }`}>
                          {hand.isBust ? 'Bust' : hand.total}
                        </span>
                        {game.phase === 'roundOver' && spot.outcomes[handIdx] && (
                          <span className={`text-xs font-semibold px-2.5 py-0.5 rounded-full ${outcomeBadge(spot.outcomes[handIdx])}`}>
                            {spot.outcomes[handIdx].toUpperCase()}
                          </span>
                        )}
                      </div>
                    ))}
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>

        {/* Controls panel */}
        <aside className="lg:w-64 lg:shrink-0 flex flex-col gap-4 mt-6 lg:mt-0">

          <PenetrationBar
            penetration={penetration(shoe)}
            remaining={remainingCount(shoe)}
            trigger={rules.penetrationPercent}
          />

          {/* Session stats */}
          <div className="grid grid-cols-3 gap-2">
            <StatCard label="SESSION" value={`${accuracy}%`} highlight />
            <StatCard label="CORRECT" value={String(sessionCorrect)} />
            <StatCard label="HANDS" value={String(sessionTotal)} />
          </div>

          {/* Action buttons */}
          <div>
            {game.phase === 'playerTurn' ? (
              <ActionButtons available={available} onAction={handleAction} />
            ) : (
              <button
                onClick={handleDeal}
                className="w-full py-4 rounded-xl bg-[#c9a84c] text-[#0a2410] font-bold text-base hover:bg-[#d9b85c] transition-colors"
              >
                {game.phase === 'idle' ? 'Deal' : 'Next Hand'}
              </button>
            )}
          </div>
        </aside>
      </div>

      {showCoaching && game.lastCoachingEntry && (
        <CoachingCard entry={game.lastCoachingEntry} onDismiss={dismissCoaching} />
      )}
    </div>
  )
}

function StatCard({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  return (
    <div className={`rounded-lg py-3 flex flex-col items-center gap-0.5 ${
      highlight ? 'bg-[#c9a84c]/10 ring-1 ring-[#c9a84c]/25' : 'bg-white/[0.04]'
    }`}>
      <span className={`text-lg font-bold ${highlight ? 'text-[#c9a84c]' : 'text-[#f0ead0]'}`}>{value}</span>
      <span className="text-[9px] font-bold text-[#6b8f71] tracking-widest">{label}</span>
    </div>
  )
}

function outcomeBadge(outcome: string): string {
  const map: Record<string, string> = {
    win:       'bg-green-700/70 text-green-100',
    blackjack: 'bg-green-600/70 text-green-100',
    lose:      'bg-red-800/70 text-red-100',
    bust:      'bg-red-900/70 text-red-100',
    push:      'bg-white/10 text-[#a09880]',
    surrender: 'bg-purple-800/70 text-purple-100',
  }
  return map[outcome] ?? 'bg-white/10 text-[#a09880]'
}

async function saveHandRecords(state: GameState, userId: string, sessionId: string, rules: RuleSet) {
  const dealerUpcard = state.dealerCards[0]
  for (const [spotIdx, spot] of state.spots.entries()) {
    for (const [handIdx, hand] of spot.hands.entries()) {
      const actions = spot.actions[handIdx] ?? []
      await fetch('/api/hand', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: sessionId,
          user_id: userId,
          spot_number: spotIdx,
          player_cards: hand.cards,
          dealer_upcard: dealerUpcard,
          dealer_final_hand: state.dealerCards,
          hand_type: hand.handType,
          player_total: hand.total,
          actions_taken: actions,
          outcome: spot.outcomes[handIdx] ?? 'lose',
          was_split: spot.hands.length > 1,
          was_doubled: actions.some(a => a.action === 'double'),
          was_surrendered: spot.outcomes[handIdx] === 'surrender',
        }),
      })
    }
  }
}

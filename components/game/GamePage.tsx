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

  // Load user and shoe from storage
  useEffect(() => {
    const stored = sessionStorage.getItem('bbs_user')
    if (!stored) { router.push('/'); return }
    setUser(JSON.parse(stored))
    setShoe(loadShoe(DEFAULT_RULES.penetrationPercent))
    setEngine(new BasicStrategyEngine(DEFAULT_RULES))
  }, [router])

  // Start DB session
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
  }, [shoe, engine, game, rules])

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

    // Save hand records when round is over
    if (result.state.phase === 'roundOver' && user && sessionIdRef.current) {
      saveHandRecords(result.state, user.id, sessionIdRef.current, rules)
    }
  }, [shoe, engine, game, rules, user])

  const dismissCoaching = useCallback(() => {
    setShowCoaching(false)
  }, [])

  const available = shoe && engine ? getAvailableActions(game, rules) : new Set<DecisionCategory>()

  const dealerTotal = game.dealerCards.length > 0 ? calcTotal(game.dealerCards) : null
  const visibleDealerCards = game.phase === 'playerTurn'
    ? [game.dealerCards[0], undefined]
    : game.dealerCards.map(c => c)

  const accuracy = sessionTotal > 0 ? Math.round((sessionCorrect / sessionTotal) * 100) : 0

  if (!user || !shoe) {
    return (
      <div className="min-h-screen bg-[#0f3818] flex items-center justify-center">
        <div className="text-[#b89a4d] text-lg">Loading...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#0f3818] flex flex-col select-none" style={{ maxWidth: 480, margin: '0 auto' }}>
      {/* Top bar */}
      <div className="flex items-center justify-between px-4 pt-4 pb-2">
        <button onClick={() => router.push('/')} className="text-[#a09880] text-sm">← Exit</button>
        <span className="text-[#b89a4d] text-sm font-semibold">{user.username}</span>
        <button onClick={() => router.push('/stats')} className="text-[#a09880] text-sm">Stats →</button>
      </div>

      {/* Penetration bar */}
      <PenetrationBar
        penetration={penetration(shoe)}
        remaining={remainingCount(shoe)}
        trigger={rules.penetrationPercent}
      />

      {/* Dealer area */}
      <div className="flex flex-col items-center py-6 gap-3">
        <span className="text-[#a09880] text-xs font-bold tracking-widest">DEALER</span>
        {game.dealerCards.length > 0
          ? <CardStack cards={visibleDealerCards} cardWidth={62} overlap={22} />
          : <div className="h-[87px] w-[62px] rounded-xl border-2 border-dashed border-white/10" />
        }
        {game.phase !== 'idle' && dealerTotal && (
          <span className={`text-2xl font-bold ${dealerTotal.total > 21 ? 'text-red-400' : 'text-[#f9f5e3]'}`}>
            {game.phase === 'playerTurn' ? (game.dealerCards[0] ? calcTotal([game.dealerCards[0]]).total : '') : (dealerTotal.total > 21 ? 'BUST' : dealerTotal.total)}
          </span>
        )}
      </div>

      {/* Player spots */}
      <div className="flex-1 flex items-center justify-center gap-4 px-4">
        {game.spots.length === 0 ? (
          <div className="flex flex-col items-center gap-2 opacity-40">
            <span className="text-5xl">♣</span>
            <span className="text-[#a09880] text-sm">Tap Deal to start</span>
          </div>
        ) : (
          game.spots.map((spot, spotIdx) => (
            <div
              key={spot.id}
              className={`flex flex-col items-center gap-2 p-3 rounded-2xl transition ${spotIdx === game.activeSpotIndex && game.phase === 'playerTurn' ? 'bg-white/7 ring-1 ring-[#b89a4d]/50' : ''}`}
            >
              {spot.hands.map((hand, handIdx) => (
                <div key={handIdx} className="flex flex-col items-center gap-1">
                  <CardStack cards={hand.cards} cardWidth={58} overlap={20} />
                  <span className={`text-xl font-bold ${hand.isBust ? 'text-red-400' : (spotIdx === game.activeSpotIndex && handIdx === spot.activeHandIndex ? 'text-[#b89a4d]' : 'text-[#f9f5e3]')}`}>
                    {hand.isBust ? 'BUST' : hand.total}
                  </span>
                  {game.phase === 'roundOver' && spot.outcomes[handIdx] && (
                    <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${outcomeBadge(spot.outcomes[handIdx])}`}>
                      {spot.outcomes[handIdx].toUpperCase()}
                    </span>
                  )}
                </div>
              ))}
            </div>
          ))
        )}
      </div>

      {/* Session strip */}
      <div className="flex justify-center gap-8 py-3">
        <Stat label="SESSION" value={`${accuracy}%`} highlight />
        <Stat label="CORRECT" value={String(sessionCorrect)} />
        <Stat label="HANDS" value={String(sessionTotal)} />
      </div>

      {/* Action buttons / Deal */}
      <div className="px-4 pb-8">
        {game.phase === 'playerTurn' ? (
          <ActionButtons available={available} onAction={handleAction} />
        ) : (
          <button
            onClick={handleDeal}
            className="w-full py-4 rounded-2xl bg-[#b89a4d] text-black font-bold text-xl hover:bg-[#cead5a] transition"
          >
            {game.phase === 'idle' ? 'Deal' : 'Next Hand'}
          </button>
        )}
      </div>

      {/* Coaching overlay */}
      {showCoaching && game.lastCoachingEntry && (
        <CoachingCard entry={game.lastCoachingEntry} onDismiss={dismissCoaching} />
      )}
    </div>
  )
}

function Stat({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  return (
    <div className="flex flex-col items-center gap-0.5">
      <span className={`text-lg font-bold ${highlight ? 'text-[#b89a4d]' : 'text-[#f9f5e3]'}`}>{value}</span>
      <span className="text-[10px] font-semibold text-[#a09880] tracking-widest">{label}</span>
    </div>
  )
}

function outcomeBadge(outcome: string): string {
  const map: Record<string, string> = {
    win: 'bg-green-700 text-white',
    blackjack: 'bg-green-600 text-white',
    lose: 'bg-red-800 text-white',
    bust: 'bg-red-900 text-white',
    push: 'bg-gray-600 text-white',
    surrender: 'bg-purple-800 text-white',
  }
  return map[outcome] ?? 'bg-gray-700 text-white'
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

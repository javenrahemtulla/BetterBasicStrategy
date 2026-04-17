import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'

import { Colors, outcomeColor, outcomeLabel, shared } from '../theme'
import { DEFAULT_RULES, type DecisionCategory, type GameState, type StrategyEntry } from '../types'
import { createShoe } from '../engine/shoe'
import { penetration } from '../engine/shoe'
import { initialGameState, dealNewRound, getAvailableActions, performAction } from '../engine/gameEngine'
import { BasicStrategyEngine } from '../engine/basicStrategyEngine'
import { calcTotal } from '../engine/hand'
import type { ShoeState } from '../engine/shoe'

import { loadShoe, saveShoe, clearShoe } from '../storage/shoe'
import { createSession, updateSession, upsertHand } from '../services/SupabaseService'

import { CardStack } from '../components/CardView'
import { ActionButtons } from '../components/ActionButtons'
import { CoachingCard } from '../components/CoachingCard'
import { PenetrationBar } from '../components/PenetrationBar'

interface Props {
  userId: string
  username: string
  onStats: () => void
}

const rules = DEFAULT_RULES

export function GameScreen({ userId, username, onStats }: Props) {
  const engine = useMemo(() => new BasicStrategyEngine(rules), [])

  const [shoe, setShoe]                   = useState<ShoeState | null>(null)
  const [game, setGame]                   = useState<GameState>(() => initialGameState())
  const [sessionId, setSessionId]         = useState<string | null>(null)
  const [coachEntry, setCoachEntry]       = useState<StrategyEntry | null>(null)
  const [actionLocked, setActionLocked]   = useState(false)

  const handIdxRef   = useRef(0)
  const sessStatsRef = useRef({ hands: 0, correct: 0, incorrect: 0 })

  // ── Init ───────────────────────────────────────────────────────────────────

  useEffect(() => {
    async function init() {
      const saved = await loadShoe()
      const s = (saved && saved.cards.length > 0) ? saved : createShoe(rules.penetrationPercent)
      setShoe(s)
      try {
        const sess = await createSession(userId)
        setSessionId(sess.id)
      } catch (_) {}
    }
    init()
  }, [userId])

  // ── Session helpers ────────────────────────────────────────────────────────

  const rotateSession = useCallback(async () => {
    if (sessionId) {
      updateSession(sessionId, {
        ended_at: new Date().toISOString(),
        hands_played: sessStatsRef.current.hands,
        correct_decisions: sessStatsRef.current.correct,
        incorrect_decisions: sessStatsRef.current.incorrect,
      }).catch(() => {})
    }
    try {
      const sess = await createSession(userId)
      setSessionId(sess.id)
    } catch (_) {}
    sessStatsRef.current = { hands: 0, correct: 0, incorrect: 0 }
    handIdxRef.current   = 0
    await clearShoe()
  }, [sessionId, userId])

  const recordRound = useCallback(async (state: GameState, currentSessionId: string | null) => {
    if (!currentSessionId) return
    const upcard = state.dealerCards[0]
    let handsThisRound = 0, correctThisRound = 0, incorrectThisRound = 0

    for (let si = 0; si < state.spots.length; si++) {
      const spot = state.spots[si]
      for (let hi = 0; hi < spot.hands.length; hi++) {
        const hand    = spot.hands[hi]
        const actions = spot.actions[hi] ?? []
        const outcome = spot.outcomes[hi] ?? 'lose'
        const c = actions.filter(a => a.wasCorrect).length
        const w = actions.filter(a => !a.wasCorrect).length

        handsThisRound++
        correctThisRound   += c
        incorrectThisRound += w

        try {
          await upsertHand({
            session_id: currentSessionId,
            user_id: userId,
            hand_index: handIdxRef.current * 10 + si * 4 + hi,
            hand_type: hand.handType,
            player_total: hand.total,
            dealer_upcard_rank: upcard?.rank ?? 10,
            outcome,
            actions_taken: actions,
            was_correct: actions.length > 0 && actions.every(a => a.wasCorrect),
          })
        } catch (_) {}
      }
    }

    handIdxRef.current++
    sessStatsRef.current.hands      += handsThisRound
    sessStatsRef.current.correct    += correctThisRound
    sessStatsRef.current.incorrect  += incorrectThisRound

    updateSession(currentSessionId, {
      hands_played:        sessStatsRef.current.hands,
      correct_decisions:   sessStatsRef.current.correct,
      incorrect_decisions: sessStatsRef.current.incorrect,
    }).catch(() => {})
  }, [userId])

  // ── Deal ───────────────────────────────────────────────────────────────────

  async function handleDeal() {
    if (!shoe) return
    const { state, shoe: newShoe, reshuffled } = dealNewRound(game, shoe, rules)

    if (reshuffled) {
      await rotateSession()
      setShoe(newShoe)
      setGame(state)
    } else {
      await saveShoe(newShoe)
      setShoe(newShoe)
      setGame(state)
    }
    setCoachEntry(null)
    setActionLocked(false)
  }

  // ── Player action ──────────────────────────────────────────────────────────

  function handleAction(action: DecisionCategory) {
    if (!shoe || actionLocked) return
    setActionLocked(true)

    const { state, shoe: newShoe } = performAction(game, shoe, action, rules, engine)

    if (state.lastActionWasCorrect === false && state.lastCoachingEntry) {
      setCoachEntry(state.lastCoachingEntry)
    }

    saveShoe(newShoe).catch(() => {})
    setShoe(newShoe)
    setGame(state)

    if (state.phase === 'roundOver') {
      recordRound(state, sessionId)
    }

    // Unlock after a tick so rapid taps don't double-fire
    if (state.phase !== 'roundOver') {
      setTimeout(() => setActionLocked(false), 50)
    }
  }

  function dismissCoaching() {
    setCoachEntry(null)
    setActionLocked(false)
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  const available = game.phase === 'playerTurn' ? getAvailableActions(game, rules) : new Set<DecisionCategory>()
  const shoePen   = shoe ? penetration(shoe) : 0
  const activeSpot = game.spots[game.activeSpotIndex]

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <SafeAreaView style={shared.screenBg}>
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.username}>{username}</Text>
          <PenetrationBar penetration={shoePen} trigger={rules.penetrationPercent} />
        </View>
        <TouchableOpacity onPress={onStats} style={styles.statsBtn}>
          <Text style={styles.statsBtnLabel}>STATS</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scroll} bounces={false}>

        {/* Dealer */}
        <View style={styles.section}>
          <Text style={shared.sectionTitle}>Dealer</Text>
          {game.dealerCards.length > 0
            ? <CardStack cards={game.dealerCards} hideHole={!game.dealerHoleRevealed && game.phase !== 'roundOver'} />
            : <Text style={styles.waiting}>Waiting for deal…</Text>}
          {game.phase === 'roundOver' && (
            <Text style={styles.dealerTotal}>
              {(({ total }) => total > 21 ? `Bust (${total})` : String(total))(calcTotal(game.dealerCards))}
            </Text>
          )}
        </View>

        {/* Player spots */}
        {game.spots.map((spot, si) => (
          <View key={spot.id} style={[styles.section, si === game.activeSpotIndex && game.phase === 'playerTurn' && styles.activeSection]}>
            <Text style={shared.sectionTitle}>
              {rules.numberOfSpots > 1 ? `Spot ${si + 1}` : 'Your Hand'}
              {si === game.activeSpotIndex && game.phase === 'playerTurn' ? ' ▸' : ''}
            </Text>
            {spot.hands.map((hand, hi) => (
              <View key={hi} style={styles.handRow}>
                <CardStack cards={hand.cards} small={spot.hands.length > 1} />
                <View style={styles.handInfo}>
                  <Text style={styles.handTotal}>{hand.total}{hand.isSoft ? ' soft' : ''}</Text>
                  {game.phase === 'roundOver' && spot.outcomes[hi] && (
                    <View style={[styles.outcomeBadge, { backgroundColor: outcomeColor[spot.outcomes[hi]] }]}>
                      <Text style={styles.outcomeText}>{outcomeLabel[spot.outcomes[hi]]}</Text>
                    </View>
                  )}
                </View>
              </View>
            ))}
          </View>
        ))}

        {/* Coaching message (inline for wrong but non-modal confirmation) */}
        {game.phase === 'playerTurn' && game.lastActionWasCorrect === true && (
          <View style={styles.correctBanner}>
            <Text style={styles.correctText}>✓ Correct!</Text>
          </View>
        )}

      </ScrollView>

      {/* Controls */}
      <View style={styles.controls}>
        {(game.phase === 'idle' || game.phase === 'roundOver') && (
          <TouchableOpacity style={styles.dealBtn} onPress={handleDeal} activeOpacity={0.8} disabled={!shoe}>
            <Text style={styles.dealLabel}>{game.phase === 'idle' ? 'DEAL' : 'NEXT HAND'}</Text>
          </TouchableOpacity>
        )}
        {game.phase === 'playerTurn' && (
          <ActionButtons available={available} onAction={handleAction} disabled={actionLocked || !!coachEntry} />
        )}
        {game.phase === 'dealerTurn' && (
          <View style={styles.dealerPlaying}>
            <Text style={styles.dealerPlayingText}>Dealer playing…</Text>
          </View>
        )}
      </View>

      <CoachingCard entry={coachEntry} onDismiss={dismissCoaching} />
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 16, paddingTop: 4, paddingBottom: 12,
    borderBottomWidth: 1, borderBottomColor: Colors.feltDark,
  },
  username:     { color: Colors.cream, fontWeight: '700', fontSize: 15, marginBottom: 4 },
  statsBtn:     { backgroundColor: Colors.feltDark, paddingHorizontal: 14, paddingVertical: 8, borderRadius: 8, borderWidth: 1, borderColor: Colors.gold + '66' },
  statsBtnLabel: { color: Colors.gold, fontWeight: '700', fontSize: 13 },
  scroll:       { padding: 16, gap: 12, paddingBottom: 8 },
  section:      { backgroundColor: Colors.feltDark, borderRadius: 12, padding: 14 },
  activeSection: { borderWidth: 1, borderColor: Colors.gold + '88' },
  waiting:      { color: Colors.muted, fontSize: 14 },
  dealerTotal:  { color: Colors.cream, fontSize: 14, marginTop: 6 },
  handRow:      { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 6 },
  handInfo:     { flex: 1, gap: 4 },
  handTotal:    { color: Colors.cream, fontSize: 18, fontWeight: '700' },
  outcomeBadge: { alignSelf: 'flex-start', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 6 },
  outcomeText:  { color: Colors.white, fontWeight: '800', fontSize: 12, letterSpacing: 0.5 },
  correctBanner: { backgroundColor: Colors.hit + '33', borderRadius: 8, padding: 10, alignItems: 'center' },
  correctText:  { color: Colors.green, fontWeight: '700', fontSize: 14 },
  controls:     { padding: 16, paddingBottom: 8, borderTopWidth: 1, borderTopColor: Colors.feltDark },
  dealBtn:      { backgroundColor: Colors.gold, borderRadius: 12, paddingVertical: 18, alignItems: 'center' },
  dealLabel:    { color: Colors.feltDark, fontWeight: '800', fontSize: 17, letterSpacing: 1 },
  dealerPlaying: { padding: 16, alignItems: 'center' },
  dealerPlayingText: { color: Colors.muted, fontSize: 14 },
})

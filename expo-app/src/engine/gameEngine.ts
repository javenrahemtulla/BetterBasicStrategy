import type { ActionRecord, Card, DecisionCategory, GameState, Outcome, RuleSet, SpotState } from '../types'
import { makeCard } from './card'
import { buildHandState, calcTotal } from './hand'
import { dealCard, needsReshuffle, createShoe } from './shoe'
import type { ShoeState } from './shoe'
import { BasicStrategyEngine, resolveAction, actionCategory } from './basicStrategyEngine'
import { strategyRank } from './card'

function makeSpot(id: string): SpotState {
  return { id, hands: [buildHandState([])], activeHandIndex: 0, outcomes: ['lose'], actions: [[]], isComplete: false }
}

export function initialGameState(): GameState {
  return { phase: 'idle', spots: [], activeSpotIndex: 0, dealerCards: [], dealerHoleRevealed: false, lastActionWasCorrect: null, lastCoachingEntry: null }
}

// ─── Deal ────────────────────────────────────────────────────────────────────

export function dealNewRound(
  state: GameState, shoe: ShoeState, rules: RuleSet
): { state: GameState; shoe: ShoeState; reshuffled: boolean } {
  const wasReshuffle = needsReshuffle(shoe)
  let s = wasReshuffle ? createShoe(shoe.penetrationTrigger) : shoe

  const spots: SpotState[] = Array.from({ length: rules.numberOfSpots }, (_, i) =>
    makeSpot(`spot-${i}-${Date.now()}`)
  )
  const dealerCards: Card[] = []

  for (let pass = 0; pass < 2; pass++) {
    for (let i = 0; i < spots.length; i++) {
      const result = dealCard(s)
      if (!result) continue
      s = result.shoe
      spots[i].hands[0] = buildHandState([...spots[i].hands[0].cards, result.card])
    }
    const result = dealCard(s)
    if (result) { dealerCards.push(result.card); s = result.shoe }
  }

  for (const spot of spots) {
    if (spot.hands[0].isBlackjack) { spot.isComplete = true; spot.outcomes = ['blackjack'] }
  }

  const newState: GameState = { phase: 'playerTurn', spots, activeSpotIndex: 0, dealerCards, dealerHoleRevealed: false, lastActionWasCorrect: null, lastCoachingEntry: null }

  if (spots.every(sp => sp.isComplete)) {
    const r = playDealer({ ...newState }, s, rules)
    return { state: r.state, shoe: r.shoe, reshuffled: wasReshuffle }
  }

  const first = spots.findIndex(sp => !sp.isComplete)
  newState.activeSpotIndex = first >= 0 ? first : 0
  return { state: newState, shoe: s, reshuffled: wasReshuffle }
}

// ─── Player actions ───────────────────────────────────────────────────────────

export function getAvailableActions(state: GameState, rules: RuleSet): Set<DecisionCategory> {
  if (state.phase !== 'playerTurn') return new Set()
  const spot = state.spots[state.activeSpotIndex]
  if (!spot) return new Set()
  const hand = spot.hands[spot.activeHandIndex]
  if (!hand) return new Set()

  const available: Set<DecisionCategory> = new Set(['hit', 'stand'])

  if (hand.cards.length === 2) {
    const isAfterSplit = spot.hands.length > 1
    if (!isAfterSplit || rules.doubleAfterSplit) available.add('double')

    const r1 = strategyRank(hand.cards[0].rank)
    const r2 = strategyRank(hand.cards[1].rank)
    if (r1 === r2) {
      const handsCount = spot.hands.length
      const isAce = hand.cards[0].rank === 14
      if (handsCount < 4 && (!isAce || rules.resplitAces)) available.add('split')
      if (handsCount === 1) available.add('split')
    }
  }

  if (hand.cards.length === 2 && spot.actions[spot.activeHandIndex].length === 0 && rules.surrenderRule !== 'none') {
    available.add('surrender')
  }

  return available
}

export function performAction(
  state: GameState, shoe: ShoeState, category: DecisionCategory, rules: RuleSet, engine: BasicStrategyEngine
): { state: GameState; shoe: ShoeState } {
  let s = shoe
  const spots = state.spots.map(sp => ({ ...sp, hands: [...sp.hands], actions: sp.actions.map(a => [...a]), outcomes: [...sp.outcomes] }))
  const spot = spots[state.activeSpotIndex]
  const hand = spot.hands[spot.activeHandIndex]
  const dealerUpcard = state.dealerCards[0]

  const available   = getAvailableActions(state, rules)
  const canDouble   = available.has('double')
  const canSplit    = available.has('split')
  const canSurrender = available.has('surrender')

  const rawCorrect    = engine.correctAction(hand.handKey, dealerUpcard)
  const resolved      = resolveAction(rawCorrect, canDouble, canSplit, canSurrender)
  const correctCat    = actionCategory(resolved)
  const isCorrect     = correctCat === category
  const entry         = engine.getEntry(hand.handKey, dealerUpcard)

  const record: ActionRecord = { action: category, wasCorrect: isCorrect, correctAction: resolved, explanation: entry?.explanation ?? '' }
  spot.actions[spot.activeHandIndex] = [...spot.actions[spot.activeHandIndex], record]

  let newState: GameState = { ...state, spots, lastActionWasCorrect: isCorrect, lastCoachingEntry: isCorrect ? null : (entry ?? null) }

  switch (category) {
    case 'hit': {
      const result = dealCard(s)
      if (result) {
        s = result.shoe
        spot.hands[spot.activeHandIndex] = buildHandState([...hand.cards, result.card])
        if (spot.hands[spot.activeHandIndex].total >= 21) {
          return { state: advanceHand({ ...newState, spots }, s, rules), shoe: s }
        }
      }
      break
    }
    case 'stand':
      return { state: advanceHand({ ...newState, spots }, s, rules), shoe: s }
    case 'double': {
      const result = dealCard(s)
      if (result) { s = result.shoe; spot.hands[spot.activeHandIndex] = buildHandState([...hand.cards, result.card]) }
      return { state: advanceHand({ ...newState, spots }, s, rules), shoe: s }
    }
    case 'split': {
      const splitCard = hand.cards[1]
      const fill1 = dealCard(s); if (fill1) s = fill1.shoe
      const fill2 = dealCard(s); if (fill2) s = fill2.shoe
      spot.hands[spot.activeHandIndex] = buildHandState([hand.cards[0], ...(fill1 ? [fill1.card] : [])])
      const newHand = buildHandState([splitCard, ...(fill2 ? [fill2.card] : [])])
      spot.hands = [...spot.hands.slice(0, spot.activeHandIndex + 1), newHand, ...spot.hands.slice(spot.activeHandIndex + 1)]
      spot.actions = [...spot.actions.slice(0, spot.activeHandIndex + 1), [], ...spot.actions.slice(spot.activeHandIndex + 1)]
      spot.outcomes = [...spot.outcomes, 'lose']
      if (hand.cards[0].rank === 14 && !rules.resplitAces) {
        return { state: advanceHand({ ...newState, spots }, s, rules), shoe: s }
      }
      break
    }
    case 'surrender':
      spot.outcomes = ['surrender']; spot.isComplete = true
      return { state: advanceIfNeeded({ ...newState, spots }, s, rules), shoe: s }
  }

  return { state: { ...newState, spots }, shoe: s }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

function advanceHand(state: GameState, shoe: ShoeState, rules: RuleSet): GameState {
  const spots = [...state.spots]
  const spot = { ...spots[state.activeSpotIndex] }
  const next = spot.activeHandIndex + 1
  if (next < spot.hands.length) {
    spots[state.activeSpotIndex] = { ...spot, activeHandIndex: next }
    return { ...state, spots }
  }
  spots[state.activeSpotIndex] = { ...spot, isComplete: true }
  return advanceIfNeeded({ ...state, spots }, shoe, rules)
}

function advanceIfNeeded(state: GameState, shoe: ShoeState, rules: RuleSet): GameState {
  const next = state.spots.findIndex((sp, i) => !sp.isComplete && i > state.activeSpotIndex)
  if (next >= 0) return { ...state, activeSpotIndex: next }
  if (state.spots.every(sp => sp.isComplete)) return playDealer(state, shoe, rules).state
  return state
}

function playDealer(state: GameState, shoe: ShoeState, rules: RuleSet): { state: GameState; shoe: ShoeState } {
  let s = shoe
  let dealerCards = [...state.dealerCards]
  while (shouldDealerHit(dealerCards, rules)) {
    const result = dealCard(s)
    if (!result) break
    s = result.shoe; dealerCards = [...dealerCards, result.card]
  }
  const resolved = resolveOutcomes({ ...state, dealerCards, dealerHoleRevealed: true, phase: 'dealerTurn' })
  return { state: { ...resolved, phase: 'roundOver' }, shoe: s }
}

function shouldDealerHit(cards: Card[], rules: RuleSet): boolean {
  const { total, isSoft } = calcTotal(cards)
  if (total < 17) return true
  if (total === 17 && isSoft && rules.dealerRule === 'H17') return true
  return false
}

function resolveOutcomes(state: GameState): GameState {
  const { total: dealerTotal } = calcTotal(state.dealerCards)
  const dealerBust = dealerTotal > 21
  const spots = state.spots.map(spot => {
    if (spot.outcomes[0] === 'surrender') return spot
    const outcomes: Outcome[] = spot.hands.map((hand, i) => {
      if (spot.outcomes[i] === 'blackjack') return 'blackjack'
      if (hand.total > 21) return 'bust'
      if (dealerBust) return 'win'
      if (hand.total > dealerTotal) return 'win'
      if (hand.total === dealerTotal) return 'push'
      return 'lose'
    })
    return { ...spot, outcomes, isComplete: true }
  })
  return { ...state, spots, dealerHoleRevealed: true }
}

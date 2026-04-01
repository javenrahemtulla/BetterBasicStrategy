// ─── Card ────────────────────────────────────────────────────────────────────

export type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades'
export type Rank = 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14
// 11=Jack, 12=Queen, 13=King, 14=Ace

export interface Card {
  suit: Suit
  rank: Rank
  id: string // unique per card instance in shoe
}

// ─── Hand ─────────────────────────────────────────────────────────────────────

export type HandType = 'hard' | 'soft' | 'pair'

export interface HandState {
  cards: Card[]
  total: number
  isSoft: boolean
  isBust: boolean
  isBlackjack: boolean
  handType: HandType
  handKey: HandKey
}

export type HandKey =
  | { type: 'hard'; total: number }
  | { type: 'soft'; total: number }
  | { type: 'pair'; rank: number } // strategy rank (J/Q/K → 10)

// ─── Actions ──────────────────────────────────────────────────────────────────

export type RawAction =
  | 'hit'
  | 'stand'
  | 'doubleOrHit'
  | 'doubleOrStand'
  | 'split'
  | 'surrenderOrHit'
  | 'surrenderOrStand'
  | 'surrenderOrSplit'

export type DecisionCategory = 'hit' | 'stand' | 'double' | 'split' | 'surrender'

// ─── Rules ────────────────────────────────────────────────────────────────────

export type DealerRule = 'H17' | 'S17'
export type SurrenderRule = 'none' | 'late' | 'early'
export type BlackjackPays = '3:2' | '6:5'

export interface RuleSet {
  dealerRule: DealerRule
  doubleAfterSplit: boolean
  resplitAces: boolean
  surrenderRule: SurrenderRule
  blackjackPays: BlackjackPays
  numberOfSpots: number
  penetrationPercent: number
}

export const DEFAULT_RULES: RuleSet = {
  dealerRule: 'H17',
  doubleAfterSplit: true,
  resplitAces: false,
  surrenderRule: 'late',
  blackjackPays: '3:2',
  numberOfSpots: 1,
  penetrationPercent: 0.75,
}

// ─── Strategy ─────────────────────────────────────────────────────────────────

export interface StrategyEntry {
  action: RawAction
  explanation: string
}

export type StrategyTableMap = Map<string, Map<number, StrategyEntry>>

// ─── Game State ───────────────────────────────────────────────────────────────

export type GamePhase = 'idle' | 'playerTurn' | 'dealerTurn' | 'roundOver'

export type Outcome = 'win' | 'lose' | 'push' | 'blackjack' | 'surrender' | 'bust'

export interface ActionRecord {
  action: DecisionCategory
  wasCorrect: boolean
  correctAction: RawAction
  explanation: string
}

export interface SpotState {
  id: string
  hands: HandState[]
  activeHandIndex: number
  outcomes: Outcome[]
  actions: ActionRecord[][]
  isComplete: boolean
}

export interface GameState {
  phase: GamePhase
  spots: SpotState[]
  activeSpotIndex: number
  dealerCards: Card[]
  dealerHoleRevealed: boolean
  lastActionWasCorrect: boolean | null
  lastCoachingEntry: StrategyEntry | null
}

// ─── DB / User ────────────────────────────────────────────────────────────────

export interface User {
  id: string
  username: string
  created_at: string
}

export interface GameSession {
  id: string
  user_id: string
  started_at: string
  ended_at: string | null
  rules_snapshot: RuleSet
  hands_played: number
  correct_decisions: number
  incorrect_decisions: number
}

export interface HandRecord {
  id: string
  session_id: string
  user_id: string
  timestamp: string
  spot_number: number
  player_cards: Card[]
  dealer_upcard: Card
  dealer_final_hand: Card[]
  hand_type: HandType
  player_total: number
  actions_taken: ActionRecord[]
  outcome: Outcome
  was_split: boolean
  was_doubled: boolean
  was_surrendered: boolean
}

// ─── Stats ────────────────────────────────────────────────────────────────────

export interface OutcomeCounts {
  wins: number
  losses: number
  pushes: number
  blackjacks: number
  surrenders: number
}

export interface StatsData {
  lifetimeHands: number
  lifetimeDecisions: number
  lifetimeAccuracy: number
  currentStreak: number
  longestStreak: number
  shoesPlayed: number
  outcomeCounts: OutcomeCounts
  accuracyByHandType: { label: string; accuracy: number; total: number }[]
  accuracyByDealerUpcard: { rank: string; accuracy: number; total: number }[]
  topMistakes: { label: string; count: number; correctAction: string }[]
  recentSessions: GameSession[]
}

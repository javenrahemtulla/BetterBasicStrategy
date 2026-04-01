import type { RawAction, RuleSet, StrategyEntry, StrategyTableMap } from '@/lib/types'

// dealer ranks used as keys: 2–10, 14(Ace)
const DEALER_RANKS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 14]

type EntryDef = [number, RawAction, string] // [dealerRank, action, explanation]

function buildKey(type: string, value: number): string {
  return `${type}-${value}`
}

function makeMap(entries: EntryDef[]): Map<number, StrategyEntry> {
  return new Map(entries.map(([rank, action, explanation]) => [rank, { action, explanation }]))
}

function allDealers(action: RawAction, explanation: string): EntryDef[] {
  return DEALER_RANKS.map(d => [d, action, explanation])
}

// ─── Baseline H17 / DAS on / No Surrender ─────────────────────────────────────

function buildBaselineTable(): StrategyTableMap {
  const t: StrategyTableMap = new Map()

  const set = (key: string, entries: EntryDef[]) => t.set(key, makeMap(entries))

  // ── HARD TOTALS ──────────────────────────────────────────────────────────────

  for (let total = 5; total <= 8; total++) {
    set(buildKey('hard', total), allDealers('hit', `Hard ${total} is too weak to stand on. Always hit.`))
  }

  set(buildKey('hard', 9), DEALER_RANKS.map(d => [
    d,
    (d >= 3 && d <= 6) ? 'doubleOrHit' : 'hit',
    (d >= 3 && d <= 6)
      ? `Hard 9 vs ${d}: double to maximize profit against a weak dealer.`
      : `Hard 9 vs ${d}: dealer is too strong; just hit.`,
  ]))

  set(buildKey('hard', 10), DEALER_RANKS.map(d => [
    d,
    (d >= 2 && d <= 9) ? 'doubleOrHit' : 'hit',
    (d >= 2 && d <= 9)
      ? `Hard 10 vs ${d}: great doubling opportunity — you likely have the stronger hand.`
      : `Hard 10 vs ${d}: dealer's 10 or Ace is too strong; just hit.`,
  ]))

  // Hard 11: H17 = Double vs 2–10, Hit vs Ace
  set(buildKey('hard', 11), DEALER_RANKS.map(d => [
    d,
    d !== 14 ? 'doubleOrHit' : 'hit',
    d !== 14
      ? `Hard 11 vs ${d}: best doubling hand in the game.`
      : `Hard 11 vs Ace (H17): dealer has too much power; hit instead of doubling.`,
  ]))

  set(buildKey('hard', 12), DEALER_RANKS.map(d => [
    d,
    (d >= 4 && d <= 6) ? 'stand' : 'hit',
    (d >= 4 && d <= 6)
      ? `Hard 12 vs ${d}: dealer likely busts; stand and let them.`
      : `Hard 12 vs ${d}: take a card — risk of busting is worth it.`,
  ]))

  for (let total = 13; total <= 16; total++) {
    set(buildKey('hard', total), DEALER_RANKS.map(d => [
      d,
      (d >= 2 && d <= 6) ? 'stand' : 'hit',
      (d >= 2 && d <= 6)
        ? `Hard ${total} vs ${d}: dealer's bust card; stand and hope they break.`
        : `Hard ${total} vs ${d}: you're behind but hitting gives a chance.`,
    ]))
  }

  for (let total = 17; total <= 21; total++) {
    set(buildKey('hard', total), allDealers('stand', `Hard ${total}: strong enough — stand.`))
  }

  // ── SOFT TOTALS ──────────────────────────────────────────────────────────────

  // Soft 13 (A-2) & Soft 14 (A-3): Double vs 5–6, else Hit
  for (const total of [13, 14]) {
    const name = total === 13 ? 'A-2' : 'A-3'
    set(buildKey('soft', total), DEALER_RANKS.map(d => [
      d,
      (d === 5 || d === 6) ? 'doubleOrHit' : 'hit',
      (d === 5 || d === 6)
        ? `${name} vs ${d}: great double — dealer very likely to bust.`
        : `${name} vs ${d}: not enough edge to double; hit.`,
    ]))
  }

  // Soft 15 (A-4) & Soft 16 (A-5): Double vs 4–6, else Hit
  for (const total of [15, 16]) {
    const name = total === 15 ? 'A-4' : 'A-5'
    set(buildKey('soft', total), DEALER_RANKS.map(d => [
      d,
      (d >= 4 && d <= 6) ? 'doubleOrHit' : 'hit',
      (d >= 4 && d <= 6)
        ? `${name} vs ${d}: dealer in bust zone; double.`
        : `${name} vs ${d}: take a free hit — can't bust.`,
    ]))
  }

  // Soft 17 (A-6): Double vs 3–6, else Hit
  set(buildKey('soft', 17), DEALER_RANKS.map(d => [
    d,
    (d >= 3 && d <= 6) ? 'doubleOrHit' : 'hit',
    (d >= 3 && d <= 6)
      ? `A-6 vs ${d}: double to maximize against weak dealer.`
      : `A-6 vs ${d}: 17 isn't great; hit for a chance at 18–21.`,
  ]))

  // Soft 18 (A-7): Double vs 3–6, Stand vs 2/7/8, Hit vs 9/10/A
  set(buildKey('soft', 18), DEALER_RANKS.map(d => {
    let action: RawAction
    let expl: string
    if (d >= 3 && d <= 6) {
      action = 'doubleOrStand'
      expl = `A-7 vs ${d}: soft 18 is strong, but double to squeeze more value.`
    } else if (d === 2 || d === 7 || d === 8) {
      action = 'stand'
      expl = `A-7 vs ${d}: 18 beats this dealer total; stand.`
    } else {
      action = 'hit'
      expl = `A-7 vs ${d}: dealer likely makes 19–20; hit for a better total.`
    }
    return [d, action, expl]
  }))

  for (const total of [19, 20]) {
    set(buildKey('soft', total), allDealers('stand', `Soft ${total} is a monster hand — always stand.`))
  }

  // ── PAIRS ─────────────────────────────────────────────────────────────────────

  // 2-2 & 3-3: Split vs 2–7, else Hit
  for (const rank of [2, 3]) {
    set(buildKey('pair', rank), DEALER_RANKS.map(d => [
      d,
      (d >= 2 && d <= 7) ? 'split' : 'hit',
      (d >= 2 && d <= 7)
        ? `${rank}-${rank} vs ${d}: split to create two better hands.`
        : `${rank}-${rank} vs ${d}: too risky to split; hit.`,
    ]))
  }

  // 4-4: Split vs 5–6, else Hit
  set(buildKey('pair', 4), DEALER_RANKS.map(d => [
    d,
    (d === 5 || d === 6) ? 'split' : 'hit',
    (d === 5 || d === 6)
      ? `4-4 vs ${d}: split for two strong starting hands against a weak dealer.`
      : `4-4 vs ${d}: keep the 8; hitting is better.`,
  ]))

  // 5-5: Never split — treat as Hard 10
  set(buildKey('pair', 5), DEALER_RANKS.map(d => [
    d,
    (d >= 2 && d <= 9) ? 'doubleOrHit' : 'hit',
    `5-5 is really hard 10 — never split fives. ` +
      ((d >= 2 && d <= 9) ? 'Double for maximum value.' : 'Dealer too strong; hit.'),
  ]))

  // 6-6: Split vs 2–6, else Hit
  set(buildKey('pair', 6), DEALER_RANKS.map(d => [
    d,
    (d >= 2 && d <= 6) ? 'split' : 'hit',
    (d >= 2 && d <= 6)
      ? `6-6 vs ${d}: split; 12 is bad, two 16s give flexibility against weak dealer.`
      : `6-6 vs ${d}: splitting creates two bad hands; hit the 12.`,
  ]))

  // 7-7: Split vs 2–7, else Hit
  set(buildKey('pair', 7), DEALER_RANKS.map(d => [
    d,
    (d >= 2 && d <= 7) ? 'split' : 'hit',
    (d >= 2 && d <= 7)
      ? `7-7 vs ${d}: split; 14 is weak, two 17s are competitive.`
      : `7-7 vs ${d}: don't split into two worse hands; hit.`,
  ]))

  // 8-8: Always Split
  set(buildKey('pair', 8), allDealers('split', 'Always split 8s — 16 is the worst hand in blackjack. Two 18s are far better.'))

  // 9-9: Split vs 2–9 except 7, Stand vs 7/10/A
  set(buildKey('pair', 9), DEALER_RANKS.map(d => [
    d,
    (d === 7 || d === 10 || d === 14) ? 'stand' : 'split',
    (d === 7 || d === 10 || d === 14)
      ? `9-9 vs ${d}: your 18 beats or ties this; stand.`
      : `9-9 vs ${d}: split to get two 19s against a vulnerable dealer.`,
  ]))

  // 10-10: Always Stand
  set(buildKey('pair', 10), allDealers('stand', 'Never split tens — 20 is one of the best hands possible.'))

  // A-A: Always Split
  set(buildKey('pair', 14), allDealers('split', 'Always split Aces — starting each hand with an Ace gives huge advantage.'))

  return t
}

// ─── Rule Overrides ───────────────────────────────────────────────────────────

function applyS17Overrides(t: StrategyTableMap): void {
  // Hard 11 vs Ace: now Double
  t.get(buildKey('hard', 11))?.set(14, {
    action: 'doubleOrHit',
    explanation: 'Hard 11 vs Ace (S17): dealer stands on soft 17, giving you edge to double.',
  })
  // Soft 18 vs Ace: now Double/Stand
  t.get(buildKey('soft', 18))?.set(14, {
    action: 'doubleOrStand',
    explanation: 'A-7 vs Ace (S17): dealer weaker; double for value.',
  })
  // Soft 19 vs 6: Double
  t.get(buildKey('soft', 19))?.set(6, {
    action: 'doubleOrStand',
    explanation: 'A-8 vs 6 (S17): exceptional double opportunity — dealer very likely to bust.',
  })
}

function applySurrenderOverrides(t: StrategyTableMap, rule: 'late' | 'early'): void {
  const late: [string, number, string][] = [
    [buildKey('hard', 16), 9, 'Hard 16 vs 9: surrender saves money long-term.'],
    [buildKey('hard', 16), 10, 'Hard 16 vs 10: worst matchup — surrendering loses only half.'],
    [buildKey('hard', 16), 14, 'Hard 16 vs Ace: surrender is better than a certain likely loss.'],
    [buildKey('hard', 15), 10, 'Hard 15 vs 10: surrender saves you money over time.'],
  ]
  for (const [key, dealer, expl] of late) {
    t.get(key)?.set(dealer, { action: 'surrenderOrHit', explanation: expl })
  }
  if (rule === 'early') {
    const early: [string, number, string][] = [
      [buildKey('hard', 14), 14, 'Hard 14 vs Ace (Early): take the half-bet.'],
      [buildKey('hard', 15), 14, 'Hard 15 vs Ace (Early): surrender.'],
      [buildKey('pair', 8), 14, '8-8 vs Ace (Early): surrender instead of splitting.'],
    ]
    for (const [key, dealer, expl] of early) {
      t.get(key)?.set(dealer, { action: 'surrenderOrHit', explanation: expl })
    }
  }
}

function applyNoDASOverrides(t: StrategyTableMap): void {
  // 2-2 & 3-3: only split vs 4–7
  for (const rank of [2, 3]) {
    for (const d of DEALER_RANKS) {
      const action: RawAction = (d >= 4 && d <= 7) ? 'split' : 'hit'
      t.get(buildKey('pair', rank))?.set(d, {
        action,
        explanation: `${rank}-${rank} vs ${d} (no DAS): ${action === 'split' ? 'split.' : "hit — can't double after split."}`,
      })
    }
  }
  // 4-4: never split
  for (const d of DEALER_RANKS) {
    t.get(buildKey('pair', 4))?.set(d, { action: 'hit', explanation: `4-4 vs ${d} (no DAS): don't split; hit the 8.` })
  }
  // 6-6: only split vs 3–6
  for (const d of DEALER_RANKS) {
    const action: RawAction = (d >= 3 && d <= 6) ? 'split' : 'hit'
    t.get(buildKey('pair', 6))?.set(d, { action, explanation: `6-6 vs ${d} (no DAS): ${action === 'split' ? 'split.' : 'hit.'}` })
  }
}

// ─── Public API ───────────────────────────────────────────────────────────────

export function buildStrategyTable(rules: RuleSet): StrategyTableMap {
  const t = buildBaselineTable()
  if (rules.dealerRule === 'S17') applyS17Overrides(t)
  if (rules.surrenderRule !== 'none') applySurrenderOverrides(t, rules.surrenderRule)
  if (!rules.doubleAfterSplit) applyNoDASOverrides(t)
  return t
}

export function lookupEntry(
  t: StrategyTableMap,
  handKey: { type: string; total?: number; rank?: number },
  dealerStrategyRank: number
): StrategyEntry | undefined {
  const key = handKey.type === 'pair'
    ? buildKey('pair', handKey.rank!)
    : buildKey(handKey.type, handKey.total!)
  return t.get(key)?.get(dealerStrategyRank)
}

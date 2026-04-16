import Foundation

typealias StrategyTableMap = [String: [Int: StrategyEntry]]

private let dealerRanks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 14]

func buildStrategyTable(rules: RuleSet) -> StrategyTableMap {
    var t = buildBaselineTable()
    if rules.dealerRule == .S17      { applyS17Overrides(&t) }
    if rules.surrenderRule != .none  { applySurrenderOverrides(&t, rule: rules.surrenderRule) }
    if !rules.doubleAfterSplit       { applyNoDASOverrides(&t) }
    return t
}

func lookupEntry(table: StrategyTableMap, handKey: HandKey, dealerStrategyRank: Int) -> StrategyEntry? {
    table[handKey.keyString]?[dealerStrategyRank]
}

// MARK: - Baseline H17 / DAS on / No Surrender

private func buildBaselineTable() -> StrategyTableMap {
    var t = StrategyTableMap()

    func set(_ key: String, _ entries: [(Int, RawAction, String)]) {
        var map = [Int: StrategyEntry]()
        for (rank, action, expl) in entries {
            map[rank] = StrategyEntry(action: action, explanation: expl)
        }
        t[key] = map
    }
    func all(_ action: RawAction, _ expl: String) -> [(Int, RawAction, String)] {
        dealerRanks.map { ($0, action, expl) }
    }

    // ── Hard totals ──────────────────────────────────────────────────────────

    for total in 5...8 {
        set("hard-\(total)", all(.hit, "Hard \(total) is too weak to stand on. Always hit."))
    }

    set("hard-9", dealerRanks.map { d in
        (d,
         (d >= 3 && d <= 6) ? .doubleOrHit : .hit,
         (d >= 3 && d <= 6) ? "Hard 9 vs \(d): double to maximize profit against a weak dealer."
                            : "Hard 9 vs \(d): dealer is too strong; just hit.")
    })

    set("hard-10", dealerRanks.map { d in
        (d,
         (d >= 2 && d <= 9) ? .doubleOrHit : .hit,
         (d >= 2 && d <= 9) ? "Hard 10 vs \(d): great doubling opportunity — you likely have the stronger hand."
                            : "Hard 10 vs \(d): dealer's 10 or Ace is too strong; just hit.")
    })

    // Hard 11: H17 = double vs 2–10, hit vs Ace
    set("hard-11", dealerRanks.map { d in
        (d,
         d != 14 ? .doubleOrHit : .hit,
         d != 14 ? "Hard 11 vs \(d): best doubling hand in the game."
                 : "Hard 11 vs Ace (H17): dealer has too much power; hit instead of doubling.")
    })

    set("hard-12", dealerRanks.map { d in
        (d,
         (d >= 4 && d <= 6) ? .stand : .hit,
         (d >= 4 && d <= 6) ? "Hard 12 vs \(d): dealer likely busts; stand and let them."
                            : "Hard 12 vs \(d): take a card — risk of busting is worth it.")
    })

    for total in 13...16 {
        set("hard-\(total)", dealerRanks.map { d in
            (d,
             (d >= 2 && d <= 6) ? .stand : .hit,
             (d >= 2 && d <= 6) ? "Hard \(total) vs \(d): dealer's bust card; stand and hope they break."
                                : "Hard \(total) vs \(d): you're behind but hitting gives a chance.")
        })
    }

    for total in 17...21 {
        set("hard-\(total)", all(.stand, "Hard \(total): strong enough — stand."))
    }

    // ── Soft totals ──────────────────────────────────────────────────────────

    for total in [13, 14] {
        let name = total == 13 ? "A-2" : "A-3"
        set("soft-\(total)", dealerRanks.map { d in
            (d,
             (d == 5 || d == 6) ? .doubleOrHit : .hit,
             (d == 5 || d == 6) ? "\(name) vs \(d): great double — dealer very likely to bust."
                                : "\(name) vs \(d): not enough edge to double; hit.")
        })
    }

    for total in [15, 16] {
        let name = total == 15 ? "A-4" : "A-5"
        set("soft-\(total)", dealerRanks.map { d in
            (d,
             (d >= 4 && d <= 6) ? .doubleOrHit : .hit,
             (d >= 4 && d <= 6) ? "\(name) vs \(d): dealer in bust zone; double."
                                : "\(name) vs \(d): take a free hit — can't bust.")
        })
    }

    set("soft-17", dealerRanks.map { d in
        (d,
         (d >= 3 && d <= 6) ? .doubleOrHit : .hit,
         (d >= 3 && d <= 6) ? "A-6 vs \(d): double to maximize against weak dealer."
                            : "A-6 vs \(d): 17 isn't great; hit for a chance at 18–21.")
    })

    set("soft-18", dealerRanks.map { d -> (Int, RawAction, String) in
        if d >= 3 && d <= 6 {
            return (d, .doubleOrStand, "A-7 vs \(d): soft 18 is strong, but double to squeeze more value.")
        } else if d == 2 || d == 7 || d == 8 {
            return (d, .stand, "A-7 vs \(d): 18 beats this dealer total; stand.")
        } else {
            return (d, .hit, "A-7 vs \(d): dealer likely makes 19–20; hit for a better total.")
        }
    })

    for total in [19, 20] {
        set("soft-\(total)", all(.stand, "Soft \(total) is a monster hand — always stand."))
    }

    // ── Pairs ────────────────────────────────────────────────────────────────

    for rank in [2, 3] {
        set("pair-\(rank)", dealerRanks.map { d in
            (d,
             (d >= 2 && d <= 7) ? .split : .hit,
             (d >= 2 && d <= 7) ? "\(rank)-\(rank) vs \(d): split to create two better hands."
                                : "\(rank)-\(rank) vs \(d): too risky to split; hit.")
        })
    }

    set("pair-4", dealerRanks.map { d in
        (d,
         (d == 5 || d == 6) ? .split : .hit,
         (d == 5 || d == 6) ? "4-4 vs \(d): split for two strong starting hands against a weak dealer."
                            : "4-4 vs \(d): keep the 8; hitting is better.")
    })

    set("pair-5", dealerRanks.map { d in
        (d,
         (d >= 2 && d <= 9) ? .doubleOrHit : .hit,
         "5-5 is really hard 10 — never split fives. " +
         ((d >= 2 && d <= 9) ? "Double for maximum value." : "Dealer too strong; hit."))
    })

    set("pair-6", dealerRanks.map { d in
        (d,
         (d >= 2 && d <= 6) ? .split : .hit,
         (d >= 2 && d <= 6) ? "6-6 vs \(d): split; 12 is bad, two 16s give flexibility against weak dealer."
                            : "6-6 vs \(d): splitting creates two bad hands; hit the 12.")
    })

    set("pair-7", dealerRanks.map { d in
        (d,
         (d >= 2 && d <= 7) ? .split : .hit,
         (d >= 2 && d <= 7) ? "7-7 vs \(d): split; 14 is weak, two 17s are competitive."
                            : "7-7 vs \(d): don't split into two worse hands; hit.")
    })

    set("pair-8",  all(.split,  "Always split 8s — 16 is the worst hand in blackjack. Two 18s are far better."))

    set("pair-9", dealerRanks.map { d in
        (d,
         (d == 7 || d == 10 || d == 14) ? .stand : .split,
         (d == 7 || d == 10 || d == 14) ? "9-9 vs \(d): your 18 beats or ties this; stand."
                                         : "9-9 vs \(d): split to get two 19s against a vulnerable dealer.")
    })

    set("pair-10", all(.stand, "Never split tens — 20 is one of the best hands possible."))
    set("pair-14", all(.split, "Always split Aces — starting each hand with an Ace gives huge advantage."))

    return t
}

// MARK: - Rule overrides

private func applyS17Overrides(_ t: inout StrategyTableMap) {
    t["hard-11"]?[14] = StrategyEntry(action: .doubleOrHit,
        explanation: "Hard 11 vs Ace (S17): dealer stands on soft 17, giving you edge to double.")
    t["soft-18"]?[14] = StrategyEntry(action: .doubleOrStand,
        explanation: "A-7 vs Ace (S17): dealer weaker; double for value.")
    t["soft-19"]?[6]  = StrategyEntry(action: .doubleOrStand,
        explanation: "A-8 vs 6 (S17): exceptional double opportunity — dealer very likely to bust.")
}

private func applySurrenderOverrides(_ t: inout StrategyTableMap, rule: SurrenderRule) {
    let late: [(String, Int, String)] = [
        ("hard-16", 9,  "Hard 16 vs 9: surrender saves money long-term."),
        ("hard-16", 10, "Hard 16 vs 10: worst matchup — surrendering loses only half."),
        ("hard-16", 14, "Hard 16 vs Ace: surrender is better than a certain likely loss."),
        ("hard-15", 10, "Hard 15 vs 10: surrender saves you money over time."),
    ]
    for (key, dealer, expl) in late {
        t[key]?[dealer] = StrategyEntry(action: .surrenderOrHit, explanation: expl)
    }
    if rule == .early {
        let early: [(String, Int, String)] = [
            ("hard-14", 14, "Hard 14 vs Ace (Early): take the half-bet."),
            ("hard-15", 14, "Hard 15 vs Ace (Early): surrender."),
            ("pair-8",  14, "8-8 vs Ace (Early): surrender instead of splitting."),
        ]
        for (key, dealer, expl) in early {
            t[key]?[dealer] = StrategyEntry(action: .surrenderOrHit, explanation: expl)
        }
    }
}

private func applyNoDASOverrides(_ t: inout StrategyTableMap) {
    for rank in [2, 3] {
        for d in dealerRanks {
            let action: RawAction = (d >= 4 && d <= 7) ? .split : .hit
            t["pair-\(rank)"]?[d] = StrategyEntry(action: action,
                explanation: "\(rank)-\(rank) vs \(d) (no DAS): \(action == .split ? "split." : "hit — can't double after split.")")
        }
    }
    for d in dealerRanks {
        t["pair-4"]?[d] = StrategyEntry(action: .hit, explanation: "4-4 vs \(d) (no DAS): don't split; hit the 8.")
    }
    for d in dealerRanks {
        let action: RawAction = (d >= 3 && d <= 6) ? .split : .hit
        t["pair-6"]?[d] = StrategyEntry(action: action, explanation: "6-6 vs \(d) (no DAS): \(action == .split ? "split." : "hit.")")
    }
}

import Foundation

// MARK: - Table Entry

struct StrategyEntry {
    let action: Action
    let explanation: String
}

typealias StrategyTableMap = [HandKey: [Rank: StrategyEntry]]

// MARK: - Strategy Table Builder

enum StrategyTable {

    /// Builds the correct strategy table for the given rule set.
    /// Baseline: H17, DAS on, No Surrender, 6 decks.
    static func build(rules: RuleSet) -> StrategyTableMap {
        var table = baselineTable()
        applyS17Overrides(to: &table, rules: rules)
        applySurrenderOverrides(to: &table, rules: rules)
        applyNoDASOverrides(to: &table, rules: rules)
        return table
    }

    // MARK: - Baseline H17/DAS/No-Surrender Table

    // swiftlint:disable function_body_length
    private static func baselineTable() -> StrategyTableMap {
        var t: StrategyTableMap = [:]

        // Helper
        func set(_ key: HandKey, _ entries: [(Rank, Action, String)]) {
            t[key] = Dictionary(uniqueKeysWithValues: entries.map { rank, action, expl in
                (rank, StrategyEntry(action: action, explanation: expl))
            })
        }

        let dealers: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]

        // ── HARD TOTALS ──────────────────────────────────────────────────────────

        // Hard 8 and below: always Hit
        for total in 5...8 {
            set(.hard(total), dealers.map { d in
                (d, .hit, "Hard \(total) is too weak to stand on. Always hit.")
            })
        }

        // Hard 9: Double vs 3–6, else Hit
        set(.hard(9), dealers.map { d in
            let action: Action = (d >= .three && d <= .six) ? .doubleOrHit : .hit
            let expl = (d >= .three && d <= .six)
                ? "Hard 9 vs dealer \(d.symbol): double to maximize profit against a weak dealer."
                : "Hard 9 vs dealer \(d.symbol): dealer is too strong; just hit."
            return (d, action, expl)
        })

        // Hard 10: Double vs 2–9, else Hit
        set(.hard(10), dealers.map { d in
            let action: Action = (d >= .two && d <= .nine) ? .doubleOrHit : .hit
            let expl = (d >= .two && d <= .nine)
                ? "Hard 10 vs dealer \(d.symbol): great doubling opportunity — you likely have the stronger hand."
                : "Hard 10 vs dealer \(d.symbol): dealer's 10 or Ace is too strong; just hit."
            return (d, action, expl)
        })

        // Hard 11: Double vs 2–10, Hit vs Ace (H17 rule)
        set(.hard(11), dealers.map { d in
            let action: Action = (d != .ace) ? .doubleOrHit : .hit
            let expl = (d != .ace)
                ? "Hard 11 vs dealer \(d.symbol): best doubling hand in the game."
                : "Hard 11 vs dealer Ace: dealer has too much power; hit instead of doubling."
            return (d, action, expl)
        })

        // Hard 12: Stand vs 4–6, else Hit
        set(.hard(12), dealers.map { d in
            let action: Action = (d >= .four && d <= .six) ? .stand : .hit
            let expl = (d >= .four && d <= .six)
                ? "Hard 12 vs dealer \(d.symbol): dealer likely busts; stand and let them."
                : "Hard 12 vs dealer \(d.symbol): risk of dealer making a hand; take a card."
            return (d, action, expl)
        })

        // Hard 13–16: Stand vs 2–6, else Hit (surrender handled separately)
        for total in 13...16 {
            set(.hard(total), dealers.map { d in
                let action: Action = (d >= .two && d <= .six) ? .stand : .hit
                let expl = (d >= .two && d <= .six)
                    ? "Hard \(total) vs dealer \(d.symbol): dealer's bust card; stand and hope they break."
                    : "Hard \(total) vs dealer \(d.symbol): you're behind but hitting gives a chance."
                return (d, action, expl)
            })
        }

        // Hard 17+: always Stand
        for total in 17...21 {
            set(.hard(total), dealers.map { d in
                (d, .stand, "Hard \(total): strong enough — stand.")
            })
        }

        // ── SOFT TOTALS ──────────────────────────────────────────────────────────

        // Soft 13 (A2) & Soft 14 (A3): Double vs 5–6, else Hit
        for total in [13, 14] {
            let name = total == 13 ? "A-2" : "A-3"
            set(.soft(total), dealers.map { d in
                let action: Action = (d == .five || d == .six) ? .doubleOrHit : .hit
                let expl = (d == .five || d == .six)
                    ? "\(name) vs dealer \(d.symbol): great double — dealer very likely to bust."
                    : "\(name) vs dealer \(d.symbol): not enough edge to double; hit."
                return (d, action, expl)
            })
        }

        // Soft 15 (A4) & Soft 16 (A5): Double vs 4–6, else Hit
        for total in [15, 16] {
            let name = total == 15 ? "A-4" : "A-5"
            set(.soft(total), dealers.map { d in
                let action: Action = (d >= .four && d <= .six) ? .doubleOrHit : .hit
                let expl = (d >= .four && d <= .six)
                    ? "\(name) vs dealer \(d.symbol): dealer in bust zone; double."
                    : "\(name) vs dealer \(d.symbol): take a free hit — can't bust."
                return (d, action, expl)
            })
        }

        // Soft 17 (A6): Double vs 3–6, else Hit
        set(.soft(17), dealers.map { d in
            let action: Action = (d >= .three && d <= .six) ? .doubleOrHit : .hit
            let expl = (d >= .three && d <= .six)
                ? "A-6 vs dealer \(d.symbol): double to maximize against weak dealer."
                : "A-6 vs dealer \(d.symbol): 17 isn't great; hit for a chance at 18–21."
            return (d, action, expl)
        })

        // Soft 18 (A7): Double vs 3–6, Stand vs 2/7/8, Hit vs 9/10/A
        set(.soft(18), dealers.map { d in
            let action: Action
            let expl: String
            if d >= .three && d <= .six {
                action = .doubleOrStand
                expl = "A-7 vs dealer \(d.symbol): soft 18 is strong, but double to squeeze more value."
            } else if d == .two || d == .seven || d == .eight {
                action = .stand
                expl = "A-7 vs dealer \(d.symbol): 18 beats this dealer total; stand."
            } else {
                action = .hit
                expl = "A-7 vs dealer \(d.symbol): dealer likely makes 19–20; hit for a better total."
            }
            return (d, action, expl)
        })

        // Soft 19 (A8) & Soft 20 (A9): always Stand
        for total in [19, 20] {
            set(.soft(total), dealers.map { d in
                (d, .stand, "Soft \(total) is a monster hand — always stand.")
            })
        }

        // ── PAIRS ─────────────────────────────────────────────────────────────────

        // 2-2 & 3-3: Split vs 2–7, else Hit
        for rank in [Rank.two, .three] {
            set(.pair(rank), dealers.map { d in
                let action: Action = (d >= .two && d <= .seven) ? .split : .hit
                let expl = (d >= .two && d <= .seven)
                    ? "\(rank.symbol)-\(rank.symbol) vs dealer \(d.symbol): split to create two better hands."
                    : "\(rank.symbol)-\(rank.symbol) vs dealer \(d.symbol): too risky to split; hit."
                return (d, action, expl)
            })
        }

        // 4-4: Split vs 5–6, else Hit
        set(.pair(.four), dealers.map { d in
            let action: Action = (d == .five || d == .six) ? .split : .hit
            let expl = (d == .five || d == .six)
                ? "4-4 vs dealer \(d.symbol): split for two strong starting hands against a weak dealer."
                : "4-4 vs dealer \(d.symbol): keep the 8; hitting is better."
            return (d, action, expl)
        })

        // 5-5: Never split — treat as hard 10 (Double vs 2–9, else Hit)
        set(.pair(.five), dealers.map { d in
            let action: Action = (d >= .two && d <= .nine) ? .doubleOrHit : .hit
            let expl = "5-5 is really hard 10 — never split fives. " +
                ((d >= .two && d <= .nine) ? "Double for maximum value." : "Dealer too strong; hit.")
            return (d, action, expl)
        })

        // 6-6: Split vs 2–6, else Hit
        set(.pair(.six), dealers.map { d in
            let action: Action = (d >= .two && d <= .six) ? .split : .hit
            let expl = (d >= .two && d <= .six)
                ? "6-6 vs dealer \(d.symbol): split; 12 is bad, two 16s give flexibility against weak dealer."
                : "6-6 vs dealer \(d.symbol): splitting creates two bad hands; hit the 12."
            return (d, action, expl)
        })

        // 7-7: Split vs 2–7, else Hit
        set(.pair(.seven), dealers.map { d in
            let action: Action = (d >= .two && d <= .seven) ? .split : .hit
            let expl = (d >= .two && d <= .seven)
                ? "7-7 vs dealer \(d.symbol): split; 14 is weak, two 17s are competitive."
                : "7-7 vs dealer \(d.symbol): don't split into two worse hands; hit."
            return (d, action, expl)
        })

        // 8-8: Always Split
        set(.pair(.eight), dealers.map { d in
            (d, .split, "Always split 8s — 16 is the worst hand in blackjack. Two 18s are far better.")
        })

        // 9-9: Split vs 2–9 except 7, Stand vs 7/10/A
        set(.pair(.nine), dealers.map { d in
            let action: Action
            let expl: String
            if d == .seven || d == .ten || d == .ace {
                action = .stand
                expl = "9-9 vs dealer \(d.symbol): your 18 beats or ties this; stand."
            } else {
                action = .split
                expl = "9-9 vs dealer \(d.symbol): split to get two 19s against a vulnerable dealer."
            }
            return (d, action, expl)
        })

        // 10-10: Always Stand
        set(.pair(.ten), dealers.map { d in
            (d, .stand, "Never split tens — 20 is one of the best hands possible.")
        })

        // A-A: Always Split
        set(.pair(.ace), dealers.map { d in
            (d, .split, "Always split Aces — starting each hand with an Ace gives huge advantage.")
        })

        return t
    }
    // swiftlint:enable function_body_length

    // MARK: - Rule Overrides

    /// S17: Dealer stands on soft 17 — player advantages shift slightly
    private static func applyS17Overrides(to table: inout StrategyTableMap, rules: RuleSet) {
        guard rules.dealerRule == .s17 else { return }
        // Hard 11 vs Ace: now Double (S17 makes dealer slightly weaker)
        table[.hard(11)]?[.ace] = StrategyEntry(
            action: .doubleOrHit,
            explanation: "Hard 11 vs Ace (S17): dealer stands on soft 17, giving you edge to double."
        )
        // Soft 18 (A7) vs Ace: now Double/Stand instead of Hit
        table[.soft(18)]?[.ace] = StrategyEntry(
            action: .doubleOrStand,
            explanation: "A-7 vs Ace (S17): dealer weaker; double for value."
        )
        // Soft 19 (A8) vs 6: Double (S17 bonus)
        table[.soft(19)]?[.six] = StrategyEntry(
            action: .doubleOrStand,
            explanation: "A-8 vs 6 (S17): exceptional double opportunity — dealer very likely to bust."
        )
    }

    /// Late/Early surrender overrides
    private static func applySurrenderOverrides(to table: inout StrategyTableMap, rules: RuleSet) {
        guard rules.surrenderRule != .none else { return }

        // Late surrender: Hard 16 vs 9/10/A, Hard 15 vs 10
        let lateSurrenders: [(HandKey, Rank, String)] = [
            (.hard(16), .nine, "Hard 16 vs 9: surrender saves money long-term."),
            (.hard(16), .ten, "Hard 16 vs 10: worst matchup — surrendering loses only half."),
            (.hard(16), .ace, "Hard 16 vs Ace: surrender is better than certain likely loss."),
            (.hard(15), .ten, "Hard 15 vs 10: surrender saves you money over time."),
        ]
        for (key, rank, expl) in lateSurrenders {
            table[key]?[rank] = StrategyEntry(action: .surrenderOrHit, explanation: expl)
        }

        if rules.surrenderRule == .early {
            // Early surrender adds more spots
            let earlySurrenders: [(HandKey, Rank, String)] = [
                (.hard(14), .ace, "Hard 14 vs Ace (Early surrender): take the half-bet."),
                (.hard(15), .ace, "Hard 15 vs Ace (Early surrender): surrender."),
                (.hard(16), .ace, "Hard 16 vs Ace (Early surrender): surrender."),
                (.pair(.seven), .ace, "7-7 vs Ace (Early): surrender instead of splitting."),
                (.pair(.eight), .ace, "8-8 vs Ace (Early): surrender instead of splitting."),
            ]
            for (key, rank, expl) in earlySurrenders {
                table[key]?[rank] = StrategyEntry(action: .surrenderOrHit, explanation: expl)
            }
        }
    }

    /// No DAS (Double After Split not allowed): revert some pair splits to hits
    private static func applyNoDASOverrides(to table: inout StrategyTableMap, rules: RuleSet) {
        guard !rules.doubleAfterSplit else { return }
        let dealers: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .ace]
        // 2-2 & 3-3: only split vs 4–7 without DAS
        for rank in [Rank.two, .three] {
            for d in dealers {
                let action: Action = (d >= .four && d <= .seven) ? .split : .hit
                table[.pair(rank)]?[d] = StrategyEntry(
                    action: action,
                    explanation: "\(rank.symbol)-\(rank.symbol) vs \(d.symbol) (no DAS): " +
                        (action == .split ? "split." : "hit — can't double after split.")
                )
            }
        }
        // 4-4: never split without DAS
        for d in dealers {
            table[.pair(.four)]?[d] = StrategyEntry(
                action: .hit,
                explanation: "4-4 vs \(d.symbol) (no DAS): don't split; hit the 8."
            )
        }
        // 6-6: only split vs 3–6 without DAS
        for d in dealers {
            let action: Action = (d >= .three && d <= .six) ? .split : .hit
            table[.pair(.six)]?[d] = StrategyEntry(
                action: action,
                explanation: "6-6 vs \(d.symbol) (no DAS): " +
                    (action == .split ? "split." : "hit.")
            )
        }
    }
}

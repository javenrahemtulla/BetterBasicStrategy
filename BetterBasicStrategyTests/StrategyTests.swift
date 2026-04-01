import XCTest
@testable import BetterBasicStrategy

final class StrategyTests: XCTestCase {

    // MARK: - Helpers

    private func engine(_ rules: RuleSet = .default) -> BasicStrategyEngine {
        BasicStrategyEngine(rules: rules)
    }

    private func hand(_ ranks: [Rank], suits: [Suit]? = nil) -> Hand {
        let suitList = suits ?? Array(repeating: .spades, count: ranks.count)
        let cards = zip(ranks, suitList).map { Card(suit: $1, rank: $0) }
        return Hand(cards: cards)
    }

    private func dealer(_ rank: Rank) -> Card { Card(suit: .hearts, rank: rank) }

    // MARK: - Hard Totals

    func testHard8AlwaysHit() {
        let e = engine()
        let h = hand([.three, .five])
        for rank in Rank.allCases where rank != .jack && rank != .queen && rank != .king {
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(rank)), .hit,
                           "Hard 8 vs \(rank.symbol) should be Hit")
        }
    }

    func testHard9DoubleVs3To6() {
        let e = engine()
        let h = hand([.four, .five])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.three)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.two)), .hit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.seven)), .hit)
    }

    func testHard10DoubleVs2To9() {
        let e = engine()
        let h = hand([.four, .six])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.two)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.nine)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ten)), .hit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ace)), .hit)
    }

    func testHard11DoubleVsNonAce_H17() {
        let e = engine()
        let h = hand([.five, .six])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.two)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ten)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ace)), .hit)
    }

    func testHard11DoubleVsAce_S17() {
        var rules = RuleSet.default
        rules.dealerRule = .s17
        let e = engine(rules)
        let h = hand([.five, .six])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ace)), .doubleOrHit)
    }

    func testHard12StandVs4To6() {
        let e = engine()
        let h = hand([.seven, .five])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.four)), .stand)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .stand)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.three)), .hit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.seven)), .hit)
    }

    func testHard13To16StandVs2To6() {
        let e = engine()
        for total in 13...16 {
            let ranks = decompose(total)
            let h = hand(ranks)
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.two)), .stand,
                           "Hard \(total) vs 2 should Stand")
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .stand,
                           "Hard \(total) vs 6 should Stand")
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.seven)), .hit,
                           "Hard \(total) vs 7 should Hit")
        }
    }

    func testHard17AlwaysStand() {
        let e = engine()
        let h = hand([.ten, .seven])
        for rank in [Rank.two, .seven, .ten, .ace] {
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(rank)), .stand)
        }
    }

    // MARK: - Soft Totals

    func testSoft13DoubleVs5And6() {
        let e = engine()
        let h = hand([.ace, .two], suits: [.hearts, .spades])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.five)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.four)), .hit)
    }

    func testSoft17DoubleVs3To6() {
        let e = engine()
        let h = hand([.ace, .six], suits: [.hearts, .spades])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.three)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.two)), .hit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.seven)), .hit)
    }

    func testSoft18StandVs2_7_8() {
        let e = engine()
        let h = hand([.ace, .seven], suits: [.hearts, .spades])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.two)), .stand)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.seven)), .stand)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.eight)), .stand)
    }

    func testSoft18HitVs9_10_Ace() {
        let e = engine()
        let h = hand([.ace, .seven], suits: [.hearts, .spades])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.nine)), .hit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ten)), .hit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ace)), .hit)
    }

    func testSoft18DoubleVs3To6() {
        let e = engine()
        let h = hand([.ace, .seven], suits: [.hearts, .spades])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.three)), .doubleOrStand)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .doubleOrStand)
    }

    func testSoft19And20AlwaysStand() {
        let e = engine()
        for ranks in [[Rank.ace, .eight], [Rank.ace, .nine]] {
            let h = hand(ranks, suits: [.hearts, .spades])
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .stand)
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ace)), .stand)
        }
    }

    // MARK: - Pairs

    func testAcesAlwaysSplit() {
        let e = engine()
        let h = hand([.ace, .ace], suits: [.hearts, .spades])
        for rank in [Rank.two, .six, .ten, .ace] {
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(rank)), .split,
                           "A-A vs \(rank.symbol) should Split")
        }
    }

    func testEightsAlwaysSplit() {
        let e = engine()
        let h = hand([.eight, .eight])
        for rank in [Rank.two, .seven, .ten, .ace] {
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(rank)), .split,
                           "8-8 vs \(rank.symbol) should Split")
        }
    }

    func testTensNeverSplit() {
        let e = engine()
        let h = hand([.ten, .ten])
        for rank in Rank.allCases {
            XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(rank)), .stand,
                           "T-T vs \(rank.symbol) should Stand")
        }
    }

    func testFivesNeverSplit() {
        let e = engine()
        let h = hand([.five, .five])
        // Should be treated as Hard 10
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .doubleOrHit)
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ten)), .hit)
    }

    func testNinesVsSevenStand() {
        let e = engine()
        let h = hand([.nine, .nine])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.seven)), .stand)
    }

    func testNinesVsSixSplit() {
        let e = engine()
        let h = hand([.nine, .nine])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.six)), .split)
    }

    // MARK: - Surrender

    func testLateSurrenderHard16Vs10() {
        var rules = RuleSet.default
        rules.surrenderRule = .late
        let e = engine(rules)
        let h = hand([.ten, .six])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ten)), .surrenderOrHit)
    }

    func testLateSurrenderHard15Vs10() {
        var rules = RuleSet.default
        rules.surrenderRule = .late
        let e = engine(rules)
        let h = hand([.ten, .five])
        XCTAssertEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ten)), .surrenderOrHit)
    }

    func testNoSurrenderWhenRuleIsNone() {
        var rules = RuleSet.default
        rules.surrenderRule = .none
        let e = engine(rules)
        let h = hand([.ten, .six])
        XCTAssertNotEqual(e.correctAction(hand: h, dealerUpcard: dealer(.ten)), .surrenderOrHit)
    }

    // MARK: - Helpers

    private func decompose(_ total: Int) -> [Rank] {
        // Simple decomposition for testing
        let second = min(total - 2, 10)
        let first = total - second
        return [rankFrom(first), rankFrom(second)]
    }

    private func rankFrom(_ value: Int) -> Rank {
        Rank.allCases.first { $0.value == value } ?? .two
    }
}

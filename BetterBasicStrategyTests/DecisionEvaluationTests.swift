import XCTest
@testable import BetterBasicStrategy

final class DecisionEvaluationTests: XCTestCase {

    func testHandKeyHard() {
        var h = Hand()
        h.cards = [Card(suit: .spades, rank: .seven), Card(suit: .hearts, rank: .nine)]
        XCTAssertEqual(h.handKey, .hard(16))
    }

    func testHandKeySoft() {
        var h = Hand()
        h.cards = [Card(suit: .hearts, rank: .ace), Card(suit: .spades, rank: .seven)]
        XCTAssertEqual(h.handKey, .soft(18))
    }

    func testHandKeyPair() {
        var h = Hand()
        h.cards = [Card(suit: .hearts, rank: .eight), Card(suit: .spades, rank: .eight)]
        XCTAssertEqual(h.handKey, .pair(.eight))
    }

    func testJackQueenKingAllTreatAstenPair() {
        var h = Hand()
        h.cards = [Card(suit: .hearts, rank: .jack), Card(suit: .spades, rank: .queen)]
        // J and Q both have strategyRank == .ten, so this should be a pair
        XCTAssertEqual(h.handKey, .pair(.ten))
    }

    func testAceTotalCorrectAfterBust() {
        var h = Hand()
        h.cards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .spades, rank: .ace),
            Card(suit: .clubs, rank: .nine)
        ]
        // A(11) + A(1) + 9 = 21
        XCTAssertEqual(h.total, 21)
        XCTAssertFalse(h.isBust)
    }

    func testSoftHandDetection() {
        var h = Hand()
        h.cards = [Card(suit: .hearts, rank: .ace), Card(suit: .spades, rank: .six)]
        XCTAssertTrue(h.isSoft)
        XCTAssertEqual(h.total, 17)
    }

    func testHardHandAfterAceReduction() {
        var h = Hand()
        h.cards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .spades, rank: .nine),
            Card(suit: .clubs, rank: .five)
        ]
        // A(11)+9+5=25, reduce ace: A(1)+9+5=15
        XCTAssertFalse(h.isSoft)
        XCTAssertEqual(h.total, 15)
    }

    func testBlackjack() {
        var h = Hand()
        h.cards = [Card(suit: .hearts, rank: .ace), Card(suit: .spades, rank: .king)]
        XCTAssertTrue(h.isBlackjack)
        XCTAssertEqual(h.total, 21)
    }

    func testActionResolutionDoubleOrHitWhenCanDouble() {
        let action = Action.doubleOrHit
        let resolved = action.resolved(canDouble: true, canSplit: false, canSurrender: false)
        XCTAssertEqual(resolved, .doubleOrHit)
    }

    func testActionResolutionDoubleOrHitFallsBackToHit() {
        let action = Action.doubleOrHit
        let resolved = action.resolved(canDouble: false, canSplit: false, canSurrender: false)
        XCTAssertEqual(resolved, .hit)
    }

    func testActionResolutionSurrenderOrHitFallsBackToHit() {
        let action = Action.surrenderOrHit
        let resolved = action.resolved(canDouble: false, canSplit: false, canSurrender: false)
        XCTAssertEqual(resolved, .hit)
    }

    func testActionResolutionSurrenderOrHitWhenCanSurrender() {
        let action = Action.surrenderOrHit
        let resolved = action.resolved(canDouble: false, canSplit: false, canSurrender: true)
        XCTAssertEqual(resolved, .surrenderOrHit)
    }

    func testDecisionCategoryMatchesForCorrectPlay() {
        let rawAction = Action.doubleOrHit
        let resolved = rawAction.resolved(canDouble: true, canSplit: false, canSurrender: false)
        XCTAssertEqual(resolved.primaryDecisionCategory, .double)
    }

    func testDecisionCategoryFallbackIsHit() {
        let rawAction = Action.doubleOrHit
        let resolved = rawAction.resolved(canDouble: false, canSplit: false, canSurrender: false)
        XCTAssertEqual(resolved.primaryDecisionCategory, .hit)
    }

    func testSoftHandKeyAfterHit() {
        // A+7 = soft 18; after hitting 3 → A+7+3 = hard 11 (wait, 21)
        // Actually A(11)+7+3=21 but if it goes over, ace becomes 1
        var h = Hand()
        h.cards = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .spades, rank: .seven),
            Card(suit: .clubs, rank: .six)
        ]
        // A(11)+7+6=24, reduce: A(1)+7+6=14
        XCTAssertFalse(h.isSoft)
        XCTAssertEqual(h.total, 14)
        XCTAssertEqual(h.handKey, .hard(14))
    }
}

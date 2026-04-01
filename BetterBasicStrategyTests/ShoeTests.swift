import XCTest
@testable import BetterBasicStrategy

final class ShoeTests: XCTestCase {

    func testShoeHas312Cards() {
        let shoe = Shoe()
        shoe.shuffle()
        XCTAssertEqual(shoe.totalCards, 312)
    }

    func testNoRankExceedsSixAppearances() {
        let shoe = Shoe()
        shoe.shuffle()
        var rankSuitCounts: [String: Int] = [:]
        for card in shoe.cards {
            let key = "\(card.rank)-\(card.suit)"
            rankSuitCounts[key, default: 0] += 1
        }
        for (key, count) in rankSuitCounts {
            XCTAssertEqual(count, 6, "Card \(key) appears \(count) times, expected 6")
        }
    }

    func testAllRankSuitCombinationsPresent() {
        let shoe = Shoe()
        shoe.shuffle()
        var seen = Set<String>()
        for card in shoe.cards {
            seen.insert("\(card.rank)-\(card.suit)")
        }
        XCTAssertEqual(seen.count, 52, "Expected 52 unique rank-suit combos")
    }

    func testDealReducesRemaining() {
        let shoe = Shoe()
        shoe.shuffle()
        let initial = shoe.remainingCount
        _ = shoe.deal()
        XCTAssertEqual(shoe.remainingCount, initial - 1)
        XCTAssertEqual(shoe.dealtCount, 1)
    }

    func testPenetrationCalculation() {
        let shoe = Shoe()
        shoe.shuffle()
        XCTAssertEqual(shoe.penetration, 0.0, accuracy: 0.001)
        for _ in 0..<156 { _ = shoe.deal() }
        XCTAssertEqual(shoe.penetration, 0.5, accuracy: 0.01)
    }

    func testNeedsReshuffleAtTrigger() {
        let shoe = Shoe(penetrationTrigger: 0.5)
        shoe.shuffle()
        for _ in 0..<156 { _ = shoe.deal() }
        XCTAssertTrue(shoe.needsReshuffle)
    }

    func testShuffleResetsPenetration() {
        let shoe = Shoe()
        shoe.shuffle()
        for _ in 0..<100 { _ = shoe.deal() }
        shoe.shuffle()
        XCTAssertEqual(shoe.penetration, 0.0, accuracy: 0.001)
        XCTAssertEqual(shoe.remainingCount, 312)
    }

    func testDealtCardsAreGone() {
        let shoe = Shoe()
        shoe.shuffle()
        var dealt: [Card] = []
        for _ in 0..<10 { if let c = shoe.deal() { dealt.append(c) } }
        let remaining = Array(shoe.cards[shoe.dealtCount...])
        for card in dealt {
            XCTAssertFalse(remaining.contains(card), "Dealt card found in remaining shoe")
        }
    }

    func testFisherYatesProducesUniqueOrder() {
        let shoe1 = Shoe()
        shoe1.shuffle()
        let shoe2 = Shoe()
        shoe2.shuffle()
        // Astronomically unlikely to match (1/312! chance)
        let order1 = shoe1.cards.map { $0.rank.rawValue * 4 + ($0.suit == .hearts ? 0 : $0.suit == .diamonds ? 1 : $0.suit == .clubs ? 2 : 3) }
        let order2 = shoe2.cards.map { $0.rank.rawValue * 4 + ($0.suit == .hearts ? 0 : $0.suit == .diamonds ? 1 : $0.suit == .clubs ? 2 : 3) }
        XCTAssertNotEqual(order1, order2, "Two independent shuffles should differ")
    }
}

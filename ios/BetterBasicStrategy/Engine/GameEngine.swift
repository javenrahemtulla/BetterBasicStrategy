import Foundation

enum GameEngine {

    // MARK: - Deal new round

    static func dealNewRound(
        state: GameState,
        shoe: inout ShoeState,
        rules: RuleSet
    ) -> (state: GameState, reshuffled: Bool) {
        let wasReshuffle = shoe.needsReshuffle
        if wasReshuffle {
            shoe = ShoeState.create(penetrationTrigger: shoe.penetrationTrigger)
        }

        var spots = (0..<rules.numberOfSpots).map { i in
            SpotState(
                id: "spot-\(i)-\(Int(Date().timeIntervalSince1970 * 1000))",
                hands: [HandState.build(from: [])],
                activeHandIndex: 0,
                outcomes: [.lose],
                actions: [[]],
                isComplete: false
            )
        }
        var dealerCards: [Card] = []

        // Two passes: player, dealer, player, dealer-hole
        for _ in 0..<2 {
            for i in 0..<spots.count {
                if let card = shoe.deal() {
                    spots[i].hands[0] = HandState.build(from: spots[i].hands[0].cards + [card])
                }
            }
            if let card = shoe.deal() { dealerCards.append(card) }
        }

        // Mark natural blackjacks
        for i in 0..<spots.count where spots[i].hands[0].isBlackjack {
            spots[i].isComplete = true
            spots[i].outcomes = [.blackjack]
        }

        shoe.save()

        var newState = GameState(
            phase: .playerTurn,
            spots: spots,
            activeSpotIndex: 0,
            dealerCards: dealerCards,
            dealerHoleRevealed: false,
            lastActionWasCorrect: nil,
            lastCoachingEntry: nil
        )

        if spots.allSatisfy(\.isComplete) {
            newState = playDealer(state: newState, shoe: &shoe, rules: rules)
            return (newState, wasReshuffle)
        }

        let firstActive = spots.indices.first(where: { !spots[$0].isComplete }) ?? 0
        newState.activeSpotIndex = firstActive
        return (newState, wasReshuffle)
    }

    // MARK: - Available actions

    static func getAvailableActions(state: GameState, rules: RuleSet) -> Set<DecisionCategory> {
        guard state.phase == .playerTurn else { return [] }
        guard let spot = state.spots[safe: state.activeSpotIndex] else { return [] }
        guard let hand = spot.hands[safe: spot.activeHandIndex]   else { return [] }

        var available: Set<DecisionCategory> = [.hit, .stand]

        if hand.cards.count == 2 {
            let isAfterSplit = spot.hands.count > 1
            if !isAfterSplit || rules.doubleAfterSplit { available.insert(.double) }

            let r1 = hand.cards[0].strategyRank, r2 = hand.cards[1].strategyRank
            if r1 == r2 {
                let isAce = hand.cards[0].rank == 14
                if spot.hands.count == 1 || (spot.hands.count < 4 && (!isAce || rules.resplitAces)) {
                    available.insert(.split)
                }
            }
        }

        if hand.cards.count == 2,
           spot.actions[safe: spot.activeHandIndex]?.isEmpty == true,
           rules.surrenderRule != .none {
            available.insert(.surrender)
        }

        return available
    }

    // MARK: - Perform action

    static func performAction(
        state: GameState,
        shoe: inout ShoeState,
        category: DecisionCategory,
        rules: RuleSet,
        engine: BasicStrategyEngine
    ) -> GameState {
        var spots = state.spots
        var spot  = spots[state.activeSpotIndex]
        let hand  = spot.hands[spot.activeHandIndex]
        let upcard = state.dealerCards[0]

        let available   = getAvailableActions(state: state, rules: rules)
        let canDouble   = available.contains(.double)
        let canSplit    = available.contains(.split)
        let canSurrender = available.contains(.surrender)

        let rawCorrect   = engine.correctAction(handKey: hand.handKey, dealerUpcard: upcard)
        let resolved     = resolveAction(rawCorrect, canDouble: canDouble, canSplit: canSplit, canSurrender: canSurrender)
        let correctCat   = actionCategory(resolved)
        let isCorrect    = correctCat == category
        let entry        = engine.getEntry(handKey: hand.handKey, dealerUpcard: upcard)

        spot.actions[spot.activeHandIndex].append(ActionRecord(
            action: category,
            wasCorrect: isCorrect,
            correctAction: resolved,
            explanation: entry?.explanation ?? ""
        ))

        var newState = state
        newState.spots = spots
        newState.lastActionWasCorrect = isCorrect
        newState.lastCoachingEntry    = isCorrect ? nil : entry

        switch category {
        case .hit:
            if let card = shoe.deal() {
                spot.hands[spot.activeHandIndex] = HandState.build(from: hand.cards + [card])
                spots[state.activeSpotIndex] = spot
                newState.spots = spots
                if spot.hands[spot.activeHandIndex].total >= 21 {
                    newState = advanceHand(state: newState, shoe: &shoe, rules: rules)
                }
            } else {
                spots[state.activeSpotIndex] = spot; newState.spots = spots
            }

        case .stand:
            spots[state.activeSpotIndex] = spot; newState.spots = spots
            newState = advanceHand(state: newState, shoe: &shoe, rules: rules)

        case .double:
            if let card = shoe.deal() {
                spot.hands[spot.activeHandIndex] = HandState.build(from: hand.cards + [card])
            }
            spots[state.activeSpotIndex] = spot; newState.spots = spots
            newState = advanceHand(state: newState, shoe: &shoe, rules: rules)

        case .split:
            let splitCard = hand.cards[1]
            let fill1 = shoe.deal()
            let fill2 = shoe.deal()
            spot.hands[spot.activeHandIndex] = HandState.build(from: [hand.cards[0]] + (fill1.map { [$0] } ?? []))
            let newHand = HandState.build(from: [splitCard] + (fill2.map { [$0] } ?? []))
            spot.hands.insert(newHand, at: spot.activeHandIndex + 1)
            spot.actions.insert([], at: spot.activeHandIndex + 1)
            spot.outcomes.append(.lose)
            spots[state.activeSpotIndex] = spot; newState.spots = spots
            // Split aces get only one card each unless resplitAces
            if hand.cards[0].rank == 14 && !rules.resplitAces {
                newState = advanceHand(state: newState, shoe: &shoe, rules: rules)
            }

        case .surrender:
            spot.outcomes = [.surrender]; spot.isComplete = true
            spots[state.activeSpotIndex] = spot; newState.spots = spots
            newState = advanceIfNeeded(state: newState, shoe: &shoe, rules: rules)
        }

        shoe.save()
        return newState
    }

    // MARK: - Advance helpers

    private static func advanceHand(state: GameState, shoe: inout ShoeState, rules: RuleSet) -> GameState {
        var newState = state
        var spot = newState.spots[newState.activeSpotIndex]
        let next = spot.activeHandIndex + 1
        if next < spot.hands.count {
            spot.activeHandIndex = next
            newState.spots[newState.activeSpotIndex] = spot
        } else {
            spot.isComplete = true
            newState.spots[newState.activeSpotIndex] = spot
            newState = advanceIfNeeded(state: newState, shoe: &shoe, rules: rules)
        }
        return newState
    }

    private static func advanceIfNeeded(state: GameState, shoe: inout ShoeState, rules: RuleSet) -> GameState {
        let next = state.spots.indices.first(where: { $0 > state.activeSpotIndex && !state.spots[$0].isComplete })
        if let next = next {
            var s = state; s.activeSpotIndex = next; return s
        }
        if state.spots.allSatisfy(\.isComplete) {
            return playDealer(state: state, shoe: &shoe, rules: rules)
        }
        return state
    }

    // MARK: - Dealer play

    private static func playDealer(state: GameState, shoe: inout ShoeState, rules: RuleSet) -> GameState {
        var dealerCards = state.dealerCards
        while shouldDealerHit(cards: dealerCards, rules: rules) {
            guard let card = shoe.deal() else { break }
            dealerCards.append(card)
        }
        var resolved = resolveOutcomes(state: GameState(
            phase: .dealerTurn, spots: state.spots, activeSpotIndex: state.activeSpotIndex,
            dealerCards: dealerCards, dealerHoleRevealed: true,
            lastActionWasCorrect: state.lastActionWasCorrect, lastCoachingEntry: state.lastCoachingEntry
        ))
        resolved.phase = .roundOver
        shoe.save()
        return resolved
    }

    private static func shouldDealerHit(cards: [Card], rules: RuleSet) -> Bool {
        let (total, isSoft) = calcTotal(cards)
        if total < 17 { return true }
        if total == 17 && isSoft && rules.dealerRule == .H17 { return true }
        return false
    }

    private static func resolveOutcomes(state: GameState) -> GameState {
        let (dealerTotal, _) = calcTotal(state.dealerCards)
        let dealerBust = dealerTotal > 21
        let spots = state.spots.map { spot -> SpotState in
            if spot.outcomes.first == .surrender { return spot }
            let outcomes: [Outcome] = spot.hands.enumerated().map { (i, hand) in
                if spot.outcomes[safe: i] == .blackjack { return .blackjack }
                if hand.total > 21  { return .bust }
                if dealerBust       { return .win }
                if hand.total > dealerTotal { return .win }
                if hand.total == dealerTotal { return .push }
                return .lose
            }
            return SpotState(id: spot.id, hands: spot.hands, activeHandIndex: spot.activeHandIndex,
                             outcomes: outcomes, actions: spot.actions, isComplete: true)
        }
        var s = state; s.spots = spots; s.dealerHoleRevealed = true; return s
    }
}

// MARK: - Safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

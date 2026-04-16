import Foundation

// Add SUPABASE_URL and SUPABASE_ANON_KEY to your Info.plist, or set them here directly.
struct SupabaseConfig {
    static var url: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    }
    static var anonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    }
}

enum SupabaseError: LocalizedError {
    case notConfigured
    case serverError(String)
    var errorDescription: String? {
        switch self {
        case .notConfigured:    return "Supabase URL/key not configured in Info.plist."
        case .serverError(let m): return m
        }
    }
}

final class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL: String
    private let anonKey: String

    private lazy var snakeDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
    private lazy var encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    init(url: String = SupabaseConfig.url, anonKey: String = SupabaseConfig.anonKey) {
        self.baseURL = url
        self.anonKey = anonKey
    }

    private var isConfigured: Bool { !baseURL.isEmpty && !anonKey.isEmpty }

    private func baseHeaders(prefer: String = "return=representation") -> [String: String] {
        ["Content-Type": "application/json",
         "apikey": anonKey,
         "Authorization": "Bearer \(anonKey)",
         "Prefer": prefer]
    }

    private func rest(_ path: String) throws -> URL {
        guard isConfigured, let url = URL(string: "\(baseURL)/rest/v1/\(path)") else {
            throw SupabaseError.notConfigured
        }
        return url
    }

    // MARK: - User

    func upsertUser(username: String) async throws -> BBSUser {
        var req = URLRequest(url: try rest("users"))
        req.httpMethod = "POST"
        baseHeaders(prefer: "return=representation, resolution=merge-duplicates")
            .forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["username": username])

        let (data, _) = try await URLSession.shared.data(for: req)
        let users = try snakeDecoder.decode([BBSUser].self, from: data)
        guard let user = users.first else { throw SupabaseError.serverError("No user returned") }
        return user
    }

    // MARK: - Session

    func createSession(userId: String, rules: RuleSet) async throws -> GameSession {
        var req = URLRequest(url: try rest("game_sessions"))
        req.httpMethod = "POST"
        baseHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "user_id": userId,
            "started_at": ISO8601DateFormatter().string(from: Date()),
            "hands_played": 0, "correct_decisions": 0, "incorrect_decisions": 0,
        ])
        let (data, _) = try await URLSession.shared.data(for: req)
        let sessions = try snakeDecoder.decode([GameSession].self, from: data)
        guard let s = sessions.first else { throw SupabaseError.serverError("No session returned") }
        return s
    }

    func updateSession(sessionId: String, handsPlayed: Int, correctDecisions: Int, incorrectDecisions: Int) async throws {
        var req = URLRequest(url: try rest("game_sessions?id=eq.\(sessionId)"))
        req.httpMethod = "PATCH"
        baseHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "hands_played": handsPlayed,
            "correct_decisions": correctDecisions,
            "incorrect_decisions": incorrectDecisions,
            "ended_at": ISO8601DateFormatter().string(from: Date()),
        ])
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Hand record

    func saveHandRecord(
        sessionId: String, userId: String, spotNumber: Int,
        playerCards: [Card], dealerUpcard: Card, dealerFinalHand: [Card],
        handType: HandType, playerTotal: Int, actionsTaken: [ActionRecord],
        outcome: Outcome, wasSplit: Bool, wasDoubled: Bool, wasSurrendered: Bool
    ) async throws {
        var req = URLRequest(url: try rest("hand_records"))
        req.httpMethod = "POST"
        baseHeaders(prefer: "return=minimal").forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let body: [String: Any] = [
            "session_id": sessionId, "user_id": userId,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "spot_number": spotNumber,
            "player_cards":      try jsonAny(playerCards),
            "dealer_upcard":     try jsonAny(dealerUpcard),
            "dealer_final_hand": try jsonAny(dealerFinalHand),
            "hand_type":         handType.rawValue,
            "player_total":      playerTotal,
            "actions_taken":     try jsonAny(actionsTaken),
            "outcome":           outcome.rawValue,
            "was_split": wasSplit, "was_doubled": wasDoubled, "was_surrendered": wasSurrendered,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Shoe event

    func saveShoeEvent(userId: String, sessionId: String) async throws {
        var req = URLRequest(url: try rest("shoe_events"))
        req.httpMethod = "POST"
        baseHeaders(prefer: "return=minimal").forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "user_id": userId, "session_id": sessionId,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ])
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Stats

    func fetchStats(userId: String) async throws -> StatsData {
        async let s1 = get("game_sessions?user_id=eq.\(userId)&order=started_at.desc&limit=20")
        async let s2 = get("hand_records?user_id=eq.\(userId)&order=timestamp.asc")
        async let s3 = get("shoe_events?user_id=eq.\(userId)&select=id")

        let (sessData, handsData, shoesData) = try await (s1, s2, s3)
        let sessions = (try? snakeDecoder.decode([GameSession].self, from: sessData)) ?? []
        return computeStats(sessions: sessions, handsData: handsData, shoesData: shoesData)
    }

    // MARK: - Helpers

    private func get(_ path: String) async throws -> Data {
        var req = URLRequest(url: try rest(path))
        baseHeaders().forEach { req.setValue($1, forHTTPHeaderField: $0) }
        return try await URLSession.shared.data(for: req).0
    }

    private func jsonAny<T: Encodable>(_ value: T) throws -> Any {
        // Use standard (non-snake) encoder for JSONB fields — keys are stored camelCase
        let data = try JSONEncoder().encode(value)
        return try JSONSerialization.jsonObject(with: data)
    }

    private func computeStats(sessions: [GameSession], handsData: Data, shoesData: Data) -> StatsData {
        struct MinHand: Codable {
            let handType: String
            let playerTotal: Int
            let outcome: String
            let actionsTaken: [MinAction]
            let dealerUpcard: MinCard?

            enum CodingKeys: String, CodingKey {
                case handType = "hand_type", playerTotal = "player_total", outcome
                case actionsTaken = "actions_taken", dealerUpcard = "dealer_upcard"
            }
            struct MinAction: Codable {
                let wasCorrect: Bool
                let correctAction: String
                // Explicit keys — bypasses convertFromSnakeCase for camelCase JSONB content
                enum CodingKeys: String, CodingKey { case wasCorrect, correctAction }
            }
            struct MinCard: Codable { let rank: Int }
        }

        let hands = (try? JSONDecoder().decode([MinHand].self, from: handsData)) ?? []

        var totalCorrect = 0, totalIncorrect = 0
        var outcomeCounts = OutcomeCounts()
        var typeMap: [String: (c: Int, t: Int)] = ["hard": (0,0), "soft": (0,0), "pair": (0,0)]
        let rankBuckets: [String: Set<Int>] = [
            "2":[2],"3":[3],"4":[4],"5":[5],"6":[6],
            "7":[7],"8":[8],"9":[9],"10":[10,11,12,13],"A":[14]
        ]
        var upcardMap: [String: (c: Int, t: Int)] = [:]
        var mistakeMap: [String: (count: Int, correct: String)] = [:]
        var streak = 0, longestStreak = 0

        for hand in hands {
            for a in hand.actionsTaken {
                if a.wasCorrect { totalCorrect += 1; streak += 1; longestStreak = max(longestStreak, streak) }
                else            { totalIncorrect += 1; streak = 0 }
            }
            switch hand.outcome {
            case "win":                outcomeCounts.wins += 1
            case "lose", "bust":       outcomeCounts.losses += 1
            case "push":               outcomeCounts.pushes += 1
            case "blackjack":          outcomeCounts.blackjacks += 1
            case "surrender":          outcomeCounts.surrenders += 1
            default: break
            }
            if var e = typeMap[hand.handType] {
                for a in hand.actionsTaken { e.t += 1; if a.wasCorrect { e.c += 1 } }
                typeMap[hand.handType] = e
            }
            if let dealerRank = hand.dealerUpcard?.rank {
                for (label, ranks) in rankBuckets where ranks.contains(dealerRank) {
                    var e = upcardMap[label] ?? (0,0)
                    for a in hand.actionsTaken { e.t += 1; if a.wasCorrect { e.c += 1 } }
                    upcardMap[label] = e
                }
                for a in hand.actionsTaken where !a.wasCorrect {
                    let key = "\(hand.handType) \(hand.playerTotal) vs \(dealerRank)"
                    mistakeMap[key] = ((mistakeMap[key]?.count ?? 0) + 1, a.correctAction)
                }
            }
        }

        let decisions = totalCorrect + totalIncorrect
        struct ShoeItem: Codable { let id: String }
        let shoesPlayed = ((try? JSONDecoder().decode([ShoeItem].self, from: shoesData)) ?? []).count

        return StatsData(
            lifetimeHands: hands.count,
            lifetimeDecisions: decisions,
            lifetimeAccuracy: decisions > 0 ? Double(totalCorrect) / Double(decisions) * 100 : 0,
            currentStreak: streak,
            longestStreak: longestStreak,
            shoesPlayed: shoesPlayed,
            outcomeCounts: outcomeCounts,
            accuracyByHandType: ["Hard","Soft","Pair"].map { label in
                let e = typeMap[label.lowercased()] ?? (0,0)
                return AccuracyByHandType(label: label, accuracy: e.t > 0 ? Double(e.c)/Double(e.t)*100 : 0, total: e.t)
            },
            accuracyByDealerUpcard: ["2","3","4","5","6","7","8","9","10","A"].map { rank in
                let e = upcardMap[rank] ?? (0,0)
                return AccuracyByDealerUpcard(rank: rank, accuracy: e.t > 0 ? Double(e.c)/Double(e.t)*100 : 0, total: e.t)
            },
            topMistakes: mistakeMap.sorted { $0.value.count > $1.value.count }.prefix(10).map {
                TopMistake(label: $0.key, count: $0.value.count, correctAction: $0.value.correct)
            },
            recentSessions: sessions
        )
    }
}

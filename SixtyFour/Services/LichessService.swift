import Foundation

final class LichessService: ChessService {
    static let shared = LichessService()

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "SixtyFour/1.0"]
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    private var accessToken: String? {
        UserDefaults(suiteName: UserStore.appGroupID)?.string(forKey: "lichessAccessToken")
    }

    // MARK: - ChessService Protocol

    func validateUsername(_ username: String) async throws -> Bool {
        let url = URL(string: "https://lichess.org/api/user/\(username.lowercased())")!
        let (_, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    func fetchProfile(_ username: String) async throws -> PlayerProfile {
        let user: LichessUser = try await fetchJSON(
            URL(string: "https://lichess.org/api/user/\(username.lowercased())")!
        )
        return PlayerProfile(
            username: user.username,
            avatar: nil,
            name: user.profile?.realName,
            title: user.title,
            country: user.profile?.country,
            joined: Int(user.createdAt / 1000),
            lastOnline: Int(user.seenAt / 1000)
        )
    }

    func fetchFullStats(_ username: String) async throws -> FullPlayerStats {
        let user: LichessUser = try await fetchJSON(
            URL(string: "https://lichess.org/api/user/\(username.lowercased())")!
        )
        return FullPlayerStats(
            chessBullet: user.perfs?.bullet.map { mapPerf($0) },
            chessBlitz: user.perfs?.blitz.map { mapPerf($0) },
            chessRapid: user.perfs?.rapid.map { mapPerf($0) },
            chessDaily: user.perfs?.correspondence.map { mapPerf($0) }
        )
    }

    func fetchTodayStats(_ username: String, mode: GoalMode, timeClass: TimeClass) async throws -> (solved: Int, failed: Int, rating: Int?) {
        switch mode {
        case .puzzles:
            return try await fetchTodayPuzzleStats(username)
        case .games:
            return try await fetchTodayGameStats(username, timeClass: timeClass)
        }
    }

    func fetchTacticsChart(_ username: String, daysAgo: Int) async throws -> TacticsChartResponse {
        let activities = try await fetchPuzzleActivity(max: daysAgo * 50)
        return aggregatePuzzleActivity(activities, daysAgo: daysAgo)
    }

    func fetchGameHistory(_ username: String, timeClass: TimeClass, days: Int) async throws -> [GameDayEntry] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -days, to: Date())!
        let sinceMs = Int(cutoff.timeIntervalSince1970 * 1000)

        let games = try await fetchGamesNDJSON(
            username: username,
            perfType: timeClass.lichessPerf,
            since: sinceMs
        )

        var dayMap: [String: GameDayEntry] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for game in games {
            let endDate = Date(timeIntervalSince1970: TimeInterval(game.lastMoveAt) / 1000)
            let key = formatter.string(from: endDate)
            var entry = dayMap[key] ?? GameDayEntry(
                dateString: key,
                date: cal.startOfDay(for: endDate),
                won: 0, lost: 0, drawn: 0, latestRating: nil
            )

            let result = game.result(for: username)
            switch result {
            case .win: entry.won += 1
            case .loss: entry.lost += 1
            case .draw: entry.drawn += 1
            case .unknown: break
            }

            if let rating = game.playerRating(for: username) {
                entry.latestRating = rating
            }
            dayMap[key] = entry
        }

        return dayMap.values.sorted { $0.date < $1.date }
    }

    // MARK: - Puzzle Activity

    private func fetchTodayPuzzleStats(_ username: String) async throws -> (solved: Int, failed: Int, rating: Int?) {
        let activities = try await fetchPuzzleActivity(max: 200)
        let cal = Calendar.current
        let todayActivities = activities.filter { cal.isDateInToday($0.date) }

        let solved = todayActivities.filter { $0.win }.count
        let failed = todayActivities.filter { !$0.win }.count

        // Puzzle activity doesn't include user rating — always fetch from profile
        let user: LichessUser? = try? await fetchJSON(
            URL(string: "https://lichess.org/api/user/\(username.lowercased())")!
        )
        let rating = user?.perfs?.puzzle?.rating

        return (solved: solved, failed: failed, rating: rating)
    }

    private func fetchTodayGameStats(_ username: String, timeClass: TimeClass) async throws -> (solved: Int, failed: Int, rating: Int?) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let sinceMs = Int(todayStart.timeIntervalSince1970 * 1000)

        let games = try await fetchGamesNDJSON(
            username: username,
            perfType: timeClass.lichessPerf,
            since: sinceMs
        )

        var won = 0, lost = 0
        var latestRating: Int?

        for game in games {
            switch game.result(for: username) {
            case .win: won += 1
            case .loss: lost += 1
            case .draw: break
            case .unknown: break
            }
            if let r = game.playerRating(for: username) {
                latestRating = r
            }
        }

        // If no games today, fetch rating from profile
        if latestRating == nil {
            let stats = try? await fetchFullStats(username)
            latestRating = stats?.rating(for: timeClass)
        }

        return (solved: won, failed: lost, rating: latestRating)
    }

    // MARK: - NDJSON Fetching

    private func fetchPuzzleActivity(max: Int) async throws -> [LichessPuzzleActivity] {
        guard let token = accessToken else { throw ChessServiceError.authRequired }
        let url = URL(string: "https://lichess.org/api/puzzle/activity?max=\(max)")!
        return try await fetchNDJSON(url, headers: ["Authorization": "Bearer \(token)"])
    }

    private func fetchGamesNDJSON(username: String, perfType: String, since: Int) async throws -> [LichessGame] {
        let url = URL(string: "https://lichess.org/api/games/user/\(username.lowercased())?perfType=\(perfType)&since=\(since)")!
        return try await fetchNDJSON(url)
    }

    // MARK: - Helpers

    private func aggregatePuzzleActivity(_ activities: [LichessPuzzleActivity], daysAgo: Int) -> TacticsChartResponse {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -daysAgo, to: Date())!

        let filtered = activities.filter { $0.date >= cutoff }

        // Group by day
        var dayGroups: [String: [LichessPuzzleActivity]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for activity in filtered {
            let key = formatter.string(from: activity.date)
            dayGroups[key, default: []].append(activity)
        }

        // Build daily stats
        var dailyStats: [DailyStatEntry] = []
        var ratings: [RatingEntry] = []

        for (_, group) in dayGroups.sorted(by: { $0.key < $1.key }) {
            let passed = group.filter { $0.win }.count
            let failed = group.filter { !$0.win }.count
            let lastRating = group.last.map { $0.puzzleRating }

            // Produce a timestamp that works with DailyStatEntry's chess.com offset logic
            let dayDate = group.first!.date
            let dayStart = cal.startOfDay(for: dayDate)
            // Add 7h offset in ms so the existing date computation strips it correctly
            let adjustedTimestamp = Int(dayStart.timeIntervalSince1970 * 1000) + 7 * 3600 * 1000

            dailyStats.append(DailyStatEntry(
                timestamp: adjustedTimestamp,
                totalPassed: passed,
                totalFailed: failed,
                totalTime: 0,
                dayCloseRating: lastRating
            ))

            if let r = lastRating {
                ratings.append(RatingEntry(
                    timestamp: adjustedTimestamp,
                    open: r, rating: r, high: r, low: r
                ))
            }
        }

        return TacticsChartResponse(ratings: ratings, dailyStats: dailyStats)
    }

    private func mapPerf(_ perf: LichessPerfStat) -> GameRatingCategory {
        GameRatingCategory(
            last: GameRatingCategory.GameRatingValue(rating: perf.rating),
            best: nil,
            record: nil
        )
    }

    private func fetchJSON<T: Decodable>(_ url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ChessServiceError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ChessServiceError.invalidUsername
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ChessServiceError.decodingError(error)
        }
    }

    private func fetchNDJSON<T: Decodable>(_ url: URL, headers: [String: String] = [:]) async throws -> [T] {
        var request = URLRequest(url: url)
        request.setValue("application/x-ndjson", forHTTPHeaderField: "Accept")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ChessServiceError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            if (response as? HTTPURLResponse)?.statusCode == 401 {
                throw ChessServiceError.authRequired
            }
            throw ChessServiceError.invalidUsername
        }
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        let lines = text.split(separator: "\n")
        let decoder = JSONDecoder()
        return lines.compactMap { line in
            try? decoder.decode(T.self, from: Data(line.utf8))
        }
    }
}

// MARK: - Lichess Internal Models

private struct LichessUser: Codable {
    let id: String
    let username: String
    let title: String?
    let createdAt: Int64
    let seenAt: Int64
    let profile: LichessProfile?
    let perfs: LichessPerfs?
}

private struct LichessProfile: Codable {
    let country: String?
    let realName: String?
}

private struct LichessPerfs: Codable {
    let bullet: LichessPerfStat?
    let blitz: LichessPerfStat?
    let rapid: LichessPerfStat?
    let correspondence: LichessPerfStat?
    let puzzle: LichessPerfStat?
}

private struct LichessPerfStat: Codable {
    let games: Int
    let rating: Int
    let rd: Int
    let prog: Int?
}

private struct LichessPuzzleActivity: Decodable {
    let date: Date
    let puzzleId: String
    let puzzleRating: Int
    let win: Bool

    private struct Puzzle: Decodable {
        let id: String
        let rating: Int
    }

    enum CodingKeys: String, CodingKey {
        case date, puzzle, win
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateMs = try container.decode(Int64.self, forKey: .date)
        date = Date(timeIntervalSince1970: TimeInterval(dateMs) / 1000)
        let puzzle = try container.decode(Puzzle.self, forKey: .puzzle)
        puzzleId = puzzle.id
        puzzleRating = puzzle.rating
        win = try container.decode(Bool.self, forKey: .win)
    }
}

private struct LichessGame: Codable {
    let id: String
    let rated: Bool?
    let speed: String?
    let perf: String?
    let createdAt: Int64
    let lastMoveAt: Int64
    let status: String
    let players: LichessPlayers
    let winner: String?

    func result(for username: String) -> GameResult {
        guard let winner = winner else { return .draw }
        let lower = username.lowercased()
        if winner == "white" && players.white.user?.id.lowercased() == lower { return .win }
        if winner == "black" && players.black.user?.id.lowercased() == lower { return .win }
        return .loss
    }

    func playerRating(for username: String) -> Int? {
        let lower = username.lowercased()
        if players.white.user?.id.lowercased() == lower { return players.white.rating }
        if players.black.user?.id.lowercased() == lower { return players.black.rating }
        return nil
    }
}

private struct LichessPlayers: Codable {
    let white: LichessPlayerEntry
    let black: LichessPlayerEntry
}

private struct LichessPlayerEntry: Codable {
    let user: LichessPlayerUser?
    let rating: Int?
}

private struct LichessPlayerUser: Codable {
    let id: String
    let name: String?
}

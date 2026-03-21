import Foundation

final class ChessComService: ChessService {
    static let shared = ChessComService()

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "SixtyFour/1.0"]
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    func validateUsername(_ username: String) async throws -> Bool {
        let url = URL(string: "https://api.chess.com/pub/player/\(username.lowercased())")!
        let (_, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    func fetchProfile(_ username: String) async throws -> PlayerProfile {
        let url = URL(string: "https://api.chess.com/pub/player/\(username.lowercased())")!
        return try await fetch(url)
    }

    func fetchStats(_ username: String) async throws -> PlayerStats {
        let url = URL(string: "https://api.chess.com/pub/player/\(username.lowercased())/stats")!
        return try await fetch(url)
    }

    func fetchFullStats(_ username: String) async throws -> FullPlayerStats {
        let url = URL(string: "https://api.chess.com/pub/player/\(username.lowercased())/stats")!
        return try await fetch(url)
    }

    func fetchTacticsChart(_ username: String, daysAgo: Int = 1) async throws -> TacticsChartResponse {
        let url = URL(string: "https://www.chess.com/callback/tactics/stats/\(username.lowercased())/chart?daysAgo=\(daysAgo)")!
        return try await fetch(url)
    }

    func fetchTodayPuzzleCount(_ username: String) async throws -> (solved: Int, failed: Int, rating: Int?) {
        let chart = try await fetchTacticsChart(username, daysAgo: 1)
        let today = chart.dailyStats.first(where: { $0.isToday })
        let latestRating = chart.ratings.last?.rating
        return (
            solved: today?.totalPassed ?? 0,
            failed: today?.totalFailed ?? 0,
            rating: today?.dayCloseRating ?? latestRating
        )
    }

    // MARK: - Games API

    func fetchGames(_ username: String, year: Int, month: Int) async throws -> GamesResponse {
        let monthStr = String(format: "%02d", month)
        let url = URL(string: "https://api.chess.com/pub/player/\(username.lowercased())/games/\(year)/\(monthStr)")!
        return try await fetch(url)
    }

    func fetchTodayGameCount(_ username: String, timeClass: TimeClass) async throws -> (played: Int, won: Int, lost: Int, drawn: Int, rating: Int?) {
        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)

        let response = try await fetchGames(username, year: year, month: month)

        let todayGames = response.games.filter { game in
            game.timeClass == timeClass.rawValue && cal.isDateInToday(game.endDate)
        }

        var won = 0, lost = 0, drawn = 0
        var latestRating: Int?

        for game in todayGames {
            switch game.result(for: username) {
            case .win: won += 1
            case .loss: lost += 1
            case .draw: drawn += 1
            case .unknown: break
            }
            if let player = game.player(for: username) {
                latestRating = player.rating
            }
        }

        return (played: won + lost + drawn, won: won, lost: lost, drawn: drawn, rating: latestRating)
    }

    func fetchGameRating(_ username: String, timeClass: TimeClass) async throws -> Int? {
        let stats = try await fetchFullStats(username)
        return stats.rating(for: timeClass)
    }

    /// Unified stats fetch based on goal mode
    func fetchTodayStats(_ username: String, mode: GoalMode, timeClass: TimeClass) async throws -> (solved: Int, failed: Int, rating: Int?) {
        switch mode {
        case .puzzles:
            let result = try await fetchTodayPuzzleCount(username)
            return (solved: result.solved, failed: result.failed, rating: result.rating)
        case .games:
            let gameResult = try await fetchTodayGameCount(username, timeClass: timeClass)
            // If no rating from today's games, fetch from stats API
            var rating = gameResult.rating
            if rating == nil {
                rating = try? await fetchGameRating(username, timeClass: timeClass)
            }
            return (solved: gameResult.won, failed: gameResult.lost, rating: rating)
        }
    }

    // MARK: - History (Games)

    func fetchGameHistory(_ username: String, timeClass: TimeClass, days: Int = 30) async throws -> [GameDayEntry] {
        let now = Date()
        let cal = Calendar.current
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)

        // Fetch current month
        var allGames = (try? await fetchGames(username, year: year, month: month).games) ?? []

        // If we need more than what's in the current month, fetch previous month
        if days > cal.component(.day, from: now) {
            let prevDate = cal.date(byAdding: .month, value: -1, to: now)!
            let prevYear = cal.component(.year, from: prevDate)
            let prevMonth = cal.component(.month, from: prevDate)
            let prevGames = (try? await fetchGames(username, year: prevYear, month: prevMonth).games) ?? []
            allGames = prevGames + allGames
        }

        // Filter by time class and date range
        let cutoff = cal.date(byAdding: .day, value: -days, to: now)!
        let filtered = allGames.filter { game in
            game.timeClass == timeClass.rawValue && game.endDate >= cutoff
        }

        // Group by day
        var dayMap: [String: GameDayEntry] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for game in filtered {
            let key = formatter.string(from: game.endDate)
            var entry = dayMap[key] ?? GameDayEntry(dateString: key, date: cal.startOfDay(for: game.endDate), won: 0, lost: 0, drawn: 0, latestRating: nil)
            switch game.result(for: username) {
            case .win: entry.won += 1
            case .loss: entry.lost += 1
            case .draw: entry.drawn += 1
            case .unknown: break
            }
            if let player = game.player(for: username) {
                entry.latestRating = player.rating
            }
            dayMap[key] = entry
        }

        return dayMap.values.sorted { $0.date < $1.date }
    }

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
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
}

struct GameDayEntry {
    let dateString: String
    let date: Date
    var won: Int
    var lost: Int
    var drawn: Int
    var latestRating: Int?

    var total: Int { won + lost + drawn }
}

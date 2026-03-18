import Foundation

enum ChessComError: LocalizedError {
    case invalidUsername
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Username not found on chess.com"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

final class ChessComService {
    static let shared = ChessComService()

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "SixtyFour/1.0"]
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

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ChessComError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ChessComError.invalidUsername
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ChessComError.decodingError(error)
        }
    }
}

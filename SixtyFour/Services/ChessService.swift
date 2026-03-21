import Foundation

protocol ChessService {
    func validateUsername(_ username: String) async throws -> Bool
    func fetchProfile(_ username: String) async throws -> PlayerProfile
    func fetchFullStats(_ username: String) async throws -> FullPlayerStats
    func fetchTodayStats(_ username: String, mode: GoalMode, timeClass: TimeClass) async throws -> (solved: Int, failed: Int, rating: Int?)
    func fetchTacticsChart(_ username: String, daysAgo: Int) async throws -> TacticsChartResponse
    func fetchGameHistory(_ username: String, timeClass: TimeClass, days: Int) async throws -> [GameDayEntry]
}

enum ChessServiceError: LocalizedError {
    case invalidUsername
    case networkError(Error)
    case decodingError(Error)
    case authRequired

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Username not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .authRequired:
            return "Authentication required. Please sign in again."
        }
    }
}

enum ChessServiceResolver {
    static var current: ChessService {
        switch UserStore.shared.platform {
        case .chesscom: return ChessComService.shared
        case .lichess: return LichessService.shared
        }
    }
}

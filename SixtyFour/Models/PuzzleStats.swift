import Foundation

struct TacticsChartResponse: Codable {
    let ratings: [RatingEntry]
    let dailyStats: [DailyStatEntry]
}

struct RatingEntry: Codable {
    let timestamp: Int
    let open: Int
    let rating: Int
    let high: Int
    let low: Int
}

struct DailyStatEntry: Codable {
    let timestamp: Int
    let totalPassed: Int
    let totalFailed: Int
    let totalTime: Int
    let dayCloseRating: Int?

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

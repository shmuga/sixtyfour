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

    /// The API returns timestamps offset by +7h from midnight UTC
    /// (e.g. 2026-03-18T07:00:00Z means March 18). Extract the calendar
    /// date by interpreting the raw timestamp in the API's implicit timezone,
    /// then compare against the user's local "today".
    var date: Date {
        let rawDate = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        // The API bakes in a +7h offset — strip it to get the intended calendar date
        var apiCal = Calendar(identifier: .gregorian)
        apiCal.timeZone = TimeZone(secondsFromGMT: 7 * 3600)!
        let comps = apiCal.dateComponents([.year, .month, .day], from: rawDate)
        // Reconstruct in user's local timezone so isDateInToday works correctly
        return Calendar.current.date(from: comps) ?? rawDate
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

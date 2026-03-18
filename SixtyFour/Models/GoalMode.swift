import Foundation

enum GoalMode: String, Codable, CaseIterable {
    case puzzles
    case games
}

enum TimeClass: String, Codable, CaseIterable {
    case bullet, blitz, rapid, daily

    var displayName: String {
        rawValue.uppercased()
    }

    var ratingLabel: String {
        switch self {
        case .bullet: return "BULLET RATING"
        case .blitz: return "BLITZ RATING"
        case .rapid: return "RAPID RATING"
        case .daily: return "DAILY RATING"
        }
    }

    var statsKey: String {
        switch self {
        case .bullet: return "chess_bullet"
        case .blitz: return "chess_blitz"
        case .rapid: return "chess_rapid"
        case .daily: return "chess_daily"
        }
    }
}

import Foundation

struct PlayerProfile: Codable {
    let username: String
    let avatar: String?
    let name: String?
    let title: String?
    let country: String?
    let joined: Int
    let lastOnline: Int

    enum CodingKeys: String, CodingKey {
        case username, avatar, name, title, country, joined
        case lastOnline = "last_online"
    }
}

struct PlayerStats: Codable {
    let tactics: TacticsRating?
    let puzzleRush: PuzzleRush?

    enum CodingKeys: String, CodingKey {
        case tactics
        case puzzleRush = "puzzle_rush"
    }
}

struct TacticsRating: Codable {
    let highest: RatingRecord?
    let lowest: RatingRecord?
}

struct RatingRecord: Codable {
    let rating: Int
    let date: Int
}

struct PuzzleRush: Codable {
    let daily: PuzzleRushRecord?
    let best: PuzzleRushRecord?
}

struct PuzzleRushRecord: Codable {
    let totalAttempts: Int
    let score: Int

    enum CodingKeys: String, CodingKey {
        case totalAttempts = "total_attempts"
        case score
    }
}

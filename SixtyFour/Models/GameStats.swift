import Foundation

struct GamesResponse: Codable {
    let games: [GameRecord]
}

struct GameRecord: Codable {
    let endTime: Int
    let timeClass: String
    let white: GamePlayer
    let black: GamePlayer
    let rated: Bool?

    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
        case timeClass = "time_class"
        case white, black, rated
    }

    var endDate: Date {
        Date(timeIntervalSince1970: TimeInterval(endTime))
    }

    func player(for username: String) -> GamePlayer? {
        let lower = username.lowercased()
        if white.username.lowercased() == lower { return white }
        if black.username.lowercased() == lower { return black }
        return nil
    }

    func result(for username: String) -> GameResult {
        guard let player = player(for: username) else { return .unknown }
        switch player.result {
        case "win": return .win
        case "checkmated", "resigned", "timeout", "abandoned": return .loss
        case "repetition", "insufficient", "stalemate", "agreed", "50move", "timevsinsufficient": return .draw
        default: return .unknown
        }
    }
}

enum GameResult {
    case win, loss, draw, unknown
}

struct GamePlayer: Codable {
    let username: String
    let rating: Int
    let result: String

    enum CodingKeys: String, CodingKey {
        case username, rating, result
    }
}

struct GameRatingCategory: Codable {
    let last: GameRatingValue?
    let best: GameRatingValue?
    let record: GameRecord_Stats?

    struct GameRatingValue: Codable {
        let rating: Int
    }

    struct GameRecord_Stats: Codable {
        let win: Int
        let loss: Int
        let draw: Int
    }
}

struct FullPlayerStats: Codable {
    let chessBullet: GameRatingCategory?
    let chessBlitz: GameRatingCategory?
    let chessRapid: GameRatingCategory?
    let chessDaily: GameRatingCategory?

    enum CodingKeys: String, CodingKey {
        case chessBullet = "chess_bullet"
        case chessBlitz = "chess_blitz"
        case chessRapid = "chess_rapid"
        case chessDaily = "chess_daily"
    }

    func rating(for timeClass: TimeClass) -> Int? {
        let category: GameRatingCategory?
        switch timeClass {
        case .bullet: category = chessBullet
        case .blitz: category = chessBlitz
        case .rapid: category = chessRapid
        case .daily: category = chessDaily
        }
        return category?.last?.rating
    }
}

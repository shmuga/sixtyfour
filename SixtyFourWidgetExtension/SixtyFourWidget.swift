import WidgetKit
import SwiftUI

struct PuzzleEntry: TimelineEntry {
    let date: Date
    let solved: Int
    let failed: Int
    let target: Int
    let rating: Int?
    let username: String
    let isPlaceholder: Bool
    let goalMode: GoalMode

    var remaining: Int { max(0, target - solved) }
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(solved) / Double(target))
    }

    var solvedLabel: String { goalMode == .games ? "WON" : "PASSED" }
    var failedLabel: String { goalMode == .games ? "LOST" : "FAILED" }

    static let puzzlePlaceholder = PuzzleEntry(
        date: .now, solved: 7, failed: 3, target: 10,
        rating: 1511, username: "player", isPlaceholder: true,
        goalMode: .puzzles
    )

    static let gamePlaceholder = PuzzleEntry(
        date: .now, solved: 2, failed: 1, target: 3,
        rating: 1247, username: "player", isPlaceholder: true,
        goalMode: .games
    )

    // Keep backward compat
    static let placeholder = puzzlePlaceholder
}

// MARK: - Puzzle Timeline Provider

struct PuzzleTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PuzzleEntry {
        .puzzlePlaceholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PuzzleEntry) -> Void) {
        if context.isPreview {
            completion(.puzzlePlaceholder)
            return
        }
        fetchEntry { completion($0) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PuzzleEntry>) -> Void) {
        fetchEntry { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry(completion: @escaping (PuzzleEntry) -> Void) {
        let defaults = UserDefaults(suiteName: UserStore.appGroupID) ?? .standard
        let username = defaults.string(forKey: "username") ?? ""
        let enabled = defaults.object(forKey: "puzzleGoalEnabled") as? Bool ?? true
        let target = defaults.object(forKey: "dailyPuzzleTarget") as? Int ?? 10

        guard !username.isEmpty, enabled else {
            completion(PuzzleEntry(
                date: .now, solved: 0, failed: 0, target: target,
                rating: nil, username: username, isPlaceholder: false,
                goalMode: .puzzles
            ))
            return
        }

        Task {
            do {
                let result = try await ChessServiceResolver.current.fetchTodayStats(username, mode: .puzzles, timeClass: .blitz)
                completion(PuzzleEntry(
                    date: .now,
                    solved: result.solved,
                    failed: result.failed,
                    target: target,
                    rating: result.rating,
                    username: username,
                    isPlaceholder: false,
                    goalMode: .puzzles
                ))
            } catch {
                completion(PuzzleEntry(
                    date: .now, solved: 0, failed: 0, target: target,
                    rating: nil, username: username, isPlaceholder: false,
                    goalMode: .puzzles
                ))
            }
        }
    }
}

struct PuzzleProgressWidget: Widget {
    let kind = "PuzzleProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PuzzleTimelineProvider()) { entry in
            PuzzleWidgetView(entry: entry)
                .containerBackground(Color(hex: 0x0D0D0F), for: .widget)
        }
        .configurationDisplayName("Puzzle Goal")
        .description("Track daily puzzle goal progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Game Timeline Provider

struct GameTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PuzzleEntry {
        .gamePlaceholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PuzzleEntry) -> Void) {
        if context.isPreview {
            completion(.gamePlaceholder)
            return
        }
        fetchEntry { completion($0) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PuzzleEntry>) -> Void) {
        fetchEntry { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry(completion: @escaping (PuzzleEntry) -> Void) {
        let defaults = UserDefaults(suiteName: UserStore.appGroupID) ?? .standard
        let username = defaults.string(forKey: "username") ?? ""
        let enabled = defaults.object(forKey: "gameGoalEnabled") as? Bool ?? true
        let target = defaults.object(forKey: "dailyGameTarget") as? Int ?? 3
        let timeClassStr = defaults.string(forKey: "gameTimeClass") ?? "blitz"
        let timeClass = TimeClass(rawValue: timeClassStr) ?? .blitz

        guard !username.isEmpty, enabled else {
            completion(PuzzleEntry(
                date: .now, solved: 0, failed: 0, target: target,
                rating: nil, username: username, isPlaceholder: false,
                goalMode: .games
            ))
            return
        }

        Task {
            do {
                let result = try await ChessServiceResolver.current.fetchTodayStats(username, mode: .games, timeClass: timeClass)
                completion(PuzzleEntry(
                    date: .now,
                    solved: result.solved,
                    failed: result.failed,
                    target: target,
                    rating: result.rating,
                    username: username,
                    isPlaceholder: false,
                    goalMode: .games
                ))
            } catch {
                completion(PuzzleEntry(
                    date: .now, solved: 0, failed: 0, target: target,
                    rating: nil, username: username, isPlaceholder: false,
                    goalMode: .games
                ))
            }
        }
    }
}

struct GameGoalWidget: Widget {
    let kind = "GameGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GameTimelineProvider()) { entry in
            PuzzleWidgetView(entry: entry)
                .containerBackground(Color(hex: 0x0D0D0F), for: .widget)
        }
        .configurationDisplayName("Game Goal")
        .description("Track daily game goal progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Combined Goal Widget

struct CombinedGoalEntry: TimelineEntry {
    let date: Date
    let puzzleSolved: Int
    let puzzleFailed: Int
    let puzzleTarget: Int
    let puzzleRating: Int?
    let gameSolved: Int
    let gameFailed: Int
    let gameTarget: Int
    let gameRating: Int?
    let username: String
    let isPlaceholder: Bool

    var puzzleRemaining: Int { max(0, puzzleTarget - puzzleSolved) }
    var gameRemaining: Int { max(0, gameTarget - gameSolved) }
    var puzzleProgress: Double {
        guard puzzleTarget > 0 else { return 0 }
        return min(1.0, Double(puzzleSolved) / Double(puzzleTarget))
    }
    var gameProgress: Double {
        guard gameTarget > 0 else { return 0 }
        return min(1.0, Double(gameSolved) / Double(gameTarget))
    }

    static let placeholder = CombinedGoalEntry(
        date: .now,
        puzzleSolved: 7, puzzleFailed: 3, puzzleTarget: 10, puzzleRating: 1511,
        gameSolved: 2, gameFailed: 1, gameTarget: 3, gameRating: 1247,
        username: "player", isPlaceholder: true
    )
}

struct CombinedGoalTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CombinedGoalEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CombinedGoalEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        fetchEntry { completion($0) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CombinedGoalEntry>) -> Void) {
        fetchEntry { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry(completion: @escaping (CombinedGoalEntry) -> Void) {
        let defaults = UserDefaults(suiteName: UserStore.appGroupID) ?? .standard
        let username = defaults.string(forKey: "username") ?? ""
        let puzzleTarget = defaults.object(forKey: "dailyPuzzleTarget") as? Int ?? 10
        let gameTarget = defaults.object(forKey: "dailyGameTarget") as? Int ?? 3
        let timeClassStr = defaults.string(forKey: "gameTimeClass") ?? "blitz"
        let timeClass = TimeClass(rawValue: timeClassStr) ?? .blitz

        guard !username.isEmpty else {
            completion(CombinedGoalEntry(
                date: .now,
                puzzleSolved: 0, puzzleFailed: 0, puzzleTarget: puzzleTarget, puzzleRating: nil,
                gameSolved: 0, gameFailed: 0, gameTarget: gameTarget, gameRating: nil,
                username: "", isPlaceholder: false
            ))
            return
        }

        Task {
            var pSolved = 0, pFailed = 0, pRating: Int?
            var gSolved = 0, gFailed = 0, gRating: Int?

            if let pResult = try? await ChessServiceResolver.current.fetchTodayStats(username, mode: .puzzles, timeClass: .blitz) {
                pSolved = pResult.solved
                pFailed = pResult.failed
                pRating = pResult.rating
            }
            if let gResult = try? await ChessServiceResolver.current.fetchTodayStats(username, mode: .games, timeClass: timeClass) {
                gSolved = gResult.solved
                gFailed = gResult.failed
                gRating = gResult.rating
            }

            completion(CombinedGoalEntry(
                date: .now,
                puzzleSolved: pSolved, puzzleFailed: pFailed, puzzleTarget: puzzleTarget, puzzleRating: pRating,
                gameSolved: gSolved, gameFailed: gFailed, gameTarget: gameTarget, gameRating: gRating,
                username: username, isPlaceholder: false
            ))
        }
    }
}

struct CombinedGoalWidget: Widget {
    let kind = "CombinedGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CombinedGoalTimelineProvider()) { entry in
            CombinedGoalWidgetView(entry: entry)
                .containerBackground(Color(hex: 0x0D0D0F), for: .widget)
        }
        .configurationDisplayName("Both Goals")
        .description("Track daily game and puzzle goals together.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Rating Widget

struct WidgetRatingEntry: TimelineEntry {
    let date: Date
    let rating: Int
    let bestRating: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let timeClass: TimeClass
    let username: String
    let isPlaceholder: Bool

    static let placeholder = WidgetRatingEntry(
        date: .now, rating: 1247, bestRating: 1385,
        wins: 312, losses: 198, draws: 47,
        timeClass: .blitz, username: "player", isPlaceholder: true
    )
}

struct RatingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetRatingEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetRatingEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        fetchEntry { completion($0) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetRatingEntry>) -> Void) {
        fetchEntry { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry(completion: @escaping (WidgetRatingEntry) -> Void) {
        let defaults = UserDefaults(suiteName: UserStore.appGroupID) ?? .standard
        let username = defaults.string(forKey: "username") ?? ""
        let timeClassStr = defaults.string(forKey: "gameTimeClass") ?? "blitz"
        let timeClass = TimeClass(rawValue: timeClassStr) ?? .blitz

        guard !username.isEmpty else {
            completion(WidgetRatingEntry(
                date: .now, rating: 0, bestRating: 0,
                wins: 0, losses: 0, draws: 0,
                timeClass: timeClass, username: "", isPlaceholder: false
            ))
            return
        }

        Task {
            do {
                let stats = try await ChessServiceResolver.current.fetchFullStats(username)
                let category = stats.category(for: timeClass)
                completion(WidgetRatingEntry(
                    date: .now,
                    rating: category?.last?.rating ?? 0,
                    bestRating: category?.best?.rating ?? 0,
                    wins: category?.record?.win ?? 0,
                    losses: category?.record?.loss ?? 0,
                    draws: category?.record?.draw ?? 0,
                    timeClass: timeClass,
                    username: username,
                    isPlaceholder: false
                ))
            } catch {
                completion(WidgetRatingEntry(
                    date: .now, rating: 0, bestRating: 0,
                    wins: 0, losses: 0, draws: 0,
                    timeClass: timeClass, username: username, isPlaceholder: false
                ))
            }
        }
    }
}

struct RatingWidget: Widget {
    let kind = "RatingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RatingTimelineProvider()) { entry in
            RatingWidgetView(entry: entry)
                .containerBackground(Color(hex: 0x0D0D0F), for: .widget)
        }
        .configurationDisplayName("Rating")
        .description("View your current chess rating and stats.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SixtyFourWidgetBundle: WidgetBundle {
    var body: some Widget {
        PuzzleProgressWidget()
        GameGoalWidget()
        CombinedGoalWidget()
        RatingWidget()
    }
}

// Widget needs its own Color extension since it's a separate target
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

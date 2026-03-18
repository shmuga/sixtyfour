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

    static let placeholder = PuzzleEntry(
        date: .now, solved: 52, failed: 23, target: 75,
        rating: 1511, username: "player", isPlaceholder: true,
        goalMode: .puzzles
    )
}

struct PuzzleTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PuzzleEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PuzzleEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
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
        let goalModeStr = defaults.string(forKey: "goalMode") ?? "puzzles"
        let goalMode = GoalMode(rawValue: goalModeStr) ?? .puzzles
        let timeClassStr = defaults.string(forKey: "gameTimeClass") ?? "blitz"
        let timeClass = TimeClass(rawValue: timeClassStr) ?? .blitz
        let target: Int
        if goalMode == .games {
            target = defaults.object(forKey: "dailyGameTarget") as? Int ?? 3
        } else {
            target = defaults.object(forKey: "dailyPuzzleTarget") as? Int ?? 10
        }

        guard !username.isEmpty else {
            completion(PuzzleEntry(
                date: .now, solved: 0, failed: 0, target: target,
                rating: nil, username: "", isPlaceholder: false,
                goalMode: goalMode
            ))
            return
        }

        Task {
            do {
                let result = try await ChessComService.shared.fetchTodayStats(username, mode: goalMode, timeClass: timeClass)
                completion(PuzzleEntry(
                    date: .now,
                    solved: result.solved,
                    failed: result.failed,
                    target: target,
                    rating: result.rating,
                    username: username,
                    isPlaceholder: false,
                    goalMode: goalMode
                ))
            } catch {
                completion(PuzzleEntry(
                    date: .now, solved: 0, failed: 0, target: target,
                    rating: nil, username: username, isPlaceholder: false,
                    goalMode: goalMode
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
        .configurationDisplayName("Goal Progress")
        .description("Track daily chess goal progress with activity rings.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SixtyFourWidgetBundle: WidgetBundle {
    var body: some Widget {
        PuzzleProgressWidget()
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

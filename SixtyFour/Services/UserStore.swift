import Foundation

final class UserStore: ObservableObject {
    static let shared = UserStore()
    static let appGroupID = "group.com.sixtyfour.shared"

    private let defaults: UserDefaults

    @Published var username: String {
        didSet { defaults.set(username, forKey: "username") }
    }

    @Published var dailyPuzzleTarget: Int {
        didSet { defaults.set(dailyPuzzleTarget, forKey: "dailyPuzzleTarget") }
    }

    @Published var dailyReminderEnabled: Bool {
        didSet { defaults.set(dailyReminderEnabled, forKey: "dailyReminderEnabled") }
    }

    @Published var goalReachedEnabled: Bool {
        didSet { defaults.set(goalReachedEnabled, forKey: "goalReachedEnabled") }
    }

    @Published var goalMode: GoalMode {
        didSet { defaults.set(goalMode.rawValue, forKey: "goalMode") }
    }

    @Published var gameTimeClass: TimeClass {
        didSet { defaults.set(gameTimeClass.rawValue, forKey: "gameTimeClass") }
    }

    @Published var dailyGameTarget: Int {
        didSet { defaults.set(dailyGameTarget, forKey: "dailyGameTarget") }
    }

    @Published var puzzleGoalEnabled: Bool {
        didSet { defaults.set(puzzleGoalEnabled, forKey: "puzzleGoalEnabled") }
    }

    @Published var gameGoalEnabled: Bool {
        didSet { defaults.set(gameGoalEnabled, forKey: "gameGoalEnabled") }
    }

    var activeTarget: Int {
        switch goalMode {
        case .puzzles: return dailyPuzzleTarget
        case .games: return dailyGameTarget
        }
    }

    var isOnboarded: Bool {
        !username.isEmpty
    }

    init() {
        let defaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        self.defaults = defaults
        self.username = defaults.string(forKey: "username") ?? ""
        self.dailyPuzzleTarget = defaults.object(forKey: "dailyPuzzleTarget") as? Int ?? 10
        self.dailyReminderEnabled = defaults.object(forKey: "dailyReminderEnabled") as? Bool ?? true
        self.goalReachedEnabled = defaults.object(forKey: "goalReachedEnabled") as? Bool ?? true
        self.goalMode = GoalMode(rawValue: defaults.string(forKey: "goalMode") ?? "") ?? .games
        self.gameTimeClass = TimeClass(rawValue: defaults.string(forKey: "gameTimeClass") ?? "") ?? .blitz
        self.dailyGameTarget = defaults.object(forKey: "dailyGameTarget") as? Int ?? 3
        self.puzzleGoalEnabled = defaults.object(forKey: "puzzleGoalEnabled") as? Bool ?? true
        self.gameGoalEnabled = defaults.object(forKey: "gameGoalEnabled") as? Bool ?? true
    }

    func reset() {
        username = ""
        dailyPuzzleTarget = 10
        dailyGameTarget = 3
        goalMode = .games
        gameTimeClass = .blitz
        puzzleGoalEnabled = true
        gameGoalEnabled = true
        NotificationService.shared.cancelAll()
    }
}

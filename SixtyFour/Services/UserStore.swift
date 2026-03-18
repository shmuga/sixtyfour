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
    }

    func reset() {
        username = ""
        dailyPuzzleTarget = 10
        NotificationService.shared.cancelAll()
    }
}

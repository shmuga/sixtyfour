import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let dailyReminderID = "daily-puzzle-reminder"

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // Set to true to fire notification in 5 seconds (for testing)
    private let debugMode = false

    /// Schedule a notification at 7 PM today if the goal isn't reached.
    /// Call this after every stats fetch.
    func updateDailyReminder(solved: Int, target: Int, enabled: Bool, mode: GoalMode = .puzzles) {
        // Cancel any existing reminder first
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        guard enabled else { return }

        let remaining = max(0, target - solved)
        guard remaining > 0 else { return } // Goal reached, no reminder needed

        let content = UNMutableNotificationContent()

        switch mode {
        case .puzzles:
            content.title = "Puzzle Reminder"
            content.body = "You have \(remaining) puzzle\(remaining == 1 ? "" : "s") left to reach your daily goal!"
        case .games:
            content.title = "Game Reminder"
            content.body = "You have \(remaining) game\(remaining == 1 ? "" : "s") left to reach your daily goal!"
        }

        content.sound = .default

        let trigger: UNNotificationTrigger
        if debugMode {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        } else {
            // Only schedule if 7 PM hasn't passed yet
            let now = Date()
            var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
            components.hour = 19
            components.minute = 0

            guard let fireDate = Calendar.current.date(from: components),
                  fireDate > now else { return }

            let triggerComponents = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        }

        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule a combined reminder that fires if ANY enabled goal is incomplete.
    func updateCombinedReminder(
        puzzleSolved: Int, puzzleTarget: Int, puzzleEnabled: Bool,
        gameSolved: Int, gameTarget: Int, gameEnabled: Bool,
        reminderEnabled: Bool
    ) {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        guard reminderEnabled else { return }

        let puzzleRemaining = puzzleEnabled ? max(0, puzzleTarget - puzzleSolved) : 0
        let gameRemaining = gameEnabled ? max(0, gameTarget - gameSolved) : 0

        guard puzzleRemaining > 0 || gameRemaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Reminder"

        if puzzleRemaining > 0 && gameRemaining > 0 {
            content.body = "\(puzzleRemaining) puzzle\(puzzleRemaining == 1 ? "" : "s") and \(gameRemaining) game\(gameRemaining == 1 ? "" : "s") left to reach your daily goal!"
        } else if puzzleRemaining > 0 {
            content.body = "\(puzzleRemaining) puzzle\(puzzleRemaining == 1 ? "" : "s") left to reach your daily goal!"
        } else {
            content.body = "\(gameRemaining) game\(gameRemaining == 1 ? "" : "s") left to reach your daily goal!"
        }

        content.sound = .default

        let trigger: UNNotificationTrigger
        if debugMode {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        } else {
            let now = Date()
            var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
            components.hour = 19
            components.minute = 0

            guard let fireDate = Calendar.current.date(from: components),
                  fireDate > now else { return }

            let triggerComponents = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        }

        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}

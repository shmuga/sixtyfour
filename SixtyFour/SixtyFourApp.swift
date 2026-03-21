import SwiftUI

@main
struct SixtyFourApp: App {
    @StateObject private var store = UserStore.shared

    var body: some Scene {
        WindowGroup {
            if store.isOnboarded {
                MainTabView()
                    .environmentObject(store)
                    .task {
                        if store.dailyReminderEnabled {
                            await NotificationService.shared.requestPermission()
                        }
                    }
                    .onOpenURL { url in
                        handleWidgetURL(url)
                    }
            } else {
                OnboardingView()
                    .environmentObject(store)
            }
        }
    }

    private func handleWidgetURL(_ url: URL) {
        guard url.scheme == "sixtyfour",
              url.host == "open-chesscom" else { return }

        let isPlay = url.path.contains("play")

        let targetURL: URL
        if store.platform == .lichess {
            targetURL = URL(string: isPlay ? "https://lichess.org/" : "https://lichess.org/training")!
        } else {
            targetURL = URL(string: isPlay ? "https://www.chess.com/play" : "https://www.chess.com/puzzles")!
        }

        UIApplication.shared.open(targetURL)
    }
}

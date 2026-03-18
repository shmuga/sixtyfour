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

        let chessURL: URL
        if url.path.contains("play") {
            chessURL = URL(string: "https://www.chess.com/play")!
        } else {
            chessURL = URL(string: "https://www.chess.com/puzzles")!
        }

        UIApplication.shared.open(chessURL)
    }
}

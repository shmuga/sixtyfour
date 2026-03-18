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
            } else {
                OnboardingView()
                    .environmentObject(store)
            }
        }
    }
}

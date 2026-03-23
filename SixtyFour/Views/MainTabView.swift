import SwiftUI

enum Tab: String, CaseIterable {
    case home, stats, settings

    var label: String { rawValue.uppercased() }

    var icon: String {
        switch self {
        case .home: return "chart.bar.fill"
        case .stats: return "chart.xyaxis.line"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var store: UserStore
    @State private var selected: Tab = .home

    init() {
        let item = UITabBarItemAppearance()
        let font = UIFont.monospacedSystemFont(ofSize: 8, weight: .medium)
        item.normal.titleTextAttributes = [.font: font]
        item.selected.titleTextAttributes = [.font: font]

        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selected) {
            DashboardView()
                .tabItem {
                    Image(systemName: Tab.home.icon)
                    Text(Tab.home.label)
                }
                .tag(Tab.home)

            HistoryView()
                .tabItem {
                    Image(systemName: Tab.stats.icon)
                    Text(Tab.stats.label)
                }
                .tag(Tab.stats)

            SettingsView()
                .tabItem {
                    Image(systemName: Tab.settings.icon)
                    Text(Tab.settings.label)
                }
                .tag(Tab.settings)
        }
        .tint(SFColor.amber)
        .preferredColorScheme(.dark)
    }
}

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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selected {
                case .home: DashboardView()
                case .stats: HistoryView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 64)

            // Glass tab bar
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selected = tab
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 19))
                            Text(tab.label)
                                .font(.system(size: 8, weight: .regular, design: .monospaced))
                                .kerning(0.8)
                        }
                        .foregroundColor(selected == tab ? SFColor.amber : SFColor.ivory3)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    Rectangle()
                        .fill(SFColor.s1.opacity(0.6))
                }
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            )
        }
        .background(SFColor.s2.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

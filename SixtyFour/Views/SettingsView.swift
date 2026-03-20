import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var store: UserStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                Text("SETTINGS")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(SFColor.ivory2)
                    .kerning(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Account section
                sectionLabel(icon: "person", text: "ACCOUNT")

                HStack(alignment: .top, spacing: 8) {
                    CfgRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Username")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(SFColor.ivory)
                            Text("@\(store.username)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(SFColor.ivory3)
                        }
                    } trailing: {
                        Text("chess.com \u{2197}")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SFColor.amber)
                    }

                    Button {
                        store.reset()
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 13))
                            .foregroundColor(SFColor.red)
                            .frame(maxHeight: .infinity)
                            .frame(width: 44)
                            .background(RoundedRectangle(cornerRadius: 12).fill(SFColor.red.opacity(0.1)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SFColor.red.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.bottom, 7)
                }

                // Goals section
                sectionLabel(icon: "flag", text: "GOALS")

                CfgRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tracking")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SFColor.ivory)
                        Text(goalTrackingLabel)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SFColor.ivory3)
                    }
                } trailing: {
                    HStack(spacing: 0) {
                        goalOptionButton(.puzzles, label: "Puz")
                        goalOptionButton(.games, label: "Gam")
                        goalOptionButton(.both, label: "Both")
                    }
                    .background(RoundedRectangle(cornerRadius: 8).fill(SFColor.s4))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(SFColor.border, lineWidth: 1))
                }

                // Time class
                CfgRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time Class")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SFColor.ivory)
                        Text(store.gameTimeClass.displayName.lowercased())
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SFColor.ivory3)
                    }
                } trailing: {
                    HStack(spacing: 0) {
                        ForEach(TimeClass.allCases, id: \.self) { tc in
                            timeClassButton(tc)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 8).fill(SFColor.s4))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(SFColor.border, lineWidth: 1))
                }

                // Notifications section
                sectionLabel(icon: "bell", text: "NOTIFICATIONS")

                ToggleRow(label: "Daily reminder (7 PM)", isOn: $store.dailyReminderEnabled)
                    .onChange(of: store.dailyReminderEnabled) { _, enabled in
                        if enabled {
                            Task { await NotificationService.shared.requestPermission() }
                        } else {
                            NotificationService.shared.cancelAll()
                        }
                    }


            }
            .padding(.horizontal, 17)
            .padding(.top, 17)
            .padding(.bottom, 20)
        }
        .background(SFColor.s2)
    }

    private enum GoalOption { case puzzles, games, both }

    private var currentGoalOption: GoalOption {
        if store.puzzleGoalEnabled && store.gameGoalEnabled { return .both }
        if store.gameGoalEnabled { return .games }
        return .puzzles
    }

    private var goalTrackingLabel: String {
        switch currentGoalOption {
        case .puzzles: return "puzzles only"
        case .games: return "games only"
        case .both: return "puzzles & games"
        }
    }

    private func goalOptionButton(_ option: GoalOption, label: String) -> some View {
        let selected = currentGoalOption == option
        return Button {
            switch option {
            case .puzzles:
                store.puzzleGoalEnabled = true
                store.gameGoalEnabled = false
                store.goalMode = .puzzles
            case .games:
                store.puzzleGoalEnabled = false
                store.gameGoalEnabled = true
                store.goalMode = .games
            case .both:
                store.puzzleGoalEnabled = true
                store.gameGoalEnabled = true
            }
            WidgetCenter.shared.reloadAllTimelines()
        } label: {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(selected ? SFColor.void_ : SFColor.ivory3)
                .kerning(0.5)
                .padding(.horizontal, 7)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(selected ? SFColor.amber : Color.clear)
                )
        }
    }

    private func timeClassButton(_ tc: TimeClass) -> some View {
        Button {
            store.gameTimeClass = tc
            WidgetCenter.shared.reloadAllTimelines()
        } label: {
            Text(tc.displayName.prefix(3))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(store.gameTimeClass == tc ? SFColor.void_ : SFColor.ivory3)
                .kerning(0.5)
                .padding(.horizontal, 7)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(store.gameTimeClass == tc ? SFColor.amber : Color.clear)
                )
        }
    }

    private func sectionLabel(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .kerning(2)
        }
        .foregroundColor(SFColor.amber)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 14)
        .padding(.bottom, 7)
    }
}

struct CfgRow<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack {
            leading
            Spacer()
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SFColor.border, lineWidth: 1))
        .padding(.bottom, 7)
    }
}

struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        CfgRow {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SFColor.ivory)
        } trailing: {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(SFColor.amber)
        }
    }
}

struct StepperButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundColor(SFColor.ivory)
                .frame(width: 27, height: 27)
                .background(Circle().fill(SFColor.s4))
                .overlay(Circle().stroke(SFColor.border, lineWidth: 1))
        }
    }
}

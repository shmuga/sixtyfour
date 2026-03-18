import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var store: UserStore
    @State private var targetText = ""

    private var isGames: Bool { store.goalMode == .games }

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
                    Text("chess.com ↗")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(SFColor.amber)
                }

                // Goal mode section
                sectionLabel(icon: "flag", text: "GOAL MODE")

                CfgRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tracking")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SFColor.ivory)
                        Text(isGames ? "Games" : "Puzzles")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SFColor.ivory3)
                    }
                } trailing: {
                    HStack(spacing: 0) {
                        goalModeButton(.puzzles, label: "PUZZLES")
                        goalModeButton(.games, label: "GAMES")
                    }
                    .background(RoundedRectangle(cornerRadius: 8).fill(SFColor.s4))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(SFColor.border, lineWidth: 1))
                }

                // Time class (games only)
                if isGames {
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
                }

                // Daily target section
                sectionLabel(icon: "target", text: "DAILY TARGET")

                CfgRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isGames ? "Game Goal" : "Puzzle Goal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SFColor.ivory)
                        Text("per day")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SFColor.ivory3)
                    }
                } trailing: {
                    HStack(spacing: 7) {
                        StepperButton(symbol: "minus") {
                            if currentTarget > 1 {
                                setCurrentTarget(currentTarget - 1)
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }

                        TextField("", text: $targetText)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(SFColor.amber)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .frame(width: 44)
                            .onChange(of: targetText) { _, newVal in
                                if let num = Int(newVal), num >= 1, num <= 999 {
                                    setCurrentTarget(num)
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }

                        StepperButton(symbol: "plus") {
                            if currentTarget < 999 {
                                setCurrentTarget(currentTarget + 1)
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
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

                // Sign out
                Button {
                    store.reset()
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Text("SIGN OUT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(SFColor.red)
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 12).fill(SFColor.red.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SFColor.red.opacity(0.2), lineWidth: 1))
                }
                .padding(.top, 24)
            }
            .padding(.horizontal, 17)
            .padding(.top, 17)
            .padding(.bottom, 20)
        }
        .background(SFColor.s2)
        .onAppear { targetText = "\(currentTarget)" }
        .onChange(of: store.goalMode) { _, _ in
            targetText = "\(currentTarget)"
        }
    }

    private var currentTarget: Int {
        isGames ? store.dailyGameTarget : store.dailyPuzzleTarget
    }

    private func setCurrentTarget(_ value: Int) {
        if isGames {
            store.dailyGameTarget = value
        } else {
            store.dailyPuzzleTarget = value
        }
        targetText = "\(value)"
    }

    private func goalModeButton(_ mode: GoalMode, label: String) -> some View {
        Button {
            store.goalMode = mode
            WidgetCenter.shared.reloadAllTimelines()
        } label: {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(store.goalMode == mode ? SFColor.void_ : SFColor.ivory3)
                .kerning(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(store.goalMode == mode ? SFColor.amber : Color.clear)
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

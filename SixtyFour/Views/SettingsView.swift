import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var store: UserStore
    @State private var targetText = ""

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

                // Daily target section
                sectionLabel(icon: "target", text: "DAILY TARGET")

                CfgRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Puzzle Goal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SFColor.ivory)
                        Text("per day")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(SFColor.ivory3)
                    }
                } trailing: {
                    HStack(spacing: 7) {
                        StepperButton(symbol: "minus") {
                            if store.dailyPuzzleTarget > 1 {
                                store.dailyPuzzleTarget -= 1
                                targetText = "\(store.dailyPuzzleTarget)"
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
                                    store.dailyPuzzleTarget = num
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }

                        StepperButton(symbol: "plus") {
                            if store.dailyPuzzleTarget < 999 {
                                store.dailyPuzzleTarget += 1
                                targetText = "\(store.dailyPuzzleTarget)"
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
        .onAppear { targetText = "\(store.dailyPuzzleTarget)" }
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

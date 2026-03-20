import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: UserStore
    @State private var dailyStats: [DailyStatEntry] = []
    @State private var gameDayStats: [GameDayEntry] = []
    @State private var isLoading = true

    private var isGames: Bool { store.goalMode == .games }
    private var bothGoalsEnabled: Bool { store.puzzleGoalEnabled && store.gameGoalEnabled }

    // Puzzle stats
    private var totalSolved: Int { dailyStats.reduce(0) { $0 + $1.totalPassed } }
    private var totalFailed: Int { dailyStats.reduce(0) { $0 + $1.totalFailed } }
    private var total: Int { totalSolved + totalFailed }
    private var accuracy: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(totalSolved) / Double(total) * 100))
    }

    // Game stats
    private var totalWon: Int { gameDayStats.reduce(0) { $0 + $1.won } }
    private var totalLost: Int { gameDayStats.reduce(0) { $0 + $1.lost } }
    private var totalDrawn: Int { gameDayStats.reduce(0) { $0 + $1.drawn } }
    private var totalGames: Int { totalWon + totalLost + totalDrawn }
    private var winRate: Int {
        guard totalGames > 0 else { return 0 }
        return Int(round(Double(totalWon) / Double(totalGames) * 100))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("HISTORY")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(SFColor.ivory2)
                        .kerning(2)
                    Spacer()

                    if bothGoalsEnabled {
                        compactGoalToggle
                    }

                    Text("LAST 30 DAYS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(SFColor.amber)
                        .kerning(1.5)
                }
                .padding(.bottom, 18)

                // Summary tiles
                if isGames {
                    HStack(spacing: 7) {
                        SummaryTile(
                            value: "\(winRate)%",
                            label: "WIN RATE",
                            color: SFColor.green,
                            icon: "checkmark.circle"
                        )
                        SummaryTile(
                            value: "\(totalGames)",
                            label: "TOTAL",
                            color: SFColor.blue,
                            icon: "number"
                        )
                    }
                    .padding(.bottom, 11)
                } else {
                    HStack(spacing: 7) {
                        SummaryTile(
                            value: "\(accuracy)%",
                            label: "ACCURACY",
                            color: SFColor.green,
                            icon: "checkmark.circle"
                        )
                        SummaryTile(
                            value: "\(total)",
                            label: "TOTAL",
                            color: SFColor.blue,
                            icon: "number"
                        )
                    }
                    .padding(.bottom, 11)
                }

                // Daily breakdown label
                Text("DAILY  BREAKDOWN")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
                    .kerning(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 7)

                if isLoading {
                    ProgressView().tint(SFColor.amber).padding(.top, 40)
                } else if isGames {
                    if gameDayStats.isEmpty {
                        Text("No data found")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(SFColor.ivory3)
                            .padding(.top, 30)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(gameDayStats.reversed(), id: \.dateString) { day in
                                GameDayRow(entry: day, username: store.username)
                            }
                        }
                    }
                } else {
                    if dailyStats.isEmpty {
                        Text("No data found")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(SFColor.ivory3)
                            .padding(.top, 30)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(dailyStats.reversed(), id: \.timestamp) { day in
                                DayRow(entry: day)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 17)
            .padding(.bottom, 20)
        }
        .background(SFColor.s2)
        .task(id: "\(store.username)-\(store.goalMode.rawValue)-\(store.gameTimeClass.rawValue)") { await loadStats() }
    }

    private var compactGoalToggle: some View {
        HStack(spacing: 0) {
            compactToggleButton(.games, icon: "flag.pattern.checkered")
            compactToggleButton(.puzzles, icon: "puzzlepiece.fill")
        }
        .background(RoundedRectangle(cornerRadius: 9).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(SFColor.border, lineWidth: 1))
        .padding(.trailing, 8)
    }

    private func compactToggleButton(_ mode: GoalMode, icon: String) -> some View {
        Button {
            store.goalMode = mode
        } label: {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(store.goalMode == mode ? SFColor.void_ : SFColor.ivory3)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(store.goalMode == mode ? SFColor.amber : Color.clear)
                )
        }
        .padding(2)
    }

    private func loadStats() async {
        isLoading = true
        if isGames {
            do {
                gameDayStats = try await ChessComService.shared.fetchGameHistory(store.username, timeClass: store.gameTimeClass, days: 30)
            } catch {
                gameDayStats = []
            }
        } else {
            do {
                let chart = try await ChessComService.shared.fetchTacticsChart(store.username, daysAgo: 30)
                dailyStats = chart.dailyStats.filter { $0.totalPassed > 0 || $0.totalFailed > 0 }
            } catch {
                dailyStats = []
            }
        }
        isLoading = false
    }
}

struct DayRow: View {
    let entry: DailyStatEntry

    private var total: Int { entry.totalPassed + entry.totalFailed }
    private var accuracy: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(entry.totalPassed) / Double(total) * 100))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Date
            Text(entry.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(SFColor.ivory2)
                .frame(width: 80, alignment: .leading)

            // Solved
            HStack(spacing: 3) {
                Circle().fill(SFColor.green).frame(width: 5, height: 5)
                Text("\(entry.totalPassed)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.green)
            }
            .frame(width: 50, alignment: .leading)

            // Failed
            HStack(spacing: 3) {
                Circle().fill(SFColor.red).frame(width: 5, height: 5)
                Text("\(entry.totalFailed)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.red)
            }
            .frame(width: 50, alignment: .leading)

            Spacer()

            // Accuracy
            Text("\(accuracy)%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(SFColor.ivory3)

            // Rating
            if let rating = entry.dayCloseRating {
                Text("\(rating)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(SFColor.amber)
                    .frame(width: 45, alignment: .trailing)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SFColor.border, lineWidth: 1))
    }
}

struct GameDayRow: View {
    let entry: GameDayEntry
    let username: String

    private var winRate: Int {
        guard entry.total > 0 else { return 0 }
        return Int(round(Double(entry.won) / Double(entry.total) * 100))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Date
            Text(entry.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(SFColor.ivory2)
                .frame(width: 80, alignment: .leading)

            // Won
            HStack(spacing: 3) {
                Circle().fill(SFColor.green).frame(width: 5, height: 5)
                Text("\(entry.won)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.green)
            }
            .frame(width: 50, alignment: .leading)

            // Lost
            HStack(spacing: 3) {
                Circle().fill(SFColor.red).frame(width: 5, height: 5)
                Text("\(entry.lost)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.red)
            }
            .frame(width: 50, alignment: .leading)

            Spacer()

            // Win rate
            Text("\(winRate)%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(SFColor.ivory3)

            // Rating
            if let rating = entry.latestRating {
                Text("\(rating)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(SFColor.amber)
                    .frame(width: 45, alignment: .trailing)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SFColor.border, lineWidth: 1))
    }
}

struct SummaryTile: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: 50, height: 30)
                    .blur(radius: 16)
                    .offset(y: -10)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            .frame(height: 20)
            .padding(.bottom, 3)

            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .kerning(1.3)
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 13).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(SFColor.border, lineWidth: 1))
    }
}

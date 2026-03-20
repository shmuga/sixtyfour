import SwiftUI
import WidgetKit

struct DashboardView: View {
    @EnvironmentObject var store: UserStore

    // Puzzle data
    @State private var puzzleSolved = 0
    @State private var puzzleFailed = 0
    @State private var puzzleRating: Int?
    @State private var puzzleSparkline: [Int] = Array(repeating: 0, count: 7)

    // Game data
    @State private var gameSolved = 0
    @State private var gameFailed = 0
    @State private var gameRating: Int?
    @State private var gameSparkline: [Int] = Array(repeating: 0, count: 7)

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var profile: PlayerProfile?

    // Computed properties that read from the appropriate set based on goalMode
    private var solved: Int { isGames ? gameSolved : puzzleSolved }
    private var failed: Int { isGames ? gameFailed : puzzleFailed }
    private var rating: Int? { isGames ? gameRating : puzzleRating }
    private var sparkline: [Int] { isGames ? gameSparkline : puzzleSparkline }

    private var remaining: Int { max(0, store.activeTarget - solved) }
    private var total: Int { solved + failed }
    private var accuracy: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(solved) / Double(total) * 100))
    }
    private var progress: Double {
        guard store.activeTarget > 0 else { return 0 }
        return min(1.0, Double(solved) / Double(store.activeTarget))
    }

    private var isGames: Bool { store.goalMode == .games }
    private var bothGoalsEnabled: Bool { store.puzzleGoalEnabled && store.gameGoalEnabled }

    private var ratingLabel: String {
        isGames ? store.gameTimeClass.ratingLabel : "PUZZLE RATING"
    }

    private var solvedLabel: String { isGames ? "WON" : "PASSED" }
    private var failedLabel: String { isGames ? "LOST" : "FAILED" }
    private var unitName: String { isGames ? "games" : "puzzles" }

    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(spacing: 0) {
                // App bar
                HStack {
                    HStack(spacing: 0) {
                        Text("SIXTY")
                            .foregroundColor(SFColor.ivory)
                        Text("FOUR")
                            .foregroundColor(SFColor.amber)
                    }
                    .font(.system(size: 27, weight: .bold))
                    .kerning(3)

                    Spacer()

                    // Games/Puzzles toggle (only if both goals enabled)
                    if bothGoalsEnabled {
                        compactGoalToggle
                    }

                    // Refresh
                    Button {
                        Task { await loadStats() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SFColor.ivory3)
                            .frame(width: 33, height: 33)
                            .background(Circle().fill(SFColor.s3))
                            .overlay(Circle().stroke(SFColor.border, lineWidth: 1))
                    }
                }
                .padding(.bottom, 14)

                // Profile card
                if let profile {
                    profileCard(profile)
                        .padding(.bottom, 16)
                }

                // Hero rating card
                heroCard
                    .padding(.bottom, 16)

                // Stat tiles
                HStack(spacing: 7) {
                    StatTile(value: "\(remaining)", label: "LEFT", color: SFColor.amber, icon: "target")
                    StatTile(value: "\(solved)", label: solvedLabel, color: SFColor.green, icon: "checkmark.circle")
                    StatTile(value: "\(failed)", label: failedLabel, color: SFColor.red, icon: "xmark.circle")
                }
                .padding(.bottom, 16)

                // Progress bar
                progressCard
                    .padding(.bottom, 16)

                // Streak (placeholder)
                HStack(spacing: 6) {
                    Image(systemName: "flame")
                        .font(.system(size: 11))
                    Text("\(solved > 0 ? "Active today" : (isGames ? "Play a game!" : "Solve a puzzle!"))")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .kerning(0.5)
                }
                .foregroundColor(SFColor.amber)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [SFColor.amber.opacity(0.13), SFColor.amber.opacity(0.04)], startPoint: .leading, endPoint: .trailing))
                        .overlay(Capsule().stroke(SFColor.borderAmber, lineWidth: 1))
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 17)
            .padding(.top, 17)
        }
        .scrollBounceBehavior(.always)
        .background(SFColor.s2)
        .refreshable { await loadStats(showLoading: false) }
        .task(id: "\(store.username)-\(store.gameTimeClass.rawValue)") { await loadStats() }
        .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Compact Goal Mode Toggle

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

    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Label
                HStack(spacing: 5) {
                    Image(systemName: "chess.pawn.fill")
                        .font(.system(size: 9))
                        .foregroundColor(SFColor.amber)
                    Text(ratingLabel)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(SFColor.ivory3)
                        .kerning(2)
                }
                .padding(.bottom, 3)

                // Big number
                if isLoading {
                    ProgressView().tint(SFColor.amber).padding(.vertical, 16)
                } else {
                    Text("\(rating ?? 0)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(SFColor.ivory)
                        .kerning(1)
                }

                // Delta badge
                if !isLoading {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                        Text("+\(solved) today")
                            .font(.system(size: 9, design: .monospaced))
                    }
                    .foregroundColor(SFColor.green)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(SFColor.green.opacity(0.12))
                            .overlay(Capsule().stroke(SFColor.green.opacity(0.2), lineWidth: 1))
                    )
                    .padding(.top, 6)
                }

                // Sparkline — last 7 days
                VStack(spacing: 0) {
                    Rectangle().fill(SFColor.border).frame(height: 1)
                    Spacer(minLength: 4)
                    let maxVal = max(sparkline.max() ?? 1, 1)
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(0..<7, id: \.self) { i in
                            let barHeight = max(3, CGFloat(sparkline[i]) / CGFloat(maxVal) * 28)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i == 6 ? LinearGradient(colors: [SFColor.amber, SFColor.amber2], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [SFColor.s6, SFColor.s6], startPoint: .top, endPoint: .bottom))
                                .frame(width: 16, height: barHeight)
                                .shadow(color: i == 6 ? SFColor.amber.opacity(0.28) : .clear, radius: 3)
                        }
                        Spacer()
                    }
                }
                .frame(height: 32)
                .padding(.top, 6)
            }

            // Knight watermark
            Image(systemName: "chess.pawn.fill")
                .font(.system(size: 44))
                .foregroundColor(SFColor.amber.opacity(0.15))
                .offset(x: -5, y: 8)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(SFColor.s3)
                // Amber glow top-right
                Circle()
                    .fill(SFColor.amber.opacity(0.08))
                    .frame(width: 90, height: 90)
                    .blur(radius: 30)
                    .offset(x: 40, y: -25)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(SFColor.border, lineWidth: 1))
    }

    private var progressCard: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "target")
                        .font(.system(size: 13))
                        .foregroundColor(SFColor.amber)
                    Text("Daily Target")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SFColor.ivory2)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(SFColor.amber)
            }
            .padding(.bottom, 9)

            // Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 99)
                        .fill(SFColor.s5)
                    RoundedRectangle(cornerRadius: 99)
                        .fill(LinearGradient(colors: [SFColor.amber2, SFColor.amber], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress)
                        .shadow(color: SFColor.amber.opacity(0.28), radius: 4.5)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 7)

            HStack {
                Text("\(solved) / \(store.activeTarget) \(unitName)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
                Spacer()
                Text("\(remaining) left")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
            }

            // Divider + embedded stepper
            Rectangle().fill(SFColor.border).frame(height: 1)
                .padding(.vertical, 10)

            HStack {
                Text("Goal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SFColor.ivory3)
                Spacer()
                HStack(spacing: 7) {
                    StepperButton(symbol: "minus") {
                        if currentTarget > 1 {
                            setCurrentTarget(currentTarget - 1)
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }

                    Text("\(currentTarget)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(SFColor.amber)
                        .frame(width: 36)
                        .multilineTextAlignment(.center)

                    StepperButton(symbol: "plus") {
                        if currentTarget < 999 {
                            setCurrentTarget(currentTarget + 1)
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 13).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(SFColor.border, lineWidth: 1))
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
    }

    private func avatarView(size: CGFloat) -> some View {
        Group {
            if let avatarURL = profile?.avatar, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsAvatar(size: size)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initialsAvatar(size: size)
            }
        }
    }

    private func initialsAvatar(size: CGFloat) -> some View {
        Circle()
            .fill(LinearGradient(colors: [SFColor.amber, SFColor.amber2], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Text(store.username.prefix(2).uppercased())
                    .font(.system(size: size * 0.3, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.void_)
            )
    }

    private func profileCard(_ profile: PlayerProfile) -> some View {
        HStack(spacing: 11) {
            avatarView(size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    if let title = profile.title {
                        Text(title)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(SFColor.amber)
                    }
                    Text("@\(profile.username)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SFColor.ivory)
                }
                HStack(spacing: 10) {
                    profileDetail(icon: "clock", text: lastOnlineText(profile.lastOnline))
                    profileDetail(icon: "calendar", text: memberSinceText(profile.joined))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 13).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(SFColor.border, lineWidth: 1))
    }

    private func profileDetail(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 9, design: .monospaced))
        }
        .foregroundColor(SFColor.ivory3)
    }

    private func lastOnlineText(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "Online now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    private func memberSinceText(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        if years < 1 {
            let months = Calendar.current.dateComponents([.month], from: date, to: Date()).month ?? 0
            return "\(months)mo member"
        }
        return "\(years)yr member"
    }

    private func loadStats(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil
        do {
            async let profileFetch = ChessComService.shared.fetchProfile(store.username)
            async let delay: () = Task.sleep(nanoseconds: 150_000_000)

            // Fetch both enabled modes in parallel
            async let puzzleFetch: (solved: Int, failed: Int, rating: Int?)? = store.puzzleGoalEnabled
                ? try await ChessComService.shared.fetchTodayStats(store.username, mode: .puzzles, timeClass: store.gameTimeClass)
                : nil
            async let gameFetch: (solved: Int, failed: Int, rating: Int?)? = store.gameGoalEnabled
                ? try await ChessComService.shared.fetchTodayStats(store.username, mode: .games, timeClass: store.gameTimeClass)
                : nil
            async let puzzleSparkFetch: [Int] = store.puzzleGoalEnabled
                ? await loadSparkline(mode: .puzzles)
                : Array(repeating: 0, count: 7)
            async let gameSparkFetch: [Int] = store.gameGoalEnabled
                ? await loadSparkline(mode: .games)
                : Array(repeating: 0, count: 7)

            if let pResult = try await puzzleFetch {
                puzzleSolved = pResult.solved
                puzzleFailed = pResult.failed
                puzzleRating = pResult.rating
            }
            if let gResult = try await gameFetch {
                gameSolved = gResult.solved
                gameFailed = gResult.failed
                gameRating = gResult.rating
            }
            profile = try? await profileFetch
            puzzleSparkline = await puzzleSparkFetch
            gameSparkline = await gameSparkFetch
            _ = try? await delay

            WidgetCenter.shared.reloadAllTimelines()
            NotificationService.shared.updateCombinedReminder(
                puzzleSolved: puzzleSolved, puzzleTarget: store.dailyPuzzleTarget, puzzleEnabled: store.puzzleGoalEnabled,
                gameSolved: gameSolved, gameTarget: store.dailyGameTarget, gameEnabled: store.gameGoalEnabled,
                reminderEnabled: store.dailyReminderEnabled
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadSparkline(mode: GoalMode) async -> [Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        if mode == .puzzles {
            guard let chart = try? await ChessComService.shared.fetchTacticsChart(store.username, daysAgo: 7) else {
                return Array(repeating: 0, count: 7)
            }
            var result = [Int](repeating: 0, count: 7)
            for entry in chart.dailyStats {
                let dayStart = cal.startOfDay(for: entry.date)
                let daysAgo = cal.dateComponents([.day], from: dayStart, to: today).day ?? 0
                let index = 6 - daysAgo
                if index >= 0, index < 7 {
                    result[index] = entry.totalPassed
                }
            }
            return result
        } else {
            guard let history = try? await ChessComService.shared.fetchGameHistory(store.username, timeClass: store.gameTimeClass, days: 7) else {
                return Array(repeating: 0, count: 7)
            }
            var result = [Int](repeating: 0, count: 7)
            for entry in history {
                let dayStart = cal.startOfDay(for: entry.date)
                let daysAgo = cal.dateComponents([.day], from: dayStart, to: today).day ?? 0
                let index = 6 - daysAgo
                if index >= 0, index < 7 {
                    result[index] = entry.won
                }
            }
            return result
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 0) {
            // Glow
            ZStack {
                Circle()
                    .fill(color.opacity(0.55))
                    .frame(width: 56, height: 36)
                    .blur(radius: 16)
                    .offset(y: -15)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            .frame(height: 20)
            .padding(.bottom, 3)

            Text(value)
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .kerning(1.3)
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 13).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(SFColor.border, lineWidth: 1))
    }
}

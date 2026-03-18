import SwiftUI
import WidgetKit

struct DashboardView: View {
    @EnvironmentObject var store: UserStore
    @State private var solved = 0
    @State private var failed = 0
    @State private var rating: Int?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var remaining: Int { max(0, store.dailyPuzzleTarget - solved) }
    private var total: Int { solved + failed }
    private var accuracy: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(solved) / Double(total) * 100))
    }
    private var progress: Double {
        guard store.dailyPuzzleTarget > 0 else { return 0 }
        return min(1.0, Double(solved) / Double(store.dailyPuzzleTarget))
    }

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

                    // Avatar
                    Circle()
                        .fill(LinearGradient(colors: [SFColor.amber, SFColor.amber2], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 33, height: 33)
                        .overlay(
                            Text(store.username.prefix(2).uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(SFColor.void_)
                        )
                }
                .padding(.bottom, 22)

                // Hero rating card
                heroCard
                    .padding(.bottom, 16)

                // Stat tiles
                HStack(spacing: 7) {
                    StatTile(value: "\(remaining)", label: "LEFT", color: SFColor.amber, icon: "target")
                    StatTile(value: "\(solved)", label: "PASSED", color: SFColor.green, icon: "checkmark.circle")
                    StatTile(value: "\(failed)", label: "FAILED", color: SFColor.red, icon: "xmark.circle")
                }
                .padding(.bottom, 16)

                // Progress bar
                progressCard
                    .padding(.bottom, 16)

                // Streak (placeholder)
                HStack(spacing: 6) {
                    Image(systemName: "flame")
                        .font(.system(size: 11))
                    Text("\(solved > 0 ? "Active today" : "Solve a puzzle!")")
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
        .background(SFColor.s2)
        .refreshable { await loadStats() }
        .task(id: store.username) { await loadStats() }
        .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Label
                HStack(spacing: 5) {
                    Image(systemName: "chess.pawn.fill" /* closest to knight */)
                        .font(.system(size: 9))
                        .foregroundColor(SFColor.amber)
                    Text("PUZZLE RATING")
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

                // Sparkline
                VStack(spacing: 0) {
                    Rectangle().fill(SFColor.border).frame(height: 1)
                    Spacer(minLength: 4)
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(0..<7, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i == 6 ? LinearGradient(colors: [SFColor.amber, SFColor.amber2], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [SFColor.s6, SFColor.s6], startPoint: .top, endPoint: .bottom))
                                .frame(width: 16, height: CGFloat([8, 13, 10, 18, 12, 16, 28][i]))
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
                Text("\(solved) / \(store.dailyPuzzleTarget) puzzles")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
                Spacer()
                Text("\(remaining) left")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 13).fill(SFColor.s3))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(SFColor.border, lineWidth: 1))
    }

    private func loadStats() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetch = ChessComService.shared.fetchTodayPuzzleCount(store.username)
            async let delay: () = Task.sleep(nanoseconds: 150_000_000)
            let result = try await fetch
            _ = try? await delay
            solved = result.solved
            failed = result.failed
            rating = result.rating
            WidgetCenter.shared.reloadAllTimelines()
            NotificationService.shared.updateDailyReminder(
                solved: solved, target: store.dailyPuzzleTarget,
                enabled: store.dailyReminderEnabled
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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

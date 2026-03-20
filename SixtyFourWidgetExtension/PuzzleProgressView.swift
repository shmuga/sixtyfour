import SwiftUI
import WidgetKit

// MARK: - Activity Ring

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.6), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Widget View

struct PuzzleWidgetView: View {
    let entry: PuzzleEntry

    @Environment(\.widgetFamily) var family

    private var deepLink: URL? {
        guard entry.remaining > 0 else { return nil }
        return URL(string: "sixtyfour://open-chesscom/play")!
    }

    private var modeIcon: String {
        entry.goalMode == .games ? "flag.pattern.checkered" : "puzzlepiece.fill"
    }

    private var modeLabel: String {
        entry.goalMode == .games ? "GAMES" : "PUZZLES"
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            default:
                smallWidget
            }
        }
        .widgetURL(deepLink ?? URL(string: "sixtyfour://home")!)
    }

    // MARK: - Knight Silhouette

    private var knightImage: some View {
        Image("knight")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        let progressVal = entry.target > 0 ? Double(entry.solved) / Double(entry.target) : 0
        let goalReached = entry.remaining <= 0
        let accentColor = goalReached ? Color(hex: 0x2ECC71) : Color(hex: 0xF5A623)

        return ZStack {
            // Knight silhouette — centered
            knightImage
                .foregroundColor(Color.white.opacity(0.08))
                .frame(height: 130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            VStack(spacing: 8) {
                // Mode badge
                HStack(spacing: 3) {
                    Image(systemName: modeIcon)
                        .font(.system(size: 7))
                    Text(modeLabel)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .kerning(1)
                }
                .foregroundColor(Color(hex: 0xF5A623))
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                // Ring + center text
                ZStack {
                    ActivityRing(
                        progress: progressVal,
                        color: accentColor,
                        lineWidth: 7,
                        size: 78
                    )

                    if goalReached {
                        Image(systemName: "checkmark")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(hex: 0x2ECC71))
                    } else {
                        VStack(spacing: -2) {
                            Text("\(entry.remaining)")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundColor(accentColor)
                            Text("LEFT")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(accentColor.opacity(0.7))
                                .kerning(1.5)
                        }
                    }
                }

                // Footer centered under ring
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text("\(entry.solved)/\(entry.target)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(goalReached ? Color(hex: 0x2ECC71).opacity(0.6) : Color(hex: 0x555049))
                    if let rating = entry.rating {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("▲")
                                .font(.system(size: 7))
                            Text("\(rating)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(Color(hex: 0x2ECC71))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .clipped()
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        let total = entry.solved + entry.failed
        let accProgress = total > 0 ? Double(entry.solved) / Double(total) : 0
        let targetProgress = entry.target > 0 ? Double(entry.solved) / Double(entry.target) : 0

        return ZStack {
            // Knight silhouette — right side, full height
            knightImage
                .foregroundColor(Color.white.opacity(0.07))
                .frame(height: 150)
                .offset(x: 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

        HStack(spacing: 0) {
            // Concentric rings
            ZStack {
                ActivityRing(progress: targetProgress, color: Color(hex: 0xF5A623), lineWidth: 8, size: 120)
                ActivityRing(progress: accProgress, color: Color(hex: 0x2ECC71), lineWidth: 7, size: 98)
                ActivityRing(progress: min(1.0, Double(entry.failed) / max(1, Double(entry.target)) * 3), color: Color(hex: 0xE74C3C), lineWidth: 6, size: 78)

                VStack(spacing: 1) {
                    Text("\(entry.rating ?? 0)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: 0xECE8DF))
                    Text("RATING")
                        .font(.system(size: 6, design: .monospaced))
                        .foregroundColor(Color(hex: 0x555049))
                        .kerning(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 40)

            // Right side — vertical stat stack
            VStack(alignment: .leading, spacing: 1) {
                // Mode badge
                HStack(spacing: 4) {
                    Image(systemName: modeIcon)
                        .font(.system(size: 8))
                    Text(modeLabel)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .kerning(1.5)
                }
                .foregroundColor(Color(hex: 0xF5A623).opacity(0.75))
                .lineLimit(1)

                Spacer(minLength: 0)

                // Stats stacked vertically
                WidgetStatRow(color: Color(hex: 0xF5A623), value: "\(entry.remaining)", label: "LEFT")
                WidgetStatRow(color: Color(hex: 0x2ECC71), value: "\(entry.solved)", label: entry.solvedLabel)
                WidgetStatRow(color: Color(hex: 0xE74C3C), value: "\(entry.failed)", label: entry.failedLabel)

                Spacer(minLength: 0)

                // Delta
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8, weight: .bold))
                    Text("+\(entry.solved) today")
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(Color(hex: 0x2ECC71))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        }
        .clipped()
    }
}

// MARK: - Rating Widget View

struct RatingWidgetView: View {
    let entry: WidgetRatingEntry

    @Environment(\.widgetFamily) var family

    private var knightImage: some View {
        Image("knight")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallRating
            case .systemMedium:
                mediumRating
            default:
                smallRating
            }
        }
        .widgetURL(URL(string: "sixtyfour://home")!)
    }

    // MARK: - Small Rating

    private var smallRating: some View {
        ZStack {
            knightImage
                .foregroundColor(Color.white.opacity(0.08))
                .frame(height: 130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            VStack(spacing: 4) {
                Text(entry.timeClass.displayName)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: 0xF5A623))
                    .kerning(2)

                Spacer(minLength: 0)

                Text("\(entry.rating)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(hex: 0xECE8DF))
                    .minimumScaleFactor(0.6)

                Text("RATING")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: 0x555049))
                    .kerning(1.5)

                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .clipped()
    }

    // MARK: - Medium Rating

    private var mediumRating: some View {
        ZStack {
            knightImage
                .foregroundColor(Color.white.opacity(0.07))
                .frame(height: 150)
                .offset(x: 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            HStack(spacing: 0) {
                // Left — big rating + time class
                VStack(spacing: 2) {
                    Spacer(minLength: 0)
                    Text("\(entry.rating)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(hex: 0xECE8DF))
                        .minimumScaleFactor(0.6)
                    Text(entry.timeClass.displayName)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: 0xF5A623))
                        .kerning(2)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)

                // Right — stat column
                VStack(alignment: .leading, spacing: 1) {
                    Text("SIXTYFOUR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0xF5A623).opacity(0.75))
                        .kerning(1.5)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    WidgetStatRow(color: Color(hex: 0xF5A623), value: "\(entry.bestRating)", label: "BEST")
                    WidgetStatRow(color: Color(hex: 0x2ECC71), value: "\(entry.wins)", label: "WON")
                    WidgetStatRow(color: Color(hex: 0xE74C3C), value: "\(entry.losses)", label: "LOST")
                    WidgetStatRow(color: Color(hex: 0x555049), value: "\(entry.draws)", label: "DRAW")

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
        }
        .clipped()
    }
}

// MARK: - Combined Goal Widget View

struct CombinedGoalWidgetView: View {
    let entry: CombinedGoalEntry

    private let gameColor = Color(hex: 0xF5A623)  // amber for games
    private let puzzleColor = Color(hex: 0x2ECC71) // green for puzzles
    private let ivory = Color(hex: 0xECE8DF)
    private let muted = Color(hex: 0x555049)

    private var knightImage: some View {
        Image("knight")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    var body: some View {
        ZStack {
            knightImage
                .foregroundColor(Color.white.opacity(0.05))
                .frame(height: 140)
                .offset(x: 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            HStack(spacing: 0) {
                // Concentric rings
                ZStack {
                    // Outer ring — games
                    ActivityRing(
                        progress: entry.gameProgress,
                        color: gameColor,
                        lineWidth: 9,
                        size: 120
                    )
                    // Inner ring — puzzles
                    ActivityRing(
                        progress: entry.puzzleProgress,
                        color: puzzleColor,
                        lineWidth: 8,
                        size: 96
                    )

                    // Center — total remaining
                    let totalRemaining = entry.gameRemaining + entry.puzzleRemaining
                    if totalRemaining == 0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(puzzleColor)
                    } else {
                        VStack(spacing: 0) {
                            Text("\(totalRemaining)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ivory)
                            Text("LEFT")
                                .font(.system(size: 6, weight: .medium, design: .monospaced))
                                .foregroundColor(muted)
                                .kerning(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.trailing, 30)

                // Right side — stats
                VStack(alignment: .leading, spacing: 2) {
                    Text("SIXTYFOUR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(gameColor.opacity(0.75))
                        .kerning(1.5)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    // Games stats
                    HStack(spacing: 4) {
                        Circle().fill(gameColor).frame(width: 6, height: 6)
                        Text("GAMES")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(muted)
                            .kerning(0.5)
                    }
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(entry.gameSolved)/\(entry.gameTarget)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(gameColor)
                        Text("\(entry.gameRemaining) left")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(muted)
                    }

                    Spacer(minLength: 2)

                    // Puzzles stats
                    HStack(spacing: 4) {
                        Circle().fill(puzzleColor).frame(width: 6, height: 6)
                        Text("PUZZLES")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(muted)
                            .kerning(0.5)
                    }
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(entry.puzzleSolved)/\(entry.puzzleTarget)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(puzzleColor)
                        Text("\(entry.puzzleRemaining) left")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(muted)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
        }
        .clipped()
        .widgetURL(URL(string: "sixtyfour://home")!)
    }
}

struct WidgetStatRow: View {
    let color: Color
    let value: String
    let label: String

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(hex: 0x6B665D))
                .kerning(0.5)
        }
    }
}

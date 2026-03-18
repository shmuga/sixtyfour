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

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
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

        return ZStack {
            // Knight silhouette — left side, partially cropped
            knightImage
                .foregroundColor(Color.white.opacity(0.08))
                .frame(height: 130)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            VStack(spacing: 8) {
                Spacer(minLength: 0)

                // Ring + center text
                ZStack {
                    ActivityRing(
                        progress: progressVal,
                        color: Color(hex: 0xF5A623),
                        lineWidth: 7,
                        size: 78
                    )

                    VStack(spacing: -2) {
                        Text("\(entry.remaining)")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(Color(hex: 0xF5A623))
                        Text("LEFT")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: 0xF5A623).opacity(0.7))
                            .kerning(1.5)
                    }
                }

                // Footer centered under ring
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text("\(entry.solved)/\(entry.target)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: 0x555049))
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
                // Header
                Text("SIXTYFOUR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0xF5A623).opacity(0.75))
                    .kerning(1.5)
                    .lineLimit(1)

                Spacer(minLength: 0)

                // Stats stacked vertically
                WidgetStatRow(color: Color(hex: 0xF5A623), value: "\(entry.remaining)", label: "LEFT")
                WidgetStatRow(color: Color(hex: 0x2ECC71), value: "\(entry.solved)", label: "PASSED")
                WidgetStatRow(color: Color(hex: 0xE74C3C), value: "\(entry.failed)", label: "FAILED")

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

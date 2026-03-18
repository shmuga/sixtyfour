import SwiftUI

struct ChessboardIcon: View {
    let size: CGFloat

    var body: some View {
        let cellSize = size / 4.8
        let gap = size / 15
        let cells = 4

        Canvas { context, _ in
            for row in 0..<cells {
                for col in 0..<cells {
                    let isAmber = (row + col) % 2 == 0
                    let x = CGFloat(col) * (cellSize + gap)
                    let y = CGFloat(row) * (cellSize + gap)
                    let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                    let path = Path(roundedRect: rect, cornerRadius: cellSize * 0.15)
                    context.fill(path, with: .color(isAmber ? SFColor.amber : SFColor.s5))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

enum OnboardingStep {
    case username
    case goalType
    case goal
    case reminders
}

struct OnboardingView: View {
    @EnvironmentObject var store: UserStore
    @State private var username = ""
    @State private var goalMode: GoalMode = .puzzles
    @State private var gameTimeClass: TimeClass = .blitz
    @State private var dailyTarget = 10
    @State private var targetText = "10"
    @State private var remindersEnabled = true
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var step: OnboardingStep = .username

    private var presets: [Int] {
        goalMode == .puzzles ? [5, 10, 20, 50] : [1, 3, 5, 10]
    }

    var body: some View {
        ZStack {
            SFColor.s1.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ChessboardIcon(size: 28)
                    .padding(.bottom, 16)

                // Title
                HStack(spacing: 0) {
                    Text("SIXTY")
                        .foregroundColor(SFColor.ivory)
                    Text("FOUR")
                        .foregroundColor(SFColor.amber)
                }
                .font(.system(size: 28, weight: .bold))
                .kerning(4)

                Text("CHESS.COM  PUZZLE  TRACKER")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
                    .kerning(1.5)
                    .padding(.top, 2)
                    .padding(.bottom, 28)

                switch step {
                case .username:
                    usernameContent
                case .goalType:
                    goalTypeContent
                case .goal:
                    goalContent
                case .reminders:
                    remindersContent
                }

                Spacer()

                // Bottom button area
                VStack(spacing: 0) {
                    switch step {
                    case .username:
                        usernameBottom
                    case .goalType:
                        goalTypeBottom
                    case .goal:
                        goalBottom
                    case .reminders:
                        remindersBottom
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    // MARK: - Step 1: Username

    private var usernameContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "person")
                    .font(.system(size: 13))
                    .foregroundColor(SFColor.ivory3)

                TextField("", text: $username, prompt: Text("chess.com username").foregroundColor(SFColor.ivory3))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(SFColor.ivory)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(isValidating)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(SFColor.s4)
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(SFColor.border))
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(SFColor.red)
                    .padding(.top, 6)
            }
        }
    }

    private var usernameBottom: some View {
        VStack(spacing: 0) {
            onboardingButton(label: "CONNECT", isLoading: isValidating, disabled: username.trimmingCharacters(in: .whitespaces).isEmpty || isValidating) {
                Task { await validate() }
            }

            HStack(spacing: 4) {
                Image(systemName: "lock.open")
                    .font(.system(size: 8))
                Text("No password required")
                    .font(.system(size: 8, design: .monospaced))
            }
            .foregroundColor(SFColor.ivory3)
            .padding(.top, 10)
        }
        .frame(height: 80)
    }

    // MARK: - Step 2: Goal Type

    private var goalTypeContent: some View {
        VStack(spacing: 0) {
            Text("WHAT DO YOU WANT TO TRACK?")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(SFColor.amber)
                .kerning(2)
                .padding(.bottom, 6)

            Text("Choose your daily goal type")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .padding(.bottom, 20)

            HStack(spacing: 12) {
                goalTypeCard(
                    mode: .puzzles,
                    icon: "puzzlepiece.fill",
                    title: "PUZZLES",
                    subtitle: "Solve daily puzzles"
                )
                goalTypeCard(
                    mode: .games,
                    icon: "flag.pattern.checkered",
                    title: "GAMES",
                    subtitle: "Play rated games"
                )
            }
            .padding(.horizontal, 32)
        }
    }

    private func goalTypeCard(mode: GoalMode, icon: String, title: String, subtitle: String) -> some View {
        Button {
            goalMode = mode
            // Set sensible defaults when switching
            if mode == .puzzles {
                dailyTarget = 10
                targetText = "10"
            } else {
                dailyTarget = 3
                targetText = "3"
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(goalMode == mode ? SFColor.amber : SFColor.ivory3)
                    .frame(width: 32, height: 32)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(goalMode == mode ? SFColor.ivory : SFColor.ivory3)
                    .kerning(1.5)

                Text(subtitle)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(goalMode == mode ? SFColor.s4 : SFColor.s3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(goalMode == mode ? SFColor.amber : SFColor.border, lineWidth: goalMode == mode ? 1.5 : 1)
            )
        }
    }

    private var goalTypeBottom: some View {
        VStack(spacing: 0) {
            onboardingButton(label: "CONTINUE", isLoading: false, disabled: false) {
                step = .goal
            }

            Text("You can change this later in settings")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .padding(.top, 10)
        }
        .frame(height: 80)
    }

    // MARK: - Step 3: Daily Goal

    private var goalContent: some View {
        VStack(spacing: 0) {
            Text(goalMode == .puzzles ? "DAILY PUZZLE GOAL" : "DAILY GAMES GOAL")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(SFColor.amber)
                .kerning(2)
                .padding(.bottom, 6)

            Text(goalMode == .puzzles ? "How many puzzles per day?" : "How many games per day?")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .padding(.bottom, 16)

            // Time class picker (games only)
            if goalMode == .games {
                HStack(spacing: 8) {
                    ForEach(TimeClass.allCases, id: \.self) { tc in
                        Button {
                            gameTimeClass = tc
                        } label: {
                            Text(tc.displayName)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(gameTimeClass == tc ? SFColor.void_ : SFColor.ivory3)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(gameTimeClass == tc ? SFColor.amber : SFColor.s4)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(gameTimeClass == tc ? Color.clear : SFColor.border, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.bottom, 16)
            }

            HStack(spacing: 14) {
                StepperButton(symbol: "minus") {
                    if dailyTarget > 1 {
                        dailyTarget -= 1
                        targetText = "\(dailyTarget)"
                    }
                }

                TextField("", text: $targetText)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.amber)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 70)
                    .onChange(of: targetText) { _, newVal in
                        if let num = Int(newVal), num >= 1, num <= 999 {
                            dailyTarget = num
                        }
                    }

                StepperButton(symbol: "plus") {
                    if dailyTarget < 999 {
                        dailyTarget += 1
                        targetText = "\(dailyTarget)"
                    }
                }
            }
            .padding(.bottom, 8)

            // Presets
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { val in
                    Button {
                        dailyTarget = val
                        targetText = "\(val)"
                    } label: {
                        Text("\(val)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(dailyTarget == val ? SFColor.void_ : SFColor.ivory3)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(dailyTarget == val ? SFColor.amber : SFColor.s4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(dailyTarget == val ? Color.clear : SFColor.border, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var goalBottom: some View {
        VStack(spacing: 0) {
            onboardingButton(label: "CONTINUE", isLoading: false, disabled: false) {
                step = .reminders
            }

            Text("You can change this later in settings")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .padding(.top, 10)
        }
        .frame(height: 80)
    }

    // MARK: - Step 4: Reminders

    private var remindersContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "bell.badge")
                .font(.system(size: 28))
                .foregroundColor(SFColor.amber)
                .padding(.bottom, 14)

            Text("DAILY REMINDERS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(SFColor.amber)
                .kerning(2)
                .padding(.bottom, 6)

            Text("Get notified at 7 PM if you\nhaven't reached your goal")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            // Toggle
            HStack {
                Text("Daily reminder")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SFColor.ivory)
                Spacer()
                Toggle("", isOn: $remindersEnabled)
                    .labelsHidden()
                    .tint(SFColor.amber)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(SFColor.s3))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SFColor.border, lineWidth: 1))
            .padding(.horizontal, 32)
        }
    }

    private var remindersBottom: some View {
        VStack(spacing: 0) {
            onboardingButton(label: "GET STARTED", isLoading: false, disabled: false) {
                finishOnboarding()
            }

            Button {
                remindersEnabled = false
                finishOnboarding()
            } label: {
                Text("Skip")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
            }
            .padding(.top, 10)
        }
        .frame(height: 80)
    }

    // MARK: - Shared Button

    private func onboardingButton(label: String, isLoading: Bool, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(SFColor.void_)
                } else {
                    Text(label)
                        .font(.system(size: 14, weight: .bold))
                        .kerning(2.5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .background(SFColor.amber)
        .foregroundColor(SFColor.void_)
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .shadow(color: SFColor.amber.opacity(0.25), radius: 8, y: 3)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .padding(.horizontal, 32)
        .padding(.top, 10)
    }

    // MARK: - Actions

    private func validate() async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        isValidating = true
        errorMessage = nil

        do {
            let valid = try await ChessComService.shared.validateUsername(trimmed)
            if valid {
                step = .goalType
            } else {
                errorMessage = "Username not found on chess.com"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isValidating = false
    }

    private func finishOnboarding() {
        store.goalMode = goalMode
        store.gameTimeClass = gameTimeClass
        if goalMode == .puzzles {
            store.dailyPuzzleTarget = dailyTarget
        } else {
            store.dailyGameTarget = dailyTarget
        }
        store.dailyReminderEnabled = remindersEnabled
        store.username = username.trimmingCharacters(in: .whitespaces)
        if remindersEnabled {
            Task { await NotificationService.shared.requestPermission() }
        }
    }
}

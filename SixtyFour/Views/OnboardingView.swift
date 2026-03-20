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
    case gameGoal
    case gameTimeClass
    case puzzleGoal
    case reminders
}

enum GoalSelection {
    case puzzles, games, both

    var puzzleEnabled: Bool { self == .puzzles || self == .both }
    var gameEnabled: Bool { self == .games || self == .both }
}

struct OnboardingView: View {
    @EnvironmentObject var store: UserStore

    @State private var username = ""
    @State private var goalSelection: GoalSelection = .games
    @State private var gameTimeClass: TimeClass = .blitz
    @State private var dailyGameTarget = 3
    @State private var dailyPuzzleTarget = 10
    @State private var remindersEnabled = true
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var step: OnboardingStep = .username

    /// The next step after goal type selection
    private var stepAfterGoalType: OnboardingStep {
        goalSelection.gameEnabled ? .gameGoal : .puzzleGoal
    }

    /// The next step after game time class
    private var stepAfterGameTimeClass: OnboardingStep {
        goalSelection.puzzleEnabled ? .puzzleGoal : .reminders
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
                case .username:      usernameContent
                case .goalType:      goalTypeContent
                case .gameGoal:      gameGoalContent
                case .gameTimeClass: gameTimeClassContent
                case .puzzleGoal:    puzzleGoalContent
                case .reminders:     remindersContent
                }

                Spacer()

                VStack(spacing: 0) {
                    switch step {
                    case .username:      usernameBottom
                    case .goalType:      goalTypeBottom
                    case .gameGoal:      gameGoalBottom
                    case .gameTimeClass: gameTimeClassBottom
                    case .puzzleGoal:    puzzleGoalBottom
                    case .reminders:     remindersBottom
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

            bottomSubtitle("No password required")
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

            HStack(spacing: 10) {
                goalTypeCard(selection: .games, icon: "flag.pattern.checkered", title: "GAMES")
                goalTypeCard(selection: .puzzles, icon: "puzzlepiece.fill", title: "PUZZLES")
                goalTypeCard(selection: .both, icon: "star.fill", title: "BOTH")
            }
            .padding(.horizontal, 28)
        }
    }

    private func goalTypeCard(selection: GoalSelection, icon: String, title: String) -> some View {
        let selected = goalSelection == selection
        return Button {
            goalSelection = selection
        } label: {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(selected ? SFColor.amber : SFColor.ivory3)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(selected ? SFColor.ivory : SFColor.ivory3)
                    .kerning(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? SFColor.s4 : SFColor.s3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? SFColor.amber : SFColor.border, lineWidth: selected ? 1.5 : 1)
            )
        }
    }

    private var goalTypeBottom: some View {
        bottomArea(label: "CONTINUE") {
            step = stepAfterGoalType
        }
    }

    // MARK: - Step 3: Game Goal

    private var gameGoalContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "flag.pattern.checkered")
                .font(.system(size: 28))
                .foregroundColor(SFColor.amber)
                .padding(.bottom, 14)

            Text("DAILY GAME GOAL")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(SFColor.amber)
                .kerning(2)
                .padding(.bottom, 6)

            Text("How many games per day?")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .padding(.bottom, 20)

            HStack(spacing: 14) {
                StepperButton(symbol: "minus") {
                    if dailyGameTarget > 1 { dailyGameTarget -= 1 }
                }

                Text("\(dailyGameTarget)")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.amber)
                    .frame(width: 70)
                    .multilineTextAlignment(.center)

                StepperButton(symbol: "plus") {
                    if dailyGameTarget < 999 { dailyGameTarget += 1 }
                }
            }
            .padding(.bottom, 8)

            HStack(spacing: 8) {
                ForEach([1, 3, 5, 10], id: \.self) { val in
                    presetButton(val, selected: dailyGameTarget == val) {
                        dailyGameTarget = val
                    }
                }
            }
        }
    }

    private var gameGoalBottom: some View {
        bottomArea(label: "CONTINUE") {
            step = .gameTimeClass
        }
    }

    // MARK: - Step 4: Game Time Class

    private var gameTimeClassContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "clock")
                .font(.system(size: 28))
                .foregroundColor(SFColor.amber)
                .padding(.bottom, 14)

            Text("TIME CLASS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(SFColor.amber)
                .kerning(2)
                .padding(.bottom, 6)

            Text("Which time control do you play?")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .padding(.bottom, 24)

            VStack(spacing: 8) {
                ForEach(TimeClass.allCases, id: \.self) { tc in
                    timeClassRow(tc)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private func timeClassRow(_ tc: TimeClass) -> some View {
        let selected = gameTimeClass == tc
        return Button {
            gameTimeClass = tc
        } label: {
            HStack {
                Text(tc.displayName)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(selected ? SFColor.ivory : SFColor.ivory3)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(SFColor.amber)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? SFColor.s4 : SFColor.s3))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? SFColor.amber : SFColor.border, lineWidth: selected ? 1.5 : 1)
            )
        }
    }

    private var gameTimeClassBottom: some View {
        bottomArea(label: "CONTINUE") {
            step = stepAfterGameTimeClass
        }
    }

    // MARK: - Step 5: Puzzle Goal

    private var puzzleGoalContent: some View {
        VStack(spacing: 0) {
            Image(systemName: "puzzlepiece.fill")
                .font(.system(size: 28))
                .foregroundColor(SFColor.amber)
                .padding(.bottom, 14)

            Text("DAILY PUZZLE GOAL")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(SFColor.amber)
                .kerning(2)
                .padding(.bottom, 6)

            Text("How many puzzles per day?")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SFColor.ivory3)
                .padding(.bottom, 20)

            HStack(spacing: 14) {
                StepperButton(symbol: "minus") {
                    if dailyPuzzleTarget > 1 { dailyPuzzleTarget -= 1 }
                }

                Text("\(dailyPuzzleTarget)")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(SFColor.amber)
                    .frame(width: 70)
                    .multilineTextAlignment(.center)

                StepperButton(symbol: "plus") {
                    if dailyPuzzleTarget < 999 { dailyPuzzleTarget += 1 }
                }
            }
            .padding(.bottom, 8)

            HStack(spacing: 8) {
                ForEach([5, 10, 20, 50], id: \.self) { val in
                    presetButton(val, selected: dailyPuzzleTarget == val) {
                        dailyPuzzleTarget = val
                    }
                }
            }
        }
    }

    private var puzzleGoalBottom: some View {
        bottomArea(label: "CONTINUE") {
            step = .reminders
        }
    }

    // MARK: - Step 6: Reminders

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
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(SFColor.ivory3)
            }
            .padding(.top, 10)
        }
        .frame(height: 80)
    }

    // MARK: - Helpers

    private func bottomArea(label: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            onboardingButton(label: label, isLoading: false, disabled: false, action: action)
            bottomSubtitle("You can change this later in settings")
        }
        .frame(height: 80)
    }

    private func bottomSubtitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, design: .monospaced))
            .foregroundColor(SFColor.ivory3)
            .padding(.top, 10)
    }

    private func presetButton(_ val: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(val)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(selected ? SFColor.void_ : SFColor.ivory3)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? SFColor.amber : SFColor.s4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? Color.clear : SFColor.border, lineWidth: 1)
                )
        }
    }

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
        store.gameGoalEnabled = goalSelection.gameEnabled
        store.puzzleGoalEnabled = goalSelection.puzzleEnabled
        store.gameTimeClass = gameTimeClass
        store.dailyGameTarget = dailyGameTarget
        store.dailyPuzzleTarget = dailyPuzzleTarget
        store.dailyReminderEnabled = remindersEnabled
        if goalSelection.gameEnabled {
            store.goalMode = .games
        } else {
            store.goalMode = .puzzles
        }
        store.username = username.trimmingCharacters(in: .whitespaces)
        if remindersEnabled {
            Task { await NotificationService.shared.requestPermission() }
        }
    }
}

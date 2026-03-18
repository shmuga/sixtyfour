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

struct OnboardingView: View {
    @EnvironmentObject var store: UserStore
    @State private var username = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

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

                // Input field
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

                // CTA Button
                Button {
                    Task { await validate() }
                } label: {
                    Group {
                        if isValidating {
                            ProgressView()
                                .tint(SFColor.void_)
                        } else {
                            Text("CONNECT")
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
                .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                .opacity(username.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .padding(.horizontal, 32)
                .padding(.top, 10)

                // Note
                HStack(spacing: 4) {
                    Image(systemName: "lock.open")
                        .font(.system(size: 8))
                    Text("No password required")
                        .font(.system(size: 8, design: .monospaced))
                }
                .foregroundColor(SFColor.ivory3)
                .padding(.top, 10)

                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func validate() async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        isValidating = true
        errorMessage = nil

        do {
            let valid = try await ChessComService.shared.validateUsername(trimmed)
            if valid {
                store.username = trimmed
            } else {
                errorMessage = "Username not found on chess.com"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isValidating = false
    }
}

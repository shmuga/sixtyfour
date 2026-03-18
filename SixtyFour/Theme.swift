import SwiftUI

enum SFColor {
    static let void_ = Color(hex: 0x060607)
    static let s1 = Color(hex: 0x0D0D0F)
    static let s2 = Color(hex: 0x131316)
    static let s3 = Color(hex: 0x1A1A1F)
    static let s4 = Color(hex: 0x222228)
    static let s5 = Color(hex: 0x2B2B33)
    static let s6 = Color(hex: 0x35353F)
    static let ivory = Color(hex: 0xECE8DF)
    static let ivory2 = Color(hex: 0x9E9A91)
    static let ivory3 = Color(hex: 0x555049)
    static let amber = Color(hex: 0xF5A623)
    static let amber2 = Color(hex: 0xC97D10)
    static let green = Color(hex: 0x2ECC71)
    static let red = Color(hex: 0xE74C3C)
    static let blue = Color(hex: 0x5B9CF6)
    static let border = Color.white.opacity(0.06)
    static let borderAmber = Color(hex: 0xF5A623).opacity(0.28)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

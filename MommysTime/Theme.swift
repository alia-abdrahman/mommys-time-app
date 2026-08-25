import SwiftUI
import CoreText

/// Registers and exposes the design's exact typefaces — Baloo 2 for chunky
/// headings, Nunito for body — bundled from the Avocation design file.
enum AppFont {
    static func register() {
        for name in ["Baloo2-Bold", "Baloo2-ExtraBold",
                     "Nunito-Regular", "Nunito-SemiBold", "Nunito-Bold", "Nunito-ExtraBold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    /// Baloo 2 — headings / titles.
    static func baloo(_ size: CGFloat, heavy: Bool = false) -> Font {
        .custom(heavy ? "Baloo2-ExtraBold" : "Baloo2-Bold", size: size)
    }

    /// Nunito — body text.
    static func nunito(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .heavy, .black: name = "Nunito-ExtraBold"
        case .bold: name = "Nunito-Bold"
        case .semibold, .medium: name = "Nunito-SemiBold"
        default: name = "Nunito-Regular"
        }
        return .custom(name, size: size)
    }
}

/// "Avocation" warm skin — cream canvas, dusty-rose accent, muted per-feature
/// hues and soft pillow cards.
enum Theme {
    // Canvas & surfaces
    static let canvas = Color(hex: 0xF9F3EB)
    static let peach = Color(hex: 0xFBEBD8)

    // Unified menu/premium tile glyph colour
    static let tileGlyph = Color(hex: 0xC4788C)

    // Ink
    static let ink = Color(hex: 0x4A423B)
    static let inkSoft = Color(hex: 0x6E6358)
    static let inkMuted = Color(hex: 0xA99B8C)

    // Primary accent (dusty rose)
    static let rose = Color(hex: 0xD98FA0)
    static let roseDeep = Color(hex: 0xC46A82)
    static let rosePillBg = Color(hex: 0xF6E6E9)
    static let roseText = Color(hex: 0xC97B8C)

    // Tip-of-the-day
    static let tipLabel = Color(hex: 0xC08A64)
    static let tipIconBg = Color(hex: 0xF6DCC4)
    static let tipIconDot = Color(hex: 0xD9A26A)

    // Reminder pill
    static let reminderBg = Color(hex: 0xFBEBD8)
    static let reminderText = Color(hex: 0x8A6A44)
    static let reminderStrong = Color(hex: 0x5E4630)
    static let reminderIconBg = Color(hex: 0xF3D0A7)

    // Feature hues: (icon, soft background)
    static let amber = Color(hex: 0xC08A64)
    static let amberBg = Color(hex: 0xF8DFC2)
    static let lilac = Color(hex: 0x7C77B5)
    static let lilacBg = Color(hex: 0xE7E5F4)
    static let sage = Color(hex: 0x4E9E86)
    static let sageBg = Color(hex: 0xDFEDE5)
    static let dustyBlue = Color(hex: 0x6D91AB)
    static let dustyBlueBg = Color(hex: 0xE9F1F6)
    static let teal = Color(hex: 0x3E9E9E)
    static let tealBg = Color(hex: 0xDDEFED)
    static let periwinkle = Color(hex: 0x8A86C7)
    static let periwinkleBg = Color(hex: 0xE9E8F6)

    // Tab bar center button
    static let green = Color(hex: 0x7FBFAE)

    // Custom bottom nav bar
    static let navBar = Color(hex: 0xF5DCD9)          // soft blush bar
    static let navIcon = Color(hex: 0xB68A85)         // resting icon
    static let navIconOn = Color(hex: 0xC46A82)       // selected icon
    static let navCenter = Color(hex: 0xC8808F)       // elevated heart circle

    static let cardShadow = Color(hex: 0x7A6248).opacity(0.12)
}

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

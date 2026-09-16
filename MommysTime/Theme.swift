import SwiftUI
import CoreText

/// Registers and exposes the design's exact typefaces — Baloo 2 for chunky
/// headings, Nunito for body — bundled from the Avocation design file.
enum AppFont {
    /// Once per process — a language switch rebuilds `ContentView`, and
    /// re-registering the same URLs only earns a console full of complaints.
    private static var registered = false

    static func register() {
        guard !registered else { return }
        registered = true
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
    static let canvas = Color(hex: 0xFFF8EE)
    static let peach = Color(hex: 0xFBEBD8)
    static let peachBorder = Color(hex: 0xEFCFA4)
    /// Hairline border drawn around most white cards.
    static let cardBorder = Color(hex: 0xF1DFC6)
    /// Fill behind steppers and segmented controls.
    static let field = Color(hex: 0xF4EDE4)
    static let divider = Color(hex: 0x7A6248).opacity(0.1)

    // Unified menu/premium tile glyph colour
    static let tileGlyph = Color(hex: 0xC4788C)

    // Ink
    static let ink = Color(hex: 0x4A423B)
    static let inkSoft = Color(hex: 0x6E6358)
    static let inkBody = Color(hex: 0x8A7E72)
    static let inkMuted = Color(hex: 0xA99B8C)
    static let inkFaint = Color(hex: 0x9A8D80)
    static let inkWhisper = Color(hex: 0xB3A697)
    static let chevron = Color(hex: 0xC6B9AA)

    // Primary accent (dusty rose), light → dark
    static let rose = Color(hex: 0xD98FA0)
    static let roseStrong = Color(hex: 0xD9758C)      // primary CTA fill
    static let roseDeep = Color(hex: 0xC46A82)
    static let rosePillBg = Color(hex: 0xF6E6E9)
    static let roseTint = Color(hex: 0xF9EDEF)        // softer wash
    static let roseBadgeBg = Color(hex: 0xFBE4E8)
    static let roseBadgeBorder = Color(hex: 0xE7A9B8)
    static let roseText = Color(hex: 0xC97B8C)
    static let roseLabel = Color(hex: 0xB3697E)
    static let roseMuted = Color(hex: 0xB0899A)
    static let roseInk = Color(hex: 0x7E3B50)         // headline on rose panels
    static let roseAccentText = Color(hex: 0xA85F6F)

    // Wake Window — plum reads as "asleep" against the rose everything else uses
    static let plum = Color(hex: 0x7E5A78)
    static let plumDeep = Color(hex: 0x6B4A66)
    static let plumSoft = Color(hex: 0xC9A3C1)
    static let plumText = Color(hex: 0xA85F73)
    /// Border on the awake (blush) hero panel.
    static let heroBorder = Color(hex: 0xEDC3CD)
    /// Softer blush hairline — the soothe card on Home.
    static let roseSoftBorder = Color(hex: 0xF2CFD8)
    /// Dot marking an awake stretch in the sleep log.
    static let awakeDot = Color(hex: 0xE0A45F)

    // Tip-of-the-day
    static let tipLabel = Color(hex: 0xC08A64)
    static let tipIconBg = Color(hex: 0xF6DCC4)
    static let tipIconDot = Color(hex: 0xD9A26A)

    // Reminder pill
    static let reminderBg = Color(hex: 0xFBEBD8)
    static let reminderText = Color(hex: 0x8A6A44)
    static let reminderStrong = Color(hex: 0x5E4630)
    static let reminderIconBg = Color(hex: 0xF3D0A7)
    static let reminderStroke = Color(hex: 0xB07F4E)

    // Toggles
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = rose
    /// Disabled fill for Save / Send buttons.
    static let disabledFill = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)

    // Floating glass tab bar
    static let tabBarGlass = Color(hex: 0xFFFAF4).opacity(0.72)
    static let tabBarStroke = Color.white.opacity(0.75)
    static let tabPillOn = rose.opacity(0.20)
    static let tabIconOn = Color(hex: 0x8E4257)
    static let tabIconOff = Color(hex: 0x824F60)

    // Charts
    static let chartGrid = Color(hex: 0xF1E7DA)
    static let chartEmptyBar = Color(hex: 0xF1E7DA)
    static let chartPastBar = Color(hex: 0xEDC3CD)
    static let chartArea = Color(hex: 0xFAEAEE)
    /// Dot marking a day that has entries in a calendar grid.
    static let calendarBusy = Color(hex: 0xE0A45F)

    static let cardShadow = Color(hex: 0x7A6248).opacity(0.12)
    static let softShadow = Color(hex: 0x7A6248).opacity(0.09)
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

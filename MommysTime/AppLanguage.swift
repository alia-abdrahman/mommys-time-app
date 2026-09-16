import SwiftUI

// MARK: - The languages we ship
//
// Adding a language is three steps: translate `Localizable.xcstrings`, add the
// code to `knownRegions` in the project file (without it Xcode never builds the
// `.lproj`), and add a case below. Nothing else has to change — every string in
// `L` already resolves through `Bundle.appLanguage`.

/// The raw value is the `.lproj` code *and* what gets persisted, so it must
/// stay stable.
enum AppLanguage: String, CaseIterable, Identifiable {
    /// Whatever the device is set to — the default on a fresh install, so a
    /// Malaysian phone opens the app in Malay without anyone choosing anything.
    case system
    case english = "en"
    case malay = "ms"

    var id: String { rawValue }

    /// `nil` resolves against `Bundle.main`, i.e. follows the device.
    var code: String? { self == .system ? nil : rawValue }

    /// Always written *in* the language it names, so it stays readable no
    /// matter which language is currently active. Only "follow device" is
    /// translated, because it doesn't name a language.
    var label: String {
        switch self {
        case .system:  return L.Language.followDevice
        case .english: return "English"
        case .malay:   return "Bahasa Malaysia"
        }
    }

    /// The device's own language, shown under "follow device" so the choice
    /// isn't a mystery.
    static var deviceLabel: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        return AppLanguage(rawValue: code)?.label
            ?? Locale.current.localizedString(forLanguageCode: code)?.capitalized
            ?? code
    }
}

// MARK: - Live switching

/// Owns the language choice and the bundle every `L.*` lookup reads from.
///
/// `L`'s entries are computed properties that call `Bundle.appLanguage` on each
/// access, so swapping the bundle here re-translates the whole app — no
/// relaunch. (Stored `let`s would have frozen the first language the process
/// happened to read.)
final class LanguageStore: ObservableObject {
    static let shared = LanguageStore()

    @Published private(set) var language: AppLanguage
    private(set) var bundle: Bundle

    /// Lives here rather than in `SettingsView` so the sheet can be presented
    /// from above the language `.id()` — otherwise switching language rebuilds
    /// the tree underneath it and the sheet vanishes mid-tap.
    @Published var isPickerPresented = false

    private init() {
        let stored = UserDefaults.standard.string(forKey: SettingsKeys.appLanguage)
        let initial = stored.flatMap(AppLanguage.init(rawValue:)) ?? .system
        language = initial
        bundle = Self.resolve(initial)
    }

    /// Dates and numbers should follow the chosen language too.
    var locale: Locale {
        language.code.map(Locale.init(identifier:)) ?? .autoupdatingCurrent
    }

    func select(_ new: AppLanguage) {
        guard new != language else { return }
        UserDefaults.standard.set(new.rawValue, forKey: SettingsKeys.appLanguage)
        // Bundle first: by the time the published change redraws the tree,
        // every `L` read already returns the new language.
        bundle = Self.resolve(new)
        language = new
    }

    private static func resolve(_ language: AppLanguage) -> Bundle {
        guard let code = language.code,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }
}

extension Bundle {
    /// The bundle `L` resolves copy from. A key missing there falls through to
    /// the English `defaultValue:` at the call site, so a half-finished
    /// translation degrades one string at a time rather than breaking.
    static var appLanguage: Bundle { LanguageStore.shared.bundle }
}

// MARK: - Picker

/// The list of languages, shared by the onboarding step and the Settings sheet
/// so the two can never drift apart.
struct LanguageOptionList: View {
    @EnvironmentObject private var store: LanguageStore

    var body: some View {
        VStack(spacing: 10) {
            ForEach(AppLanguage.allCases) { option in
                row(option)
            }
        }
    }

    private func row(_ option: AppLanguage) -> some View {
        let selected = store.language == option
        return Button {
            store.select(option)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .font(.nunito(15.5, .heavy))
                        .foregroundStyle(Theme.ink)
                    if option == .system {
                        Text(AppLanguage.deviceLabel)
                            .font(.nunito(12.5, .semibold))
                            .foregroundStyle(Theme.inkMuted)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(selected ? Theme.rose : Theme.chevron)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(selected ? Theme.rose : Theme.cardBorder, lineWidth: 2)
            }
            .shadow(color: Theme.softShadow, radius: 9, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings sheet

struct LanguageSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L.Language.sub)
                        .font(.nunito(14))
                        .lineSpacing(5)
                        .foregroundStyle(Theme.inkMuted)
                        .padding(.bottom, 18)
                    LanguageOptionList()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle(L.Language.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.Common.done) { dismiss() }
                        .font(.nunito(15, .heavy))
                }
            }
        }
        .tint(Theme.rose)
    }
}

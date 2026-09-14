import SwiftUI

/// Destinations pushed from Settings.
enum SettingsDestination: Hashable {
    case dayConfig, sync
}

struct SettingsView: View {
    var onToast: (String) -> Void = { _ in }

    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKeys.isPremium) private var isPremium = false
    @AppStorage(SettingsKeys.userName) private var userName = "Nadia"
    @AppStorage(SettingsKeys.babyName) private var babyName = ""
    @AppStorage(SettingsKeys.babyAgeBand) private var babyAge = "0–6 months"

    @State private var path = NavigationPath()
    @State private var sheet: SettingsSheet?

    private enum SettingsSheet: String, Identifiable {
        case profile, feedback, notifications, paywall
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.baloo(32))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 22)

                    VStack(alignment: .leading, spacing: 0) {
                        profileCard.padding(.top, 16)

                        SectionLabel("APP").padding(.top, 20).padding(.bottom, 8).padding(.horizontal, 4)
                        appCard

                        SectionLabel("SUPPORT").padding(.top, 20).padding(.bottom, 8).padding(.horizontal, 4)
                        supportCard

                        SectionLabel("ABOUT").padding(.top, 20).padding(.bottom, 8).padding(.horizontal, 4)
                        aboutCard

                        signOutButton.padding(.top, 18)
                        footer.padding(.top, 14)
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.top, 8)
                .padding(.bottom, 116)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: SettingsDestination.self) { dest in
                switch dest {
                case .dayConfig: DayConfigView()
                case .sync:      SyncToCloudView()
                }
            }
            .sheet(item: $sheet) { which in
                switch which {
                case .profile:       ProfileSheet()
                case .feedback:      FeedbackSheet(onSent: onToast)
                case .notifications: NotificationsSheet()
                case .paywall:       PremiumPaywallView(onToast: onToast)
                }
            }
        }
        .tint(Theme.rose)
    }

    // MARK: Profile

    private var profileCard: some View {
        Button { sheet = .profile } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(Theme.rosePillBg)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Text(userName.prefix(1))
                            .font(.baloo(20, heavy: true))
                            .foregroundStyle(Theme.roseLabel)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(userName)
                        .font(.baloo(18, heavy: true))
                        .foregroundStyle(Theme.ink)
                    Text("\(babyName.isBlank ? "Baby" : babyName) · \(babyAge)")
                        .font(.nunito(12.5, .semibold))
                        .foregroundStyle(Theme.inkMuted)
                    Text(isPremium ? "PREMIUM MEMBER" : "FREE PLAN")
                        .font(.nunito(10, .heavy))
                        .foregroundStyle(isPremium ? Theme.roseLabel : Theme.inkBody)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isPremium ? Theme.roseBadgeBg : Theme.field, in: Capsule())
                        .padding(.top, 5)
                }
                Spacer(minLength: 0)
                Chevron()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Theme.cardBorder, lineWidth: 2)
            }
            .shadow(color: Theme.softShadow, radius: 9, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: Grouped rows

    private var appCard: some View {
        groupedCard {
            SettingsRow(icon: "appointment", title: "My day & scheduling") {
                path.append(SettingsDestination.dayConfig)
            }
            CardDivider()
            SettingsRow(icon: "bell-rose", title: "Notifications") { sheet = .notifications }
            CardDivider()
            SettingsRow(icon: "sync-to-cloud", title: "Sync to Cloud", badge: isPremium ? nil : "PREMIUM") {
                if isPremium { path.append(SettingsDestination.sync) } else { sheet = .paywall }
            }
            CardDivider()
            SettingsRow(icon: "icon-star", title: "Subscription") {
                if isPremium { onToast("You're already Premium, mama") } else { sheet = .paywall }
            }
        }
    }

    private var supportCard: some View {
        groupedCard {
            SettingsRow(icon: "icon-message", title: "Send feedback") { sheet = .feedback }
            CardDivider()
            SettingsRow(icon: "icon-help", title: "Help & FAQ") {
                onToast("Help centre opens in the full build")
            }
            CardDivider()
            SettingsRow(icon: "icon-star", title: "Rate Mommy's Time") {
                onToast("Store rating opens in the full build")
            }
            CardDivider()
            SettingsRow(icon: "icon-rerun", title: "Run setup again") {
                hasCompletedOnboarding = false
            }
        }
    }

    private var aboutCard: some View {
        groupedCard {
            SettingsRow(icon: "icon-privacy", title: "Privacy policy") {
                onToast("Privacy policy opens in the full build")
            }
            CardDivider()
            SettingsRow(icon: "icon-terms", title: "Terms of use") {
                onToast("Terms open in the full build")
            }
        }
    }

    private func groupedCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Theme.cardBorder, lineWidth: 2)
            }
            .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    private var signOutButton: some View {
        Button { onToast("Signed out — in the full build this returns to login") } label: {
            Text("Sign out")
                .font(.nunito(14, .heavy))
                .foregroundStyle(Theme.tileGlyph)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Theme.cardBorder, lineWidth: 2)
                }
                .shadow(color: Theme.softShadow, radius: 9, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        Text("Mommy's Time \(AppInfo.version)\nMade for mamas in Malaysia")
            .font(.nunito(11.5, .semibold))
            .lineSpacing(5)
            .foregroundStyle(Theme.inkWhisper)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Row

private struct SettingsRow: View {
    let icon: String
    let title: String
    var badge: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(icon)
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 19, height: 19)
                    .frame(width: 34, height: 34)
                    .background(Theme.peach, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title)
                    .font(.nunito(15, .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let badge {
                    Text(badge)
                        .font(.nunito(9.5, .heavy))
                        .foregroundStyle(Theme.roseLabel)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.roseBadgeBg, in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.roseBadgeBorder, lineWidth: 1.5))
                        .padding(.trailing, 8)
                }
                Chevron()
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.chevron)
    }
}

enum AppInfo {
    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "v\(short) (build \(build))"
    }
}

// MARK: - My day

/// The scheduling knobs that used to be the whole Settings screen; now a
/// sub-page of it.
struct DayConfigView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 22
    @AppStorage(SettingsKeys.bedtimeHour) private var bedtimeHour = 21
    @AppStorage(SettingsKeys.minGapMinutes) private var minGapMinutes = 30

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SectionLabel("YOUR DAY").padding(.bottom, 8)

                SoftCard(padding: .init(top: 0, leading: 18, bottom: 0, trailing: 18)) {
                    VStack(spacing: 0) {
                        stepperRow("My day starts", hourLabel(dayStartHour),
                                   down: { dayStartHour = max(4, dayStartHour - 1) },
                                   up: { dayStartHour = min(dayEndHour - 2, dayStartHour + 1) })
                        CardDivider()
                        stepperRow("My day ends", hourLabel(dayEndHour),
                                   down: { dayEndHour = max(dayStartHour + 2, dayEndHour - 1) },
                                   up: { dayEndHour = min(23, dayEndHour + 1) })
                    }
                }
                hint("The app only looks for me-time between these hours.")

                SoftCard {
                    stepperRow("Kids' bedtime", hourLabel(bedtimeHour),
                               down: { bedtimeHour = max(17, bedtimeHour - 1) },
                               up: { bedtimeHour = min(23, bedtimeHour + 1) })
                }
                .padding(.top, 14)
                hint("Free time after bedtime gets a bonus — the house is quiet.")

                SoftCard {
                    HStack {
                        Text("Minimum gap")
                            .font(.nunito(15, .bold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        SoftStepper(label: gapLabel(minGapMinutes)) {
                            minGapMinutes = max(15, minGapMinutes - 15)
                        } onIncrement: {
                            minGapMinutes = min(120, minGapMinutes + 15)
                        }
                    }
                    .padding(.vertical, 15)
                }
                .padding(.top, 14)
                hint("Gaps shorter than this won't be suggested — you deserve more than a rushed five minutes.")
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 116)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 12) {
                CircleBackButton { dismiss() }
                Text("My day")
                    .font(.baloo(24, heavy: true))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 4)
            .background(Theme.canvas)
        }
    }

    private func stepperRow(_ label: String, _ value: String,
                            down: @escaping () -> Void, up: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .font(.nunito(15, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            SoftStepper(label: value, minWidth: 84, onDecrement: down, onIncrement: up)
        }
        .padding(.vertical, 12)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.nunito(11.5, .semibold))
            .lineSpacing(4)
            .foregroundStyle(Theme.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
            .padding(.horizontal, 4)
    }

    private func gapLabel(_ m: Int) -> String {
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }

    private func hourLabel(_ hour: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

// MARK: - Profile

struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKeys.userName) private var userName = "Nadia"
    @AppStorage(SettingsKeys.userEmail) private var userEmail = ""
    @AppStorage(SettingsKeys.babyName) private var babyName = ""

    @State private var name = ""
    @State private var email = ""
    @State private var baby = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "My profile", enabled: !name.isBlank,
                            onCancel: { dismiss() }, onConfirm: save)

                Circle()
                    .fill(Theme.rosePillBg)
                    .frame(width: 86, height: 86)
                    .overlay {
                        Text(name.isBlank ? "?" : String(name.prefix(1)))
                            .font(.baloo(30, heavy: true))
                            .foregroundStyle(Theme.roseLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)

                SectionLabel("YOU").padding(.top, 22).padding(.bottom, 8)
                SoftCard {
                    VStack(spacing: 0) {
                        field("Your name", $name)
                        CardDivider()
                        field("Email", $email, keyboard: .emailAddress)
                    }
                }

                SectionLabel("BABY").padding(.top, 20).padding(.bottom, 8)
                SoftCard {
                    field("Baby's name", $baby)
                }

                Text("Your community posts show your first name only.")
                    .font(.nunito(11.5, .semibold))
                    .lineSpacing(4)
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(Theme.canvas)
        .presentationBackground(Theme.canvas)
        .presentationDragIndicator(.hidden)
        .onAppear {
            name = userName
            email = userEmail
            baby = babyName
        }
    }

    private func field(_ placeholder: String, _ text: Binding<String>,
                       keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .font(.nunito(15, .bold))
            .foregroundStyle(Theme.ink)
            .keyboardType(keyboard)
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
            .autocorrectionDisabled(keyboard == .emailAddress)
            .padding(.vertical, 14)
    }

    private func save() {
        guard !name.isBlank else { return }
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        babyName = baby.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}

// MARK: - Feedback

struct FeedbackSheet: View {
    var onSent: (String) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var kind = "Idea"
    @State private var text = ""

    private let kinds = ["Idea", "Something's broken", "Just saying hi"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Send feedback", confirm: "Send", enabled: !text.isBlank,
                            onCancel: { dismiss() }, onConfirm: send)

                Text("Tell us what's working and what isn't. A real person reads every note.")
                    .font(.nunito(13.5, .semibold))
                    .lineSpacing(5)
                    .foregroundStyle(Theme.inkBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)
                    .padding(.horizontal, 2)

                SectionLabel("WHAT KIND?").padding(.top, 20).padding(.bottom, 8)
                FlowRow(spacing: 8) {
                    ForEach(kinds, id: \.self) { k in
                        ChipButton(label: k, selected: kind == k, fills: false) { kind = k }
                    }
                }

                SoftCard(padding: .init(top: 14, leading: 18, bottom: 14, trailing: 18)) {
                    TextField("Write as much or as little as you like.", text: $text, axis: .vertical)
                        .lineLimit(6...)
                        .font(.nunito(14, .bold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 16)

                Text("Sent with app version \(AppInfo.version) so we know what you were using.")
                    .font(.nunito(11.5, .semibold))
                    .lineSpacing(4)
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(Theme.canvas)
        .presentationBackground(Theme.canvas)
        .presentationDragIndicator(.hidden)
    }

    private func send() {
        guard !text.isBlank else { return }
        dismiss()
        onSent("Thank you — feedback sent")
    }
}

#Preview {
    SettingsView()
}

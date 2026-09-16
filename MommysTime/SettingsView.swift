import SwiftUI

/// Destinations pushed from Settings.
enum SettingsDestination: Hashable {
    case dayConfig, sync
}

struct SettingsView: View {
    var onToast: (String) -> Void = { _ in }

    @EnvironmentObject private var language: LanguageStore

    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKeys.isPremium) private var isPremium = false
    @AppStorage(SettingsKeys.userName) private var userName = L.Settings.defaultUserName
    @AppStorage(SettingsKeys.babyName) private var babyName = ""
    @AppStorage(SettingsKeys.babyAgeBand) private var babyAge = AgeBandOption.zeroToSix

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
                    Text(L.Settings.title)
                        .font(.baloo(32))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 22)

                    VStack(alignment: .leading, spacing: 0) {
                        profileCard.padding(.top, 16)

                        SectionLabel(L.Settings.sectionApp).padding(.top, 20).padding(.bottom, 8).padding(.horizontal, 4)
                        appCard

                        SectionLabel(L.Settings.sectionSupport).padding(.top, 20).padding(.bottom, 8).padding(.horizontal, 4)
                        supportCard

                        SectionLabel(L.Settings.sectionAbout).padding(.top, 20).padding(.bottom, 8).padding(.horizontal, 4)
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
                    Text(L.Settings.profileSubtitle(
                        baby: babyName.isBlank ? L.Settings.babyFallback : babyName,
                        age: AgeBandOption.label(babyAge)
                    ))
                        .font(.nunito(12.5, .semibold))
                        .foregroundStyle(Theme.inkMuted)
                    Text(isPremium ? L.Settings.premiumMember : L.Settings.freePlan)
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
            SettingsRow(icon: "appointment", title: L.Settings.rowDay) {
                path.append(SettingsDestination.dayConfig)
            }
            CardDivider()
            // Presented from RootView — picking a language rebuilds this view,
            // so a sheet owned here would be torn down mid-tap.
            SettingsRow(icon: "icon-globe", title: L.Settings.rowLanguage, value: language.language.label) {
                language.isPickerPresented = true
            }
            CardDivider()
            SettingsRow(icon: "bell-rose", title: L.Settings.rowNotifications) { sheet = .notifications }
            CardDivider()
            SettingsRow(icon: "sync-to-cloud", title: L.Settings.rowSync, badge: isPremium ? nil : L.Settings.premiumBadge) {
                if isPremium { path.append(SettingsDestination.sync) } else { sheet = .paywall }
            }
            CardDivider()
            SettingsRow(icon: "icon-star", title: L.Settings.rowSubscription) {
                if isPremium { onToast(L.Settings.toastAlreadyPremium) } else { sheet = .paywall }
            }
        }
    }

    private var supportCard: some View {
        groupedCard {
            SettingsRow(icon: "icon-message", title: L.Settings.rowFeedback) { sheet = .feedback }
            CardDivider()
            SettingsRow(icon: "icon-help", title: L.Settings.rowHelp) {
                onToast(L.Settings.toastHelp)
            }
            CardDivider()
            SettingsRow(icon: "icon-star", title: L.Settings.rowRate) {
                onToast(L.Settings.toastRate)
            }
            CardDivider()
            SettingsRow(icon: "icon-rerun", title: L.Settings.rowRerun) {
                hasCompletedOnboarding = false
            }
        }
    }

    private var aboutCard: some View {
        groupedCard {
            SettingsRow(icon: "icon-privacy", title: L.Settings.rowPrivacy) {
                onToast(L.Settings.toastPrivacy)
            }
            CardDivider()
            SettingsRow(icon: "icon-terms", title: L.Settings.rowTerms) {
                onToast(L.Settings.toastTerms)
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
        Button { onToast(L.Settings.toastSignedOut) } label: {
            Text(L.Settings.signOut)
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
        Text(L.Settings.footer(AppInfo.version))
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
    /// The current setting, shown quietly before the chevron — unlike `badge`,
    /// which is a rose "PREMIUM" call-out.
    var value: String?
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
                if let value {
                    Text(value)
                        .font(.nunito(13, .semibold))
                        .foregroundStyle(Theme.inkMuted)
                        .lineLimit(1)
                        .padding(.trailing, 8)
                }
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
        let short = info?["CFBundleShortVersionString"] as? String ?? L.App.versionFallback
        let build = info?["CFBundleVersion"] as? String ?? L.App.buildFallback
        return L.App.version(short, build: build)
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
                SectionLabel(L.Settings.daySection).padding(.bottom, 8)

                SoftCard(padding: .init(top: 0, leading: 18, bottom: 0, trailing: 18)) {
                    VStack(spacing: 0) {
                        stepperRow(L.Settings.dayStarts, hourLabel(dayStartHour),
                                   down: { dayStartHour = max(4, dayStartHour - 1) },
                                   up: { dayStartHour = min(dayEndHour - 2, dayStartHour + 1) })
                        CardDivider()
                        stepperRow(L.Settings.dayEnds, hourLabel(dayEndHour),
                                   down: { dayEndHour = max(dayStartHour + 2, dayEndHour - 1) },
                                   up: { dayEndHour = min(23, dayEndHour + 1) })
                    }
                }
                hint(L.Settings.dayHint)

                SoftCard {
                    stepperRow(L.Settings.bedtime, hourLabel(bedtimeHour),
                               down: { bedtimeHour = max(17, bedtimeHour - 1) },
                               up: { bedtimeHour = min(23, bedtimeHour + 1) })
                }
                .padding(.top, 14)
                hint(L.Settings.bedtimeHint)

                SoftCard {
                    HStack {
                        Text(L.Settings.minimumGap)
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
                hint(L.Settings.minimumGapHint)
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
                Text(L.Settings.dayTitle)
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

    private func gapLabel(_ m: Int) -> String { L.Duration.compact(m) }

    private func hourLabel(_ hour: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

// MARK: - Profile

struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKeys.userName) private var userName = L.Settings.defaultUserName
    @AppStorage(SettingsKeys.userEmail) private var userEmail = ""
    @AppStorage(SettingsKeys.babyName) private var babyName = ""

    @State private var name = ""
    @State private var email = ""
    @State private var baby = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: L.Settings.profileTitle, enabled: !name.isBlank,
                            onCancel: { dismiss() }, onConfirm: save)

                Circle()
                    .fill(Theme.rosePillBg)
                    .frame(width: 86, height: 86)
                    .overlay {
                        Text(name.isBlank ? L.Settings.profileInitialFallback : String(name.prefix(1)))
                            .font(.baloo(30, heavy: true))
                            .foregroundStyle(Theme.roseLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 22)

                SectionLabel(L.Settings.profileSectionYou).padding(.top, 22).padding(.bottom, 8)
                SoftCard {
                    VStack(spacing: 0) {
                        field(L.Settings.profileName, $name)
                        CardDivider()
                        field(L.Settings.profileEmail, $email, keyboard: .emailAddress)
                    }
                }

                SectionLabel(L.Settings.profileSectionBaby).padding(.top, 20).padding(.bottom, 8)
                SoftCard {
                    field(L.Settings.profileBabyName, $baby)
                }

                Text(L.Settings.profileHint)
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
    @State private var kind = L.Settings.feedbackKindIdea
    @State private var text = ""

    private let kinds = [
        L.Settings.feedbackKindIdea,
        L.Settings.feedbackKindBroken,
        L.Settings.feedbackKindHi,
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: L.Settings.feedbackTitle, confirm: L.Settings.feedbackSend, enabled: !text.isBlank,
                            onCancel: { dismiss() }, onConfirm: send)

                Text(L.Settings.feedbackBlurb)
                    .font(.nunito(13.5, .semibold))
                    .lineSpacing(5)
                    .foregroundStyle(Theme.inkBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)
                    .padding(.horizontal, 2)

                SectionLabel(L.Settings.feedbackKindLabel).padding(.top, 20).padding(.bottom, 8)
                FlowRow(spacing: 8) {
                    ForEach(kinds, id: \.self) { k in
                        ChipButton(label: k, selected: kind == k, fills: false) { kind = k }
                    }
                }

                SoftCard(padding: .init(top: 14, leading: 18, bottom: 14, trailing: 18)) {
                    TextField(L.Settings.feedbackPlaceholder, text: $text, axis: .vertical)
                        .lineLimit(6...)
                        .font(.nunito(14, .bold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 16)

                Text(L.Settings.feedbackVersionNote(AppInfo.version))
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
        onSent(L.Settings.feedbackToast)
    }
}

#Preview {
    SettingsView()
}

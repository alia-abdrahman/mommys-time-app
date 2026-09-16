import SwiftUI

// The three pickers onboarding writes to `AppStorage`. The raw values are
// persisted, so they stay in English; `label` is what ends up on screen.

enum AgeBandOption {
    static let newborn = "Newborn"
    static let zeroToSix = "0–6 months"
    static let sixToTwelve = "6–12 months"
    static let overOneYear = "1 year +"

    static let all = [newborn, zeroToSix, sixToTwelve, overOneYear]

    static func label(_ value: String) -> String {
        switch value {
        case newborn: return L.AgeBand.newborn
        case sixToTwelve: return L.AgeBand.sixToTwelve
        case overOneYear: return L.AgeBand.overOneYear
        default: return L.AgeBand.zeroToSix
        }
    }
}

enum CaregiverRelation {
    static let husband = "Husband"
    static let wife = "Wife"
    static let partner = "Partner"
    static let mum = "Mum"
    static let nanny = "Nanny"
    static let grandma = "Grandma"
    static let sitter = "Sitter"

    static let all = [husband, wife, partner, mum, nanny]

    static func label(_ value: String) -> String {
        switch value {
        case wife: return L.Relation.wife
        case partner: return L.Relation.partner
        case mum: return L.Relation.mum
        case nanny: return L.Relation.nanny
        case grandma: return L.Relation.grandma
        case sitter: return L.Relation.sitter
        default: return L.Relation.husband
        }
    }
}

/// Full-screen 6-step onboarding: language · welcome · baby · day · care · done.
/// Nothing is mandatory — every input has a working default so the user can tap
/// straight through. The flow writes through only on the final CTA.
///
/// Language is the exception, and the reason it goes first: it applies the
/// moment it's tapped, so the rest of setup is already in her language.
struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var context

    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 22
    @AppStorage(SettingsKeys.babyName) private var babyNameStore = ""
    @AppStorage(SettingsKeys.babyAgeBand) private var ageBandStore = AgeBandOption.zeroToSix
    @AppStorage(SettingsKeys.caregiverName) private var caregiverNameStore = ""
    @AppStorage(SettingsKeys.caregiverRelation) private var caregiverRelationStore = CaregiverRelation.husband

    /// Toast to raise on Home after skip/finish.
    var onExit: (String) -> Void = { _ in }

    // Working copies — persisted through only on finish.
    @State private var page = 0
    @State private var babyName = ""
    @State private var ageBand = AgeBandOption.zeroToSix
    @State private var startMin = 360      // 6:00 AM
    @State private var endMin = 1320       // 10:00 PM
    @State private var caregiverName = ""
    @State private var relation = CaregiverRelation.husband
    @FocusState private var focused: Bool

    private let total = 6
    private var lastPage: Int { total - 1 }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            body(for: page)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            primaryCTA
        }
        .background(OB.screenBg.ignoresSafeArea())
        .onAppear(perform: seedFromStore)
        .contentShape(Rectangle())
        .onTapGesture { focused = false }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { withAnimation { page -= 1 } } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(OB.backIcon)
                    .frame(width: 36, height: 36)
                    .background(.white, in: Circle())
                    .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 10, y: 3)
            }
            .buttonStyle(.plain)
            .opacity(page == 0 ? 0 : 1)
            .disabled(page == 0)

            Spacer()
            dots
            Spacer()

            Button { skip() } label: {
                Text(L.Onboarding.skip)
                    .font(.nunito(13, .heavy))
                    .foregroundStyle(OB.skipText)
                    .padding(.vertical, 8).padding(.horizontal, 14)
            }
            .opacity(page == lastPage ? 0 : 1)
            .disabled(page == lastPage)
        }
        .frame(height: 36)
        .padding(.top, 20)
        .padding(.horizontal, 22)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == page ? OB.dotActive : (i < page ? OB.dotPast : OB.dotFuture))
                    .frame(width: i == page ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
            }
        }
    }

    // MARK: - Body router

    @ViewBuilder
    private func body(for step: Int) -> some View {
        switch step {
        case 0: languageStep
        case 1: welcomeStep
        case 2: babyStep
        case 3: dayStep
        case 4: careStep
        default: doneStep
        }
    }

    // MARK: - Step 1 · Language

    private var languageStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(L.Language.title, L.Language.sub)
            LanguageOptionList().padding(.top, 20)
        }
        .padding(.top, 20).padding(.horizontal, 24)
    }

    // MARK: - Step 2 · Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(L.Onboarding.welcomeEyebrow)
                    .font(.nunito(12, .heavy)).tracking(1.6)
                    .foregroundStyle(OB.roseAccent)
                Text(L.App.name)
                    .font(.baloo(36, heavy: true))
                    .foregroundStyle(OB.textPrimary)
                    .padding(.top, 4)
                Text(L.Onboarding.welcomeBody)
                    .font(.nunito(15)).lineSpacing(6)
                    .foregroundStyle(OB.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12).padding(.horizontal, 8)
            }

            VStack(spacing: 12) {
                promiseCard("growth-log", L.Onboarding.promiseNormalTitle, L.Onboarding.promiseNormalSub)
                promiseCard("inventory", L.Onboarding.promiseHouseholdTitle, L.Onboarding.promiseHouseholdSub)
                promiseCard("icon-users", L.Onboarding.promiseAloneTitle, L.Onboarding.promiseAloneSub)
            }
            .padding(.top, 30)
        }
        .padding(.top, 44)
        .padding(.horizontal, 24)
    }

    private func promiseCard(_ asset: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 14) {
            Image(asset)
                .renderingMode(.template).resizable().scaledToFit()
                .frame(width: 21, height: 21)
                .foregroundStyle(OB.glyphRose)
                .frame(width: 42, height: 42)
                .background(OB.tileFill, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.nunito(15.5, .heavy)).foregroundStyle(OB.textPrimary)
                Text(sub).font(.nunito(12.5, .semibold)).foregroundStyle(OB.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 17).padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 12, y: 4)
    }

    // MARK: - Step 3 · Baby

    private var babyStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(L.Onboarding.babyTitle, L.Onboarding.babySub)
            nameCard(placeholder: L.Onboarding.babyNamePlaceholder, text: $babyName).padding(.top, 18)
            fieldLabel(L.Onboarding.babyAgeLabel).padding(.top, 20).padding(.bottom, 9)
            chips(AgeBandOption.all, label: AgeBandOption.label, selected: ageBand) { ageBand = $0 }
        }
        .padding(.top, 20).padding(.horizontal, 24)
    }

    // MARK: - Step 4 · Day

    private var dayStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(L.Onboarding.dayTitle, L.Onboarding.daySub)
            VStack(spacing: 0) {
                dayRow(L.Onboarding.dayStarts, value: timeLabel(startMin),
                       onMinus: { startMin = max(240, startMin - 30) },
                       onPlus: { startMin = min(endMin - 120, startMin + 30) })
                Rectangle().fill(OB.divider).frame(height: 1)
                dayRow(L.Onboarding.dayEnds, value: timeLabel(endMin),
                       onMinus: { endMin = max(startMin + 120, endMin - 30) },
                       onPlus: { endMin = min(1410, endMin + 30) })
            }
            .padding(.horizontal, 18).padding(.vertical, 4)
            .background(.white, in: RoundedRectangle(cornerRadius: 26))
            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
            .padding(.top, 18)

            note(L.Onboarding.dayNote(onDutyLabel))
                .padding(.top, 14)
        }
        .padding(.top, 20).padding(.horizontal, 24)
    }

    private func dayRow(_ label: String, value: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack {
            Text(label).font(.nunito(15, .bold)).foregroundStyle(OB.textPrimary)
            Spacer()
            HStack(spacing: 0) {
                Button(action: onMinus) {
                    Text(L.Glyph.minus).font(.nunito(16, .heavy)).foregroundStyle(OB.textSecondary).frame(width: 36, height: 32)
                }.buttonStyle(.plain)
                Text(value).font(.nunito(13, .heavy)).foregroundStyle(OB.valueText).frame(minWidth: 84)
                Button(action: onPlus) {
                    Text(L.Glyph.plus).font(.nunito(16, .heavy)).foregroundStyle(OB.roseAccent).frame(width: 36, height: 32)
                }.buttonStyle(.plain)
            }
            .background(OB.fieldFill, in: Capsule())
        }
        .padding(.vertical, 12)
    }

    // MARK: - Step 5 · Care

    private var careStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(L.Onboarding.careTitle, L.Onboarding.careSub)
            nameCard(placeholder: L.Onboarding.careNamePlaceholder, text: $caregiverName).padding(.top, 18)
            fieldLabel(L.Onboarding.careRelationLabel).padding(.top, 20).padding(.bottom, 9)
            chips(CaregiverRelation.all, label: CaregiverRelation.label, selected: relation) { relation = $0 }
            note(L.Onboarding.careNote).padding(.top, 16)
        }
        .padding(.top, 20).padding(.horizontal, 24)
    }

    // MARK: - Step 6 · Done

    private var doneStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(babyName.isBlank ? L.Onboarding.doneTitle : L.Onboarding.doneTitleNamed(babyName.trimmed))
                    .font(.baloo(30, heavy: true))
                    .foregroundStyle(OB.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L.Onboarding.doneSub)
                    .font(.nunito(14)).lineSpacing(6)
                    .foregroundStyle(OB.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            VStack(spacing: 9) {
                summaryRow(
                    L.Onboarding.summaryBaby,
                    L.Onboarding.summaryBabyValue(
                        babyName.isBlank ? L.Onboarding.summaryNotSet : babyName.trimmed,
                        AgeBandOption.label(ageBand)
                    )
                )
                summaryRow(
                    L.Onboarding.summaryDay,
                    L.Onboarding.summaryDayValue(timeLabel(startMin), timeLabel(endMin))
                )
                summaryRow(
                    L.Onboarding.summaryCorner,
                    caregiverName.isBlank
                        ? L.Onboarding.summaryNobody
                        : L.Onboarding.summaryCornerValue(caregiverName.trimmed, CaregiverRelation.label(relation))
                )
            }
            .padding(.top, 16)
        }
        .padding(.top, 22).padding(.horizontal, 24)
    }

    private func summaryRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).font(.nunito(13.5, .bold)).foregroundStyle(OB.textSecondary)
            Spacer(minLength: 12)
            Text(value).font(.nunito(13.5, .heavy)).foregroundStyle(OB.textPrimary)
                .lineLimit(1).truncationMode(.tail)
        }
        .padding(.vertical, 13).padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 12, y: 4)
    }

    // MARK: - Shared building blocks

    private func heading(_ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.baloo(27, heavy: true)).foregroundStyle(OB.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(sub).font(.nunito(14)).lineSpacing(5).foregroundStyle(OB.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(OB.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func nameCard(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.nunito(16, .bold)).foregroundStyle(OB.textPrimary).tint(OB.roseCTA)
            .focused($focused)
            .padding(.vertical, 16).padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 26))
            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func chips(
        _ options: [String],
        label: @escaping (String) -> String,
        selected: String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        FlowLayout(spacing: 9, lineSpacing: 9) {
            ForEach(options, id: \.self) { opt in
                let sel = opt == selected
                Button { onSelect(opt) } label: {
                    Text(label(opt))
                        .font(.nunito(13.5, .heavy))
                        .foregroundStyle(sel ? .white : OB.chipIdleText)
                        .padding(.vertical, 11).padding(.horizontal, 17)
                        .background(sel ? OB.roseCTA : OB.chipIdle, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(sel ? 0 : 0.09), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func note(_ text: String) -> some View {
        Text(text).font(.nunito(12.5, .bold)).lineSpacing(5)
            .foregroundStyle(OB.noteText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(OB.noteBg, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - CTA

    private var primaryCTA: some View {
        Button(action: advance) {
            Text(page == 1 ? L.Onboarding.ctaStart : page == lastPage ? L.Onboarding.ctaFinish : L.Onboarding.ctaContinue)
                .font(.baloo(17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(OB.roseCTA, in: Capsule())
                .shadow(color: Color(hex: 0xBE5F78).opacity(0.42), radius: 24, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: - Logic

    private func seedFromStore() {
        babyName = babyNameStore
        ageBand = ageBandStore
        startMin = clampStart(dayStartHour * 60)
        endMin = max(startMin + 120, dayEndHour * 60)
        caregiverName = caregiverNameStore
        relation = caregiverRelationStore
    }

    private func clampStart(_ m: Int) -> Int { max(240, min(m, 1290)) }

    private func advance() {
        focused = false
        if page == lastPage { finish() } else { withAnimation { page += 1 } }
    }

    private func skip() {
        focused = false
        hasCompletedOnboarding = true
        onExit(L.Onboarding.toastSkipped)
    }

    private func finish() {
        // Write through only now.
        babyNameStore = babyName
        ageBandStore = ageBand
        dayStartHour = Int((Double(startMin) / 60).rounded())
        dayEndHour = Int((Double(endMin) / 60).rounded())
        caregiverNameStore = caregiverName
        caregiverRelationStore = relation

        hasCompletedOnboarding = true
        onExit(babyName.isBlank ? L.Onboarding.toastDone : L.Onboarding.toastDoneNamed)
    }

    private func timeLabel(_ minutes: Int) -> String {
        let h = (minutes / 60) % 24, m = minutes % 60
        let date = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }

    private var onDutyLabel: String {
        let m = endMin - startMin
        let h = m / 60, r = m % 60
        return r == 0 ? L.Duration.hours(h) : L.Duration.hoursMinutes(h, r)
    }
}

// MARK: - Reusable flow layout for wrapping chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 12
    var lineSpacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += lineHeight + lineSpacing; lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += lineHeight + lineSpacing; lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Onboarding palette

private enum OB {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let roseCTA = Color(hex: 0xD9758C)
    static let roseAccent = Color(hex: 0xC97B8C)
    static let tileFill = Color(hex: 0xFBEBD8)
    static let glyphRose = Color(hex: 0xC4788C)
    static let chipIdle = Color.white
    static let chipIdleText = Color(hex: 0x8A7E72)
    static let dotActive = Color(hex: 0xD9758C)
    static let dotPast = Color(hex: 0xEDC3CD)
    static let dotFuture = Color(hex: 0xEFE4D8)
    static let skipText = Color(hex: 0xA99B8C)
    static let backIcon = Color(hex: 0x8B7F72)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let divider = Color(hex: 0x7A6248).opacity(0.1)
    static let noteBg = Color(hex: 0xFBEBD8)
    static let noteText = Color(hex: 0x8A6A44)
}

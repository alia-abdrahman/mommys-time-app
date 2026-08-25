import SwiftUI

/// Warm 7-step onboarding matching the "Mommy's Time" design: cream canvas,
/// Baloo headings, dusty-rose accents, soft white cards and pill choices.
struct OnboardingView: View {
    // Persisted answers
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 22
    @AppStorage(SettingsKeys.babyName) private var babyName = ""
    @AppStorage(SettingsKeys.babyAgeBand) private var ageBand = "0–6 months"
    @AppStorage(SettingsKeys.trackers) private var trackersRaw = "Pump,Feeds,Appointments"
    @AppStorage(SettingsKeys.goalTitle) private var goalTitle = ""
    @AppStorage(SettingsKeys.goalTarget) private var goalTarget = 3
    @AppStorage(SettingsKeys.caregiverName) private var caregiverName = ""
    @AppStorage(SettingsKeys.caregiverRelation) private var caregiverRelation = "Husband"

    @State private var page = 0
    @State private var customGoal = ""
    @FocusState private var focused: Bool

    private let total = 7
    private var lastPage: Int { total - 1 }

    private var trackers: Set<String> {
        Set(trackersRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: $page) {
                welcomePage.tag(0)
                babyPage.tag(1)
                dayPage.tag(2)
                trackingPage.tag(3)
                goalPage.tag(4)
                caregiverPage.tag(5)
                summaryPage.tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: page)

            primaryButton
        }
        .background(Theme.canvas.ignoresSafeArea())
        .tint(Ob.accent)
    }

    // MARK: - Top bar (back · dots · skip)

    private var topBar: some View {
        ZStack {
            ProgressDots(total: total, current: page)
            HStack {
                if page > 0 {
                    Button { withAnimation { page -= 1 } } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 46, height: 46)
                            .background(.white, in: Circle())
                            .shadow(color: Theme.cardShadow, radius: 6, y: 3)
                    }
                } else {
                    Color.clear.frame(width: 46, height: 46)
                }
                Spacer()
                if page < lastPage {
                    Button { finish() } label: {
                        Text("Skip")
                            .font(.nunito(16, .bold))
                            .foregroundStyle(Theme.inkMuted)
                    }
                    .frame(height: 46)
                } else {
                    Color.clear.frame(width: 46, height: 46)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Page 1 · Welcome

    private var welcomePage: some View {
        PageScroll {
            VStack(spacing: 6) {
                Text("WELCOME TO")
                    .font(.nunito(14, .bold))
                    .tracking(2)
                    .foregroundStyle(Theme.roseText)
                Text("Mommy's Time")
                    .font(.baloo(34, heavy: true))
                    .foregroundStyle(Theme.ink)
                Text("You already run the whole day. This app maps it out, then finds the pockets that belong to you.")
                    .font(.nunito(16))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)

            VStack(spacing: 16) {
                FeatureCard(circle: Theme.amberBg, title: "Map the day", subtitle: "Routines, chores, appointments")
                FeatureCard(circle: Ob.pink, title: "Find your pockets", subtitle: "Real gaps, not wishful thinking")
                FeatureCard(circle: Theme.sageBg, title: "Share the load", subtitle: "Send the plan to your caregiver")
            }
            .padding(.top, 28)
        }
    }

    // MARK: - Page 2 · Baby

    private var babyPage: some View {
        PageScroll {
            Header(title: "Who are we caring for?", subtitle: "This shapes your feed, pump and growth logs.")

            InputField(placeholder: "Baby's name", text: $babyName, focused: $focused)
                .padding(.top, 22)

            FieldLabel("HOW OLD?")
                .padding(.top, 26)
            FlowPills(["Newborn", "0–6 months", "6–12 months", "1 year +"], selection: ageBand) { ageBand = $0 }
                .padding(.top, 10)
        }
    }

    // MARK: - Page 3 · Day

    private var dayPage: some View {
        PageScroll {
            Header(title: "When does your day run?", subtitle: "The app only looks for me-time between these hours.")

            VStack(spacing: 0) {
                StepperRow(label: "Starts", value: Self.hourLabel(dayStartHour),
                           onMinus: { dayStartHour = wrap(dayStartHour - 1) },
                           onPlus: { dayStartHour = wrap(dayStartHour + 1) })
                Divider().padding(.leading, 20)
                StepperRow(label: "Ends", value: Self.hourLabel(dayEndHour),
                           onMinus: { dayEndHour = wrap(dayEndHour - 1) },
                           onPlus: { dayEndHour = wrap(dayEndHour + 1) })
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 28))
            .shadow(color: Theme.cardShadow, radius: 10, y: 6)
            .padding(.top, 22)

            InfoBanner("That's \(onDutyHours)h on duty. We'll look for your time inside it.")
                .padding(.top, 18)
        }
    }

    // MARK: - Page 4 · Tracking

    private var trackingPage: some View {
        PageScroll {
            Header(title: "What should we keep track of?", subtitle: "Pick as many as you like — you can change this later.")

            let items: [(String, Color)] = [
                ("Pump", Theme.dustyBlueBg), ("Feeds", Theme.sageBg),
                ("Growth", Theme.periwinkleBg), ("Inventory", Theme.tealBg),
                ("Spending", Theme.amberBg), ("Appointments", Theme.lilacBg),
            ]
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(items, id: \.0) { name, tint in
                    TrackTile(title: name, circle: tint, selected: trackers.contains(name)) {
                        toggleTracker(name)
                    }
                }
            }
            .padding(.top, 22)
        }
    }

    // MARK: - Page 5 · Goal

    private var goalPage: some View {
        PageScroll {
            Header(title: "What's one thing just for you?", subtitle: "The app will hunt for time to make it happen.")

            FlowPills(["Read a book", "Stitch & craft", "Move my body", "Learn a language", "Just rest"],
                      selection: goalTitle) { goalTitle = ($0 == goalTitle ? "" : $0); customGoal = "" }
                .padding(.top, 22)

            VStack(spacing: 0) {
                TextField("Or write your own", text: $customGoal)
                    .font(.nunito(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .focused($focused)
                    .onChange(of: customGoal) { _, v in if !v.isEmpty { goalTitle = "" } }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                Divider().padding(.leading, 20)
                HStack {
                    Text("Target: \(goalTarget)× a week")
                        .font(.nunito(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    MiniStepper(onMinus: { goalTarget = max(1, goalTarget - 1) },
                                onPlus: { goalTarget = min(14, goalTarget + 1) })
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 28))
            .shadow(color: Theme.cardShadow, radius: 10, y: 6)
            .padding(.top, 18)
        }
    }

    // MARK: - Page 6 · Caregiver

    private var caregiverPage: some View {
        PageScroll {
            Header(title: "Who shares the load?", subtitle: "You'll be able to send them today's plan in one tap.")

            InputField(placeholder: "Their name", text: $caregiverName, focused: $focused)
                .padding(.top, 22)

            FieldLabel("THEY ARE MY")
                .padding(.top, 26)
            FlowPills(["Husband", "Wife", "Partner", "Mum", "Nanny"], selection: caregiverRelation) { caregiverRelation = $0 }
                .padding(.top, 10)

            InfoBanner("Nothing is sent until you tap Share — no accounts, no invites.")
                .padding(.top, 22)
        }
    }

    // MARK: - Page 7 · Summary

    private var summaryPage: some View {
        PageScroll {
            VStack(spacing: 8) {
                Text("You're all set")
                    .font(.baloo(32, heavy: true))
                    .foregroundStyle(Theme.ink)
                Text("Here's what's set up. Change any of it in Settings.")
                    .font(.nunito(16))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)

            VStack(spacing: 12) {
                SummaryRow("Baby", "\(babyName.isEmpty ? "Not set" : babyName) · \(ageBand)")
                SummaryRow("Your day", "\(Self.hourLabel(dayStartHour)) – \(Self.hourLabel(dayEndHour))")
                SummaryRow("Tracking", "\(trackers.count) logs")
                SummaryRow("Your goal", resolvedGoal.isEmpty ? "Skipped" : resolvedGoal)
                SummaryRow("Sharing with", caregiverName.isEmpty ? "Nobody yet" : caregiverName)
            }
            .padding(.top, 28)
        }
    }

    // MARK: - Primary button

    private var primaryButton: some View {
        Button(action: primaryAction) {
            Text(page == 0 ? "Let's set up" : page == lastPage ? "Open my app" : "Continue")
                .font(.baloo(20))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Ob.accent, in: Capsule())
                .shadow(color: Ob.accent.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 18)
    }

    // MARK: - Logic

    private func primaryAction() {
        focused = false
        if page == lastPage { finish() } else { withAnimation { page += 1 } }
    }

    private func finish() {
        if !customGoal.isEmpty { goalTitle = customGoal }
        hasCompletedOnboarding = true
    }

    private var resolvedGoal: String { customGoal.isEmpty ? goalTitle : customGoal }

    private func toggleTracker(_ name: String) {
        var set = trackers
        if set.contains(name) { set.remove(name) } else { set.insert(name) }
        trackersRaw = set.sorted().joined(separator: ",")
    }

    private var onDutyHours: Int {
        let diff = dayEndHour - dayStartHour
        return diff <= 0 ? diff + 24 : diff
    }

    private func wrap(_ h: Int) -> Int { ((h % 24) + 24) % 24 }

    static func hourLabel(_ hour: Int) -> String {
        let h = ((hour % 24) + 24) % 24
        let date = Calendar.current.date(bySettingHour: h, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

// MARK: - Palette

private enum Ob {
    static let accent = Color(hex: 0xD9758C)
    static let pink = Color(hex: 0xFBE4E8)
}

// MARK: - Shared layout

private struct PageScroll<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct Header: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.baloo(29, heavy: true))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.nunito(16))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

private struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.nunito(12, .bold))
            .tracking(1.4)
            .foregroundStyle(Theme.inkMuted)
    }
}

private struct InputField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.nunito(17, .semibold))
            .foregroundStyle(Theme.ink)
            .focused(focused)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: Theme.cardShadow, radius: 8, y: 4)
    }
}

private struct InfoBanner: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.nunito(15, .bold))
            .foregroundStyle(Theme.reminderText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Theme.peach, in: RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Progress dots

private struct ProgressDots: View {
    let total: Int
    let current: Int
    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(color(for: i))
                    .frame(width: i == current ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: current)
            }
        }
    }
    private func color(for i: Int) -> Color {
        if i == current { return Ob.accent }
        if i < current { return Ob.accent.opacity(0.4) }
        return Theme.inkMuted.opacity(0.35)
    }
}

// MARK: - Welcome feature card

private struct FeatureCard: View {
    let circle: Color
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 16) {
            Circle().fill(circle).frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.nunito(18, .bold)).foregroundStyle(Theme.ink)
                Text(subtitle).font(.nunito(14)).foregroundStyle(Theme.inkMuted)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Theme.cardShadow, radius: 10, y: 6)
    }
}

// MARK: - Selectable pills (wrapping)

private struct FlowPills: View {
    let options: [String]
    let selection: String
    let onSelect: (String) -> Void

    init(_ options: [String], selection: String, onSelect: @escaping (String) -> Void) {
        self.options = options
        self.selection = selection
        self.onSelect = onSelect
    }

    var body: some View {
        FlowLayout(spacing: 12, lineSpacing: 12) {
            ForEach(options, id: \.self) { opt in
                let sel = opt == selection
                Button { onSelect(opt) } label: {
                    Text(opt)
                        .font(.nunito(16, .bold))
                        .foregroundStyle(sel ? .white : Theme.inkSoft)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 15)
                        .background(sel ? Ob.accent : .white, in: Capsule())
                        .shadow(color: Theme.cardShadow, radius: 6, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Tracking tile

private struct TrackTile: View {
    let title: String
    let circle: Color
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle().fill(circle).frame(width: 32, height: 32)
                Text(title)
                    .font(.nunito(16, .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Ob.accent, lineWidth: selected ? 2 : 0)
            )
            .shadow(color: Theme.cardShadow, radius: 7, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Steppers

private struct StepperRow: View {
    let label: String
    let value: String
    let onMinus: () -> Void
    let onPlus: () -> Void
    var body: some View {
        HStack {
            Text(label).font(.nunito(18, .bold)).foregroundStyle(Theme.ink)
            Spacer()
            HStack(spacing: 0) {
                stepButton("minus", onMinus)
                Text(value)
                    .font(.nunito(16, .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 92)
                stepButton("plus", onPlus)
            }
            .background(Theme.peach, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }
    private func stepButton(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Ob.accent)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

private struct MiniStepper: View {
    let onMinus: () -> Void
    let onPlus: () -> Void
    var body: some View {
        HStack(spacing: 0) {
            btn("minus", onMinus)
            Divider().frame(height: 22)
            btn("plus", onPlus)
        }
        .background(Theme.peach, in: Capsule())
    }
    private func btn(_ s: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Image(systemName: s)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Ob.accent)
                .frame(width: 46, height: 40)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary row

private struct SummaryRow: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }
    var body: some View {
        HStack {
            Text(label).font(.nunito(16)).foregroundStyle(Theme.inkMuted)
            Spacer()
            Text(value).font(.nunito(16, .bold)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: Theme.cardShadow, radius: 7, y: 4)
    }
}

// MARK: - Simple flow layout for wrapping pills

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

#Preview {
    OnboardingView()
}

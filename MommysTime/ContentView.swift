import SwiftUI
import CoreData

enum SettingsKeys {
    static let dayStartHour = "dayStartHour"
    static let dayEndHour = "dayEndHour"
    static let bedtimeHour = "bedtimeHour"
    static let minGapMinutes = "minGapMinutes"
    static let maxSlotMinutes = "maxSlotMinutes"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let showGuide = "showGuide"
    static let pumpIntervalHours = "pumpIntervalHours"
    static let isPremium = "isPremium"

    // Collected during onboarding
    static let babyName = "babyName"
    static let babyAgeBand = "babyAgeBand"
    static let trackers = "trackers"
    static let goalTitle = "goalTitle"
    static let goalTarget = "goalTarget"
    static let caregiverName = "caregiverName"
    static let caregiverRelation = "caregiverRelation"
}

struct ContentView: View {
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var selectedTab = AppTab.home

    // Data + state for the "Share plan" button hosted in the tab bar.
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleBlock.startTime, ascending: true)])
    private var allBlocks: FetchedResults<ScheduleBlock>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.date, ascending: true)])
    private var appointments: FetchedResults<Appointment>
    @State private var showingSharePlan = false
    @State private var toast: String?

    init() {
        AppFont.register()
        // Warm "Avocation" skin behind SwiftUI Lists/Forms.
        UICollectionView.appearance().backgroundColor = UIColor(Theme.canvas)
    }

    var body: some View {
        // All tabs stay alive (keeps each tab's scroll / navigation state) and
        // the custom blush nav bar is inset along the bottom.
        ZStack {
            HomeView(selectedTab: $selectedTab).tabShown(selectedTab == AppTab.home)
            TodayView().tabShown(selectedTab == AppTab.schedule)
            GoalsView().tabShown(selectedTab == AppTab.goals)
            WeeklyProgressView().tabShown(selectedTab == AppTab.progress)
            SettingsView().tabShown(selectedTab == AppTab.settings)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab) { showingSharePlan = true }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .tint(Theme.rose)
        .font(.nunito(16))
        .sheet(isPresented: $showingSharePlan) {
            SharePlanSheet(planText: planText(for:)) { showToast($0) }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 190)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView()
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }

    private func planText(for day: Date) -> String {
        let calendar = Calendar.current
        let dayLabel = day.formatted(.dateTime.weekday(.wide).day().month())
        var lines = ["🌸 Plan for \(dayLabel)", ""]

        let blocks = allBlocks
            .compactMap { block in block.resolvedTimes(on: day).map { (block, $0.start, $0.end) } }
            .sorted { $0.1 < $1.1 }
        if !blocks.isEmpty {
            lines.append("Schedule:")
            for (block, start, end) in blocks {
                let s = start.formatted(.dateTime.hour().minute())
                let e = end.formatted(.dateTime.hour().minute())
                lines.append("• \(s)–\(e)  \(block.title ?? "")")
            }
            lines.append("")
        }

        let dayAppointments = appointments
            .filter { calendar.isDate($0.date ?? .distantPast, inSameDayAs: day) }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        if !dayAppointments.isEmpty {
            lines.append("Appointments:")
            for appt in dayAppointments {
                let time = appt.date?.formatted(.dateTime.hour().minute()) ?? ""
                var line = "• \(time)  \(appt.title ?? "")"
                if let location = appt.location, !location.isEmpty { line += " @ \(location)" }
                lines.append(line)
            }
            lines.append("")
        }

        if blocks.isEmpty && dayAppointments.isEmpty {
            lines.append("Nothing scheduled yet.")
            lines.append("")
        }

        lines.append("Sent with love from MommysTime 💛")
        return lines.joined(separator: "\n")
    }
}

private extension View {
    /// Keeps a tab in the hierarchy (preserving its state) while only the
    /// selected one is visible and interactive.
    func tabShown(_ shown: Bool) -> some View {
        opacity(shown ? 1 : 0)
            .allowsHitTesting(shown)
            .zIndex(shown ? 1 : 0)
    }
}

/// Blush bottom navigation with clean line icons and an elevated rose "heart"
/// button in the center — matching the app's Avocation design.
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    /// Triggered by the elevated center "Share plan" button.
    var onSharePlan: () -> Void

    /// True while a pointer hovers the Share plan button (iPad / trackpad).
    @State private var shareHovering = false

    private struct Item: Identifiable {
        let tab: Int
        /// Base name of the custom nav icon; "-active"/"-inactive" is appended.
        let asset: String
        let label: String
        var id: Int { tab }
    }

    private let tabs = [
        Item(tab: AppTab.home, asset: "nav-home", label: "Home"),
        Item(tab: AppTab.schedule, asset: "nav-schedule", label: "Schedule"),
        Item(tab: AppTab.goals, asset: "nav-goals", label: "Goals"),
        Item(tab: AppTab.progress, asset: "nav-progress", label: "Progress"),
        Item(tab: AppTab.settings, asset: "nav-settings", label: "Settings"),
    ]

    var body: some View {
        // Five evenly-spaced tabs in the bar, with the "Share plan" button
        // floating centered above the bar's top edge.
        HStack(spacing: 0) {
            ForEach(tabs) { iconButton($0) }
        }
        .padding(.top, 38)
        .padding(.bottom, 6)
        .padding(.horizontal, 6)
        .background(
            Theme.navBar
                .shadow(color: Theme.cardShadow, radius: 12, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            shareButton
                .offset(y: -48)
        }
    }

    private func iconButton(_ item: Item) -> some View {
        let selected = selectedTab == item.tab
        return Button {
            selectedTab = item.tab
        } label: {
            VStack(spacing: 4) {
                Image(selected ? "\(item.asset)-active" : "\(item.asset)-inactive")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(item.label)
                    .font(.nunito(11, .bold))
                    .foregroundStyle(selected ? Theme.navIconOn : Theme.navIcon)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Elevated rose circle with a paper-plane, labelled "Share plan",
    /// centered above the bar.
    private var shareButton: some View {
        Button(action: onSharePlan) {
            VStack(spacing: 5) {
                Image("share-plan-white")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .frame(width: 62, height: 62)
                    .background(Color(hex: 0xD9758C), in: Circle())
                    .overlay(Circle().stroke(Theme.canvas, lineWidth: 5))
                    .shadow(color: Color(hex: 0xD9758C).opacity(0.45), radius: 9, y: 5)
                Text("Share plan")
                    .font(.nunito(11, .bold))
                    .foregroundStyle(Theme.navIconOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(LiftButtonStyle())
        // Lift on hover (pointer devices); press handled by the style.
        .offset(y: shareHovering ? -12 : 0)
        .animation(.spring(response: 0.32, dampingFraction: 0.6), value: shareHovering)
        .onHover { shareHovering = $0 }
    }
}

/// Springs the label up and larger while pressed, then settles back — gives the
/// Share plan button a clearly visible "lift" when tapped.
private struct LiftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -12 : 0)
            .scaleEffect(configuration.isPressed ? 1.12 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

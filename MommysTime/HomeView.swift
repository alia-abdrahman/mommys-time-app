import SwiftUI
import CoreData

/// Tab indices, shared with ContentView's TabView tags so the home menu can
/// jump straight to a feature.
enum AppTab {
    static let home = 0
    static let schedule = 1
    static let goals = 2
    static let progress = 3
    static let settings = 4
}

struct HomeView: View {
    @Binding var selectedTab: Int

    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleBlock.startTime, ascending: true)],
        animation: .default
    )
    private var allBlocks: FetchedResults<ScheduleBlock>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.date, ascending: true)],
        animation: .default
    )
    private var appointments: FetchedResults<Appointment>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PumpSession.date, ascending: false)],
        animation: .default
    )
    private var pumpSessions: FetchedResults<PumpSession>

    @AppStorage(SettingsKeys.pumpIntervalHours) private var pumpIntervalHours = 3
    @AppStorage(SettingsKeys.isPremium) private var isPremium = false

    @State private var showingNotifications = false
    @State private var showingPaywall = false
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    banner
                    reminderCard
                    menuSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                // The premium section sits on top of the illustration, so the
                // sky and sun show around and behind the premium tiles.
                ZStack(alignment: .top) {
                    backgroundIllustration
                    premiumSection
                        .padding(.horizontal, 22)
                        .padding(.top, 18)
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showingPaywall) {
                PremiumPaywallView { showToast($0) }
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Toast(text: toast)
                        .padding(.bottom, 190)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .tint(Theme.rose)
    }

    /// Soft mother-and-baby illustration that sits at the very bottom of the
    /// scrolling home page. It fills the width and is shown in full (uncropped)
    /// so scrolling to the bottom reveals the whole scene, and the scroll ends
    /// exactly at the bottom edge of the illustration — no empty space below.
    /// Its cream sky is the exact same colour as `Theme.canvas`, so the top edge
    /// is pixel-identical to the background above it — there is no visible line
    /// where the two meet.
    private var backgroundIllustration: some View {
        Image("HomeIllustration")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .padding(.bottom, 70)
    }

    // MARK: 1 & 2 — Greeting + notification

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.nunito(13, .bold))
                    .tracking(0.3)
                    .foregroundStyle(Theme.inkMuted)
                Text("Hello, mama")
                    .font(.baloo(30, heavy: true))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Button { showingNotifications = true } label: {
                Image("bell")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 21)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(Theme.rose)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .offset(x: -5, y: 5)
                    }
                    .shadow(color: Theme.cardShadow, radius: 7, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 52)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "Good morning"
        case ..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }

    // MARK: 3 — Banner (tip of the day)

    private var banner: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Circle().fill(Theme.tipIconBg)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().fill(Theme.tipIconDot).frame(width: 7, height: 7))
                Text("TIP OF THE DAY")
                    .font(.nunito(11, .bold))
                    .tracking(1.1)
                    .foregroundStyle(Theme.tipLabel)
            }
            Text(tipOfTheDay)
                .font(.nunito(16, .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Theme.cardShadow, radius: 10, y: 6)
    }

    private var tipOfTheDay: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return Self.tips[day % Self.tips.count]
    }

    private static let tips = [
        "You can't pour from an empty cup. Ten minutes for you counts.",
        "Rest is productive too. The laundry can wait a little longer.",
        "A calm mama is the best gift for your little ones. Breathe.",
        "Done is better than perfect — especially today.",
        "Small pockets of me-time add up to a whole happier you.",
        "It's okay to ask for help. You don't have to do it all alone.",
        "Celebrate the tiny wins. You're doing more than you think.",
    ]

    // MARK: 4 — Reminder

    private var reminderCard: some View {
        HStack(spacing: 11) {
            Circle().fill(Theme.reminderIconBg)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xB07F4E))
                )
            Text(reminderText)
                .font(.nunito(14, .bold))
                .foregroundStyle(Theme.reminderText)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.reminderBg, in: RoundedRectangle(cornerRadius: 22))
    }

    private var reminderText: String {
        guard let next = nextEvent else {
            return "Nothing else scheduled today — enjoy the calm."
        }
        return "Next: \(next.title) \(timeUntil(next.date))"
    }

    private func timeUntil(_ date: Date) -> String {
        let minutes = max(0, Int(date.timeIntervalSinceNow / 60))
        if minutes < 1 { return "now" }
        if minutes < 60 { return "in \(minutes) min" }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "in \(hours) hour\(hours == 1 ? "" : "s")" : "in \(hours)h \(remainder)m"
    }

    // MARK: 5 — Menu

    private var menuSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Menu")
            LazyVGrid(columns: columns, spacing: 18) {
                Button { selectedTab = AppTab.schedule } label: {
                    TileLabel(title: "Schedule Builder", asset: "schedule-builder", icon: Theme.tileGlyph, bg: Theme.peach)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AppointmentsView()
                } label: {
                    TileLabel(title: "Appointment", asset: "appointment", icon: Theme.tileGlyph, bg: Theme.peach)
                }

                NavigationLink {
                    InventoryView()
                } label: {
                    TileLabel(title: "Inventory", asset: "inventory", icon: Theme.tileGlyph, bg: Theme.peach)
                }

                NavigationLink {
                    PumpTrackerView()
                } label: {
                    TileLabel(title: "Pump Tracker", asset: "pump-tracker", icon: Theme.tileGlyph, bg: Theme.peach)
                }

                NavigationLink {
                    FeedLogView()
                } label: {
                    TileLabel(title: "Feed Log", asset: "feed-log", icon: Theme.tileGlyph, bg: Theme.peach)
                }

                NavigationLink {
                    GrowthLogView()
                } label: {
                    TileLabel(title: "Growth Log", asset: "growth-log", icon: Theme.tileGlyph, bg: Theme.peach)
                }
            }
        }
    }

    // MARK: 6 — Premium features

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeading("Premium")
                Spacer()
                Button {
                    if isPremium { showToast("You're already Premium, mama") }
                    else { showingPaywall = true }
                } label: {
                    Text(isPremium ? "Premium" : "Unlock all")
                        .font(.nunito(11, .bold))
                        .foregroundStyle(Theme.roseText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Theme.rosePillBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(columns: columns, spacing: 18) {
                NavigationLink {
                    RecipesView()
                } label: {
                    TileLabel(title: "Recipes", asset: "recipes", icon: Theme.tileGlyph, bg: Theme.peach, isPremium: true)
                }

                NavigationLink {
                    MySpendingView()
                } label: {
                    TileLabel(title: "My Spending", asset: "my-spending", icon: Theme.tileGlyph, bg: Theme.peach, isPremium: true)
                }

                NavigationLink {
                    SyncToCloudView()
                } label: {
                    TileLabel(title: "Sync to Cloud", asset: "sync-to-cloud", icon: Theme.tileGlyph, bg: Theme.peach, isPremium: true)
                }
            }
        }
    }

    private func sectionHeading(_ text: String) -> some View {
        Text(text)
            .font(.baloo(17, heavy: true))
            .foregroundStyle(Theme.ink)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    }

    // MARK: Data helpers

    /// The soonest upcoming thing today — a scheduled block or an appointment.
    private var nextEvent: (title: String, date: Date)? {
        let now = Date()
        var candidates: [(title: String, date: Date)] = []

        if let block = allBlocks
            .compactMap({ b in b.resolvedTimes(on: now).map { (b, $0.start) } })
            .filter({ $0.1 > now })
            .sorted(by: { $0.1 < $1.1 })
            .first {
            candidates.append((block.0.title ?? "your next block", block.1))
        }

        if let appt = appointments.first(where: { ($0.date ?? .distantPast) > now }),
           let date = appt.date {
            candidates.append((appt.title ?? "appointment", date))
        }

        if let lastPump = pumpSessions.first?.date {
            let nextPump = lastPump.addingTimeInterval(Double(pumpIntervalHours) * 3600)
            if nextPump > now {
                candidates.append(("Pump session", nextPump))
            }
        }

        return candidates.min(by: { $0.date < $1.date })
    }
}

// MARK: - Tile

private struct TileLabel: View {
    let title: String
    /// Name of the custom vector icon in the asset catalog (e.g. "feed-log").
    let asset: String
    /// Accent colour — used only for the premium lock badge.
    let icon: Color
    let bg: Color
    var isPremium = false

    var body: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(bg)
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .overlay(
                        Image(asset)
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                    )
                    .shadow(color: Theme.cardShadow, radius: 8, y: 5)
                if isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(icon, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .offset(x: 3, y: -3)
                }
            }
            Text(title)
                .font(.nunito(12, .bold))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Placeholder destinations

private struct FeaturePlaceholderView: View {
    let title: String
    let systemImage: String
    let message: String
    var isPremium = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(isPremium ? .pink : .blue)
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            if isPremium {
                Label("Premium feature", systemImage: "lock.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Coming soon 🌸")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding(32)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header: centered title + "Done" pill
            ZStack {
                Text("Notifications")
                    .font(.baloo(20, heavy: true))
                    .foregroundStyle(Theme.ink)
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Text("Done")
                            .font(.nunito(16, .bold))
                            .foregroundStyle(Theme.roseText)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.rosePillBg, in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            Spacer()
            Spacer()
            Spacer()

            // Empty state
            VStack(spacing: 22) {
                Image("bell")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 48)
                    .foregroundStyle(Color(hex: 0xB07F4E))
                    .frame(width: 120, height: 120)
                    .background(Color(hex: 0xF7E0C6), in: Circle())
                VStack(spacing: 12) {
                    Text("You're all caught up")
                        .font(.baloo(25, heavy: true))
                        .foregroundStyle(Theme.ink)
                    Text("Reminders and gentle nudges will show up here.")
                        .font(.nunito(16))
                        .foregroundStyle(Theme.inkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .presentationDragIndicator(.hidden)
    }
}

struct SharePlan: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

struct PlanShareView: View {
    let plan: SharePlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(plan.text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: plan.text) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

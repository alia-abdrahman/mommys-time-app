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

    @State private var showingNotifications = false
    @State private var showingPlanOptions = false
    @State private var sharePlan: SharePlan?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    banner
                    reminderCard
                    menuSection
                    premiumSection
                }
                .padding()
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))
            .overlay(alignment: .bottom) { planButton }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(item: $sharePlan) { plan in
                PlanShareView(plan: plan)
            }
        }
    }

    // MARK: Generate & share plan

    private var planButton: some View {
        Button {
            showingPlanOptions = true
        } label: {
            Label("Share plan", systemImage: "paperplane.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.pink, Color.pink.opacity(0.8)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .shadow(color: .pink.opacity(0.4), radius: 8, y: 4)
        }
        .padding(.bottom, 12)
        .confirmationDialog("Generate a plan to share", isPresented: $showingPlanOptions, titleVisibility: .visible) {
            Button("Today's plan") {
                sharePlan = SharePlan(title: "Today's plan", text: planText(for: Date()))
            }
            Button("Tomorrow's plan") {
                if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                    sharePlan = SharePlan(title: "Tomorrow's plan", text: planText(for: tomorrow))
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Share the day's schedule and appointments with a caregiver.")
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

    // MARK: 1 & 2 — Greeting + notification

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Hello, mama 🌸")
                    .font(.largeTitle.bold())
            }
            Spacer()
            Button { showingNotifications = true } label: {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 48, height: 48)
                    .background(Color.yellow.opacity(0.25), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "Good morning"
        case ..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: 3 — Banner (tip of the day)

    private var banner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TIP OF THE DAY")
                .font(.caption2.bold())
                .foregroundStyle(.pink)
            Text(tipOfTheDay)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.18), Color.pink.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var tipOfTheDay: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return Self.tips[day % Self.tips.count]
    }

    private static let tips = [
        "You can't pour from an empty cup. Ten minutes for you counts. 💛",
        "Rest is productive too. The laundry can wait a little longer. 🌙",
        "A calm mama is the best gift for your little ones. Breathe. 🌸",
        "Done is better than perfect — especially today.",
        "Small pockets of me-time add up to a whole happier you. ✨",
        "It's okay to ask for help. You don't have to do it all alone.",
        "Celebrate the tiny wins. You're doing more than you think. 🌟",
    ]

    // MARK: 4 — Reminder

    private var reminderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(.orange)
            Text(reminderText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
    }

    private var reminderText: String {
        guard let next = nextEvent else {
            return "Nothing else scheduled today — enjoy the calm. 🌸"
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
            Text("Menu")
                .font(.headline)
            LazyVGrid(columns: columns, spacing: 16) {
                Button { selectedTab = AppTab.schedule } label: {
                    TileLabel(title: "Schedule Builder", systemImage: "calendar", color: .blue)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AppointmentsView()
                } label: {
                    TileLabel(title: "Appointment", systemImage: "calendar.badge.clock", color: .purple)
                }

                NavigationLink {
                    InventoryView()
                } label: {
                    TileLabel(title: "Inventory", systemImage: "archivebox.fill", color: .teal)
                }

                NavigationLink {
                    PumpTrackerView()
                } label: {
                    TileLabel(title: "Pump Tracker", systemImage: "drop.fill", color: .cyan)
                }

                NavigationLink {
                    FeedLogView()
                } label: {
                    TileLabel(title: "Feed Log", systemImage: "cup.and.saucer.fill", color: .mint)
                }

                NavigationLink {
                    GrowthLogView()
                } label: {
                    TileLabel(title: "Growth Log", systemImage: "ruler.fill", color: .indigo)
                }
            }
        }
    }

    // MARK: 6 — Premium features

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium")
                .font(.headline)
            LazyVGrid(columns: columns, spacing: 16) {
                NavigationLink {
                    RecipesView()
                } label: {
                    TileLabel(title: "Recipes", systemImage: "fork.knife", color: .pink, isPremium: true)
                }

                NavigationLink {
                    MySpendingView()
                } label: {
                    TileLabel(title: "My Spending", systemImage: "dollarsign.circle.fill", color: .pink, isPremium: true)
                }

                NavigationLink {
                    SyncToCloudView()
                } label: {
                    TileLabel(title: "Sync to Cloud", systemImage: "icloud.and.arrow.up.fill", color: .pink, isPremium: true)
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
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
    let systemImage: String
    let color: Color
    var isPremium = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 68, height: 68)
                    .background(color.opacity(isPremium ? 0.22 : 0.15), in: RoundedRectangle(cornerRadius: 18))
                if isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(color, in: Circle())
                        .offset(x: 4, y: -4)
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.primary)
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
        NavigationStack {
            VStack(spacing: 12) {
                Text("🔔")
                    .font(.system(size: 56))
                Text("You're all caught up")
                    .font(.title3.bold())
                Text("Reminders and gentle nudges will show up here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SharePlan: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

private struct PlanShareView: View {
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

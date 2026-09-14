import SwiftUI
import CoreData

/// Everything reachable by pushing from Home.
enum HomeDestination: Hashable {
    case schedule, appointment, inventory, pump, feed, growth, wake, recipes, spending, sync
}

struct HomeView: View {
    var onToast: (String) -> Void = { _ in }

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

    @ObservedObject private var noise = SootheNoise.shared

    @State private var path = NavigationPath()
    @State private var showingNotifications = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    tipCard.padding(.top, 10)
                    reminderPill.padding(.top, 8)
                    Text("What would you like to do today?")
                        .font(.baloo(19))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 14)
                    tileGrid.padding(.top, 10)
                    sootheButton.padding(.top, 20)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 116)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: HomeDestination.self, destination: destination)
            .sheet(isPresented: $showingNotifications) { NotificationsSheet() }
            .sheet(isPresented: $showingPaywall) { PremiumPaywallView(onToast: onToast) }
        }
        .tint(Theme.rose)
    }

    @ViewBuilder
    private func destination(_ dest: HomeDestination) -> some View {
        switch dest {
        case .schedule:    TodayView()
        case .appointment: AppointmentsView()
        case .inventory:   InventoryView()
        case .pump:        PumpTrackerView()
        case .feed:        FeedLogView()
        case .growth:      GrowthLogView()
        case .wake:        WakeWindowView()
        case .recipes:     RecipesView()
        case .spending:    MySpendingView()
        case .sync:        SyncToCloudView()
        }
    }

    // MARK: Greeting + notification bell

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.nunito(13, .bold))
                    .foregroundStyle(Theme.inkMuted)
                Text("Hello, mama")
                    .font(.baloo(32))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Button { showingNotifications = true } label: {
                Image("bell")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 20)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(Color(hex: 0xD97F92))
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .offset(x: -8, y: 6)
                    }
                    .shadow(color: Color(hex: 0x7A6248).opacity(0.14), radius: 7, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "Good morning"
        case ..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: Tip of the day

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image("tip-bulb")
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 18, height: 18)
                Text("TIP OF THE DAY")
                    .font(.nunito(13, .heavy))
                    .tracking(1.1)
                    .foregroundStyle(Theme.tipLabel)
            }
            Text(tipOfTheDay)
                .font(.nunito(17.5, .bold))
                .lineSpacing(4)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.10), radius: 9, y: 6)
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

    // MARK: Next-up reminder

    private var reminderPill: some View {
        Button { path.append(HomeDestination.pump) } label: {
            HStack(spacing: 11) {
                Image("reminder-alert")
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 22, height: 22)
                reminderText
                    .font(.nunito(16, .bold))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.peach, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.peachBorder, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    /// "Next: Pump session in **1h 11m**" — the countdown carries the darker ink.
    private var reminderText: Text {
        guard let next = nextEvent else {
            return Text("Nothing else scheduled today — enjoy the calm.")
                .foregroundColor(Theme.reminderText)
        }
        return Text("Next: \(next.title) ").foregroundColor(Theme.reminderText)
            + Text(timeUntil(next.date)).foregroundColor(Theme.reminderStrong)
    }

    /// Minutes up to an hour, hours up to a day, then days — "in 36h 16m" is a
    /// number you have to do arithmetic on; "in 1d 12h" isn't.
    private func timeUntil(_ date: Date) -> String {
        let minutes = max(0, Int(date.timeIntervalSinceNow / 60))
        if minutes < 1 { return "now" }
        if minutes < 60 { return "in \(minutes) min" }

        let hours = minutes / 60
        if hours < 24 {
            let remainder = minutes % 60
            return remainder == 0 ? "in \(hours)h" : "in \(hours)h \(remainder)m"
        }

        let days = hours / 24
        let remainder = hours % 24
        return remainder == 0 ? "in \(days)d" : "in \(days)d \(remainder)h"
    }

    // MARK: Menu grid

    private var tileGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
            tile("Daily Task", "schedule-builder") { path.append(HomeDestination.schedule) }
            tile("Appointment", "appointment") { path.append(HomeDestination.appointment) }
            tile("Inventory", "inventory") { path.append(HomeDestination.inventory) }
            tile("Pump Tracker", "pump-tracker") { path.append(HomeDestination.pump) }
            tile("Feed Log", "feed-log") { path.append(HomeDestination.feed) }
            tile("Growth Log", "growth-log") { path.append(HomeDestination.growth) }
            tile("Wake Window", "wake-window", premium: true) { path.append(HomeDestination.wake) }
            tile("Recipes", "recipes", premium: true) { path.append(HomeDestination.recipes) }
            tile("My Spending", "my-spending", premium: true) { path.append(HomeDestination.spending) }
        }
    }

    // MARK: Soothing sounds

    /// White noise, a tap away from wherever she is in the app. The blush card
    /// stays put while it plays — only the disc and the pill flip, so the row
    /// doesn't shout when the room has finally gone quiet.
    private var sootheButton: some View {
        let on = noise.isPlaying
        return Button { noise.toggle() } label: {
            HStack(spacing: 13) {
                SootheDisc(playing: on)

                VStack(alignment: .leading, spacing: 2) {
                    Text(on ? "Calming noise is playing" : "Baby won't settle?")
                        .font(.nunito(15.5, .heavy))
                        .foregroundStyle(Theme.roseAccentText)
                    Text(on ? "Tap stop when baby settles" : "One tap plays calming white noise")
                        .font(.nunito(12, .semibold))
                        .foregroundStyle(Theme.roseMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(on ? "Stop" : "Play")
                    .font(.nunito(13.5, .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Theme.tileGlyph, in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.roseTint, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.roseSoftBorder, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.22), value: on)
    }

    /// Premium tiles open the paywall until the subscription is unlocked.
    private func tile(_ title: String, _ asset: String, premium: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            if premium && !isPremium { showingPaywall = true } else { action() }
        } label: {
            MenuTile(title: title, asset: asset, premium: premium)
        }
        .buttonStyle(.plain)
    }

    // MARK: Data helpers

    /// The soonest upcoming thing today — a scheduled block, an appointment or
    /// the next pump session.
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

// MARK: - Soothe disc

/// The waves glyph on the soothe row. While the noise plays it breathes and
/// sends two rings out into the card — the only way to tell from across the
/// room that the sound is actually on.
private struct SootheDisc: View {
    let playing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    private var animates: Bool { playing && !reduceMotion }

    var body: some View {
        ZStack {
            if animates {
                // Staggered so one ring is always mid-flight.
                ForEach(0..<2, id: \.self) { index in
                    SootheRing(delay: Double(index) * 1.2)
                }
            }
            Image("icon-waves")
                .renderingMode(.template)
                .resizable().scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(playing ? .white : Theme.tileGlyph)
                .frame(width: 46, height: 46)
                .background(playing ? Theme.tileGlyph : Color.white, in: Circle())
                .scaleEffect(breathing ? 1.06 : 1)
        }
        .onChange(of: animates) { _, on in
            if on {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) { breathing = false }
            }
        }
    }
}

/// One ring, expanding and fading. Starts its loop on appear so it can't miss
/// the state change that inserted it.
private struct SootheRing: View {
    let delay: Double

    @State private var out = false

    var body: some View {
        Circle()
            .stroke(Theme.tileGlyph, lineWidth: 2.5)
            .frame(width: 46, height: 46)
            .scaleEffect(out ? 1.42 : 1)
            .opacity(out ? 0 : 0.75)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(delay)
                ) {
                    out = true
                }
            }
    }
}

// MARK: - Tile

/// A circular menu tile. Premium tiles wear a blush ring and a star.
private struct MenuTile: View {
    let title: String
    let asset: String
    var premium = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(premium ? Theme.roseBadgeBg : Theme.peach)
                    .frame(width: 62, height: 62)
                    .overlay {
                        Circle().strokeBorder(
                            premium ? Theme.roseBadgeBorder : .white,
                            lineWidth: premium ? 2.5 : 3
                        )
                    }
                    .overlay {
                        Image(asset)
                            .renderingMode(.original)
                            .resizable().scaledToFit()
                            .frame(width: 34, height: 34)
                    }
                    .shadow(
                        color: premium ? Color(hex: 0xB46E82).opacity(0.18) : Color(hex: 0x7A6248).opacity(0.13),
                        radius: 7, y: 5
                    )
                if premium {
                    Image("icon-star-white")
                        .renderingMode(.original)
                        .resizable().scaledToFit()
                        .frame(width: 10, height: 10)
                        .frame(width: 18, height: 18)
                        .background(Theme.roseStrong, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.canvas, lineWidth: 2))
                        .offset(x: 3, y: -3)
                }
            }
            Text(title)
                .font(.nunito(12, .bold))
                .foregroundStyle(premium ? Color(hex: 0x9A6472) : Theme.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Notifications

struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Notifications")
                    .font(.baloo(17, heavy: true))
                    .foregroundStyle(Theme.ink)
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Text("Done")
                            .font(.nunito(13, .heavy))
                            .foregroundStyle(Theme.roseText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.rosePillBg, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 0) {
                Image("bell-amber")
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 34, height: 36)
                    .frame(width: 86, height: 86)
                    .background(Theme.peach, in: Circle())
                Text("You're all caught up")
                    .font(.baloo(21, heavy: true))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 16)
                Text("Reminders and gentle nudges will show up here.")
                    .font(.nunito(14, .semibold))
                    .lineSpacing(5)
                    .foregroundStyle(Theme.inkFaint)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas)
        .presentationBackground(Theme.canvas)
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

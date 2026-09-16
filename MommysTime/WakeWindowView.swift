import SwiftUI
import CoreData

/// The two states a `SleepEntry` can record. Persisted, so never translated.
enum SleepEntryKind {
    static let sleep = "sleep"
    static let awake = "awake"
}

/// Awake or asleep in one tap. The hero counts the current stretch, every
/// switch is written to the sleep log, and the chart button opens the summary.
struct WakeWindowView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SleepEntry.start, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<SleepEntry>

    @AppStorage(SettingsKeys.babyAsleep) private var asleep = false
    @AppStorage(SettingsKeys.babyStateSince) private var sinceStamp = 0.0

    /// The stretch is re-read on a slow tick — a minute either way doesn't
    /// matter and a per-second timer would spin the whole screen.
    @State private var now = Date()
    @State private var toast: String?

    private let tick = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    /// The wake window a baby this age is usually good for.
    static let suggestedWindow = 105

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroCard

                    SectionLabel(L.Wake.todaySoFar)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    todayCard
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(tick) { now = $0 }
        .onAppear { if sinceStamp == 0 { sinceStamp = Date().timeIntervalSinceReferenceDate } }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        DetailHeader(title: L.Wake.title, onBack: { dismiss() }) {
            NavigationLink {
                SleepSummaryView()
            } label: {
                Image("icon-chart")
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Theme.tileGlyph)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
                    .shadow(color: Color(hex: 0x7A6248).opacity(0.14), radius: 6, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: Hero

    private var since: Date {
        sinceStamp == 0 ? now : Date(timeIntervalSinceReferenceDate: sinceStamp)
    }

    private var elapsed: Int { max(0, Int(now.timeIntervalSince(since) / 60)) }

    private var pastWindow: Bool { !asleep && elapsed > Self.suggestedWindow }

    private var heroCard: some View {
        VStack(spacing: 0) {
            Image(asleep ? "icon-moon" : "icon-sun")
                .renderingMode(.template)
                .resizable().scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(asleep ? .white : Theme.tileGlyph)
                .frame(width: 52, height: 52)
                .background(asleep ? Color.white.opacity(0.2) : Color.white, in: Circle())

            Text(asleep ? L.Wake.sleeping : L.Wake.awake)
                .font(.baloo(22, heavy: true))
                .foregroundStyle(asleep ? .white : Theme.roseInk)
                .padding(.top, 10)

            Text(SleepFormat.span(elapsed))
                .font(.baloo(40, heavy: true))
                .foregroundStyle(asleep ? .white : Theme.roseInk)
                .padding(.top, 6)

            Text(subtitle)
                .font(.nunito(12.5, .bold))
                .foregroundStyle(subtitleColour)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            Button(action: toggle) {
                Text(asleep ? L.Wake.wokeUp : L.Wake.fellAsleep)
                    .font(.baloo(16, heavy: true))
                    .foregroundStyle(asleep ? Theme.plum : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(asleep ? Color.white : Theme.tileGlyph, in: Capsule())
                    .shadow(color: Color(hex: 0x78465F).opacity(0.28), radius: 9, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .background(asleep ? Theme.plum : Theme.rosePillBg,
                    in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(asleep ? Theme.plumDeep : Theme.heroBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x78465F).opacity(asleep ? 0.3 : 0.14), radius: 12, y: 10)
        .animation(.easeInOut(duration: 0.25), value: asleep)
    }

    private var subtitle: String {
        if asleep { return L.Wake.asleepSince(since.formatted(.dateTime.hour().minute())) }
        if pastWindow {
            return L.Wake.pastWindow(SleepFormat.span(Self.suggestedWindow))
        }
        return L.Wake.windowLeft(SleepFormat.span(max(0, Self.suggestedWindow - elapsed)))
    }

    private var subtitleColour: Color {
        if asleep { return .white.opacity(0.85) }
        return pastWindow ? Theme.roseDeep : Theme.roseMuted
    }

    /// Closes the stretch that just ended, writes it to the log, and starts the
    /// opposite one from this moment.
    private func toggle() {
        let stamp = Date()
        if stamp > since, Calendar.current.isDate(stamp, inSameDayAs: since) {
            let entry = SleepEntry(context: context)
            entry.id = UUID()
            entry.kind = asleep ? SleepEntryKind.sleep : SleepEntryKind.awake
            entry.start = since
            entry.end = stamp
            entry.createdAt = stamp
            try? context.save()
        }
        let wasAsleep = asleep
        asleep.toggle()
        sinceStamp = stamp.timeIntervalSinceReferenceDate
        now = stamp
        show(wasAsleep ? L.Wake.toastAwake : L.Wake.toastAsleep)
    }

    private func show(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { if toast == message { toast = nil } }
        }
    }

    // MARK: Today so far

    private var today: [SleepEntry] {
        entries.filter { Calendar.current.isDateInToday($0.start ?? .distantPast) }
    }

    private var todayCard: some View {
        VStack(spacing: 0) {
            if today.isEmpty {
                Text(L.Wake.nothingToday)
                    .font(.nunito(13, .bold))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(today.enumerated()), id: \.element.objectID) { index, entry in
                    if index > 0 { CardDivider() }
                    row(entry)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    private func row(_ entry: SleepEntry) -> some View {
        let sleeping = entry.kind == SleepEntryKind.sleep
        let start = entry.start ?? Date()
        let end = entry.end ?? start
        return HStack(spacing: 11) {
            Circle()
                .fill(sleeping ? Theme.plum : Theme.awakeDot)
                .frame(width: 9, height: 9)
            Text(L.Wake.row(
                kind: sleeping ? L.Wake.slept : L.Wake.awakeRow,
                start: start.formatted(.dateTime.hour().minute()),
                end: end.formatted(.dateTime.hour().minute())
            ))
                .font(.nunito(13.5, .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(SleepFormat.span(Int(end.timeIntervalSince(start) / 60)))
                .font(.nunito(13, .heavy))
                .foregroundStyle(Theme.roseAccentText)
        }
        .padding(.vertical, 13)
    }
}

// MARK: - Sleep summary

/// The shape of the day: totals, a 6am-to-midnight strip and the week in bars.
struct SleepSummaryView: View {
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SleepEntry.start, ascending: true)],
        animation: .default
    )
    private var entries: FetchedResults<SleepEntry>

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            DetailHeader(title: L.Sleep.summaryTitle, onBack: { dismiss() })
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    statRow((SleepFormat.span(sleepMinutes), L.Sleep.sleptToday),
                            ("\(naps.count)", L.Sleep.napsToday))
                    statRow((averageWindow.map(SleepFormat.span) ?? L.Common.none, L.Sleep.averageWindow),
                            (longestNap.map(SleepFormat.span) ?? L.Common.none, L.Sleep.longestNap))
                        .padding(.top, 9)

                    caption(L.Sleep.shapeTitle, L.Sleep.shapeSub)
                        .padding(.top, 18)
                    dayStripCard.padding(.top, 12)

                    caption(L.Sleep.weekTitle, L.Sleep.weekSub)
                        .padding(.top, 18)
                    weekCard.padding(.top, 12)

                    Text(insight)
                        .font(.nunito(12.5, .bold))
                        .lineSpacing(6)
                        .foregroundStyle(Theme.plumText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Theme.roseTint, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .padding(.top, 14)
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Stats

    private var naps: [SleepEntry] {
        entries.filter { $0.kind == SleepEntryKind.sleep && calendar.isDateInToday($0.start ?? .distantPast) }
            .sorted { ($0.start ?? .distantPast) < ($1.start ?? .distantPast) }
    }

    private var sleepMinutes: Int { naps.reduce(0) { $0 + $1.minutes } }

    /// Time spent awake between one nap ending and the next beginning.
    private var wakeWindows: [Int] {
        zip(naps, naps.dropFirst()).compactMap { previous, next in
            guard let end = previous.end, let start = next.start else { return nil }
            return max(0, Int(start.timeIntervalSince(end) / 60))
        }
    }

    private var averageWindow: Int? {
        wakeWindows.isEmpty ? nil : wakeWindows.reduce(0, +) / wakeWindows.count
    }

    private var longestNap: Int? { naps.map(\.minutes).max() }

    private func statRow(_ left: (String, String), _ right: (String, String)) -> some View {
        HStack(spacing: 9) {
            statCard(left.0, left.1)
            statCard(right.0, right.1)
        }
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.baloo(22, heavy: true))
                .foregroundStyle(Theme.tileGlyph)
            Text(label)
                .font(.nunito(11.5, .bold))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 8, y: 4)
    }

    private func caption(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.baloo(19, heavy: true))
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(.nunito(12.5, .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 2)
    }

    // MARK: Day strip

    /// Today's naps clipped to the 6am–midnight window, as (fraction, isSleep).
    private var segments: [(width: Double, sleep: Bool)] {
        let dayStart = calendar.startOfDay(for: Date())
        let from = dayStart.addingTimeInterval(6 * 3600)
        let to = dayStart.addingTimeInterval(24 * 3600)
        let span = to.timeIntervalSince(from)

        var result: [(Double, Bool)] = []
        var cursor = from
        for nap in naps {
            guard let start = nap.start, let end = nap.end else { continue }
            let a = max(from, start), b = min(to, end)
            guard b > a else { continue }
            if a > cursor { result.append((a.timeIntervalSince(cursor) / span, false)) }
            result.append((b.timeIntervalSince(a) / span, true))
            cursor = b
        }
        if cursor < to { result.append((to.timeIntervalSince(cursor) / span, false)) }
        return result
    }

    private var dayStripCard: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        Rectangle()
                            .fill(segment.sleep ? Theme.plum : Color.clear)
                            .frame(width: geo.size.width * segment.width)
                    }
                }
            }
            .frame(height: 38)
            .background(Theme.peach)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack {
                ForEach(Array(L.Sleep.stripTicks.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.nunito(9.5, .heavy))
                        .foregroundStyle(Theme.inkWhisper)
                    if index < L.Sleep.stripTicks.count - 1 { Spacer() }
                }
            }
            .padding(.top, 7)
        }
        .padding(.horizontal, 15)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 8, y: 4)
    }

    // MARK: Week

    /// Sleep minutes for each of the last seven days, oldest first.
    private var week: [(day: Date, minutes: Int)] {
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let minutes = entries
                .filter { $0.kind == SleepEntryKind.sleep && calendar.isDate($0.start ?? .distantPast, inSameDayAs: day) }
                .reduce(0) { $0 + $1.minutes }
            return (day, minutes)
        }
    }

    private var weekCard: some View {
        let peak = max(week.map(\.minutes).max() ?? 0, 60)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(week, id: \.day) { entry in
                let isToday = calendar.isDateInToday(entry.day)
                VStack(spacing: 5) {
                    Spacer(minLength: 0)
                    Text(entry.minutes == 0 ? "" : SleepFormat.hours(entry.minutes))
                        .font(.nunito(9.5, .heavy))
                        .foregroundStyle(Theme.inkMuted)
                    UnevenRoundedRectangle(
                        topLeadingRadius: 8, bottomLeadingRadius: 4,
                        bottomTrailingRadius: 4, topTrailingRadius: 8,
                        style: .continuous
                    )
                    .fill(entry.minutes == 0 ? Theme.chartEmptyBar : (isToday ? Theme.plum : Theme.plumSoft))
                    .frame(height: max(4, CGFloat(entry.minutes) / CGFloat(peak) * 108))
                    Text(isToday ? L.Common.today : entry.day.formatted(.dateTime.day()))
                        .font(.nunito(10, .heavy))
                        .foregroundStyle(isToday ? Theme.plum : Theme.inkWhisper)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 150)
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 8, y: 4)
    }

    private var insight: String {
        guard !naps.isEmpty else { return L.Sleep.insightEmpty }
        let average = SleepFormat.span(sleepMinutes / naps.count)
        let window = SleepFormat.span(averageWindow ?? WakeWindowView.suggestedWindow)
        return L.Sleep.insight(average: average, window: window)
    }
}

// MARK: - Formatting

enum SleepFormat {
    /// "55m" under the hour, "1h 25m" over it — the hero and row lengths.
    static func span(_ minutes: Int) -> String {
        let m = max(0, minutes)
        guard m >= 60 else { return L.Sleep.spanMinutes(m) }
        return L.Sleep.spanHoursMinutes(m / 60, m % 60)
    }

    /// "3.5h" — the compact value above a weekly bar.
    static func hours(_ minutes: Int) -> String {
        let tenths = (Double(minutes) / 6).rounded() / 10
        return L.Sleep.hoursDecimal("\(tenths)")
    }
}

extension SleepEntry {
    var minutes: Int {
        guard let start, let end else { return 0 }
        return max(0, Int(end.timeIntervalSince(start) / 60))
    }
}

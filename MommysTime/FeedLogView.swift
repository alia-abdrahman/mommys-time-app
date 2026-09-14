import SwiftUI
import CoreData

enum FeedType {
    static let all = ["Breast", "Bottle", "Solid"]
}

struct FeedLogView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedSession.date, ascending: false)],
        animation: .default
    )
    private var feeds: FetchedResults<FeedSession>

    @State private var showingAdd = false
    @State private var editing: FeedSession?
    @State private var toast: String?

    private var todayFeeds: [FeedSession] {
        feeds.filter { Calendar.current.isDateInToday($0.date ?? .distantPast) }
    }

    @AppStorage(SettingsKeys.feedIntervalHours) private var intervalHours = 3

    /// ml today sums bottle volumes only — breast/solid contribute 0.
    private var todayML: Int {
        todayFeeds.filter { $0.type == "Bottle" }.reduce(0) { $0 + Int($1.amountML) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroCard
                    statsCard.padding(.top, 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("How feeding is going")
                            .font(.baloo(19, heavy: true))
                            .foregroundStyle(Theme.ink)
                        Text("A week at a glance — fed is fed.")
                            .font(.nunito(12.5, .semibold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 2)

                    WeeklyBarChart(title: "ML FED · LAST 7 DAYS", values: weekVolumes, tint: FL.greenAccent)
                        .padding(.top, 14)
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FL.screenBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { FeedSheet { showToast($0) } }
        .sheet(item: $editing) { feed in FeedSheet(feed: feed) }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }

    private var header: some View {
        DetailHeader(title: "Feed Log") { dismiss() }
            .padding(.top, 8)
    }

    private var heroCard: some View {
        VStack(spacing: 0) {
            Image("feed-log")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(FL.greenAccent)
                .frame(width: 46, height: 46)
                .background(.white, in: Circle())
                .padding(.bottom, 10)

            Text(feeds.first?.date.map { "Last feed \(relative($0))" } ?? "No feeds logged yet")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(FL.greenDeep)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Text("Feed every")
                    .font(.nunito(13, .bold))
                    .foregroundStyle(FL.greenMid)
                Menu {
                    ForEach(1...6, id: \.self) { hours in
                        Button("\(hours) hour\(hours == 1 ? "" : "s")") { intervalHours = hours }
                    }
                } label: {
                    Text("\(intervalHours)h")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(Theme.roseAccentText)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 9)
                        .background(.white, in: Capsule())
                }
            }
            .padding(.top, 4)

            Button { showingAdd = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    Text("Log a feed").font(.baloo(16))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(FL.greenAccent, in: Capsule())
                .shadow(color: FL.greenAccent.opacity(0.35), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(FL.greenFill, in: RoundedRectangle(cornerRadius: 28))
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            // Tapping the count opens the day-by-day history.
            NavigationLink {
                LogHistoryView(
                    title: "Feed History",
                    entries: historyRows,
                    summary: daySummary,
                    onSelect: { id in editing = feeds.first { $0.objectID == id } },
                    onDelete: { id in feeds.first { $0.objectID == id }.map(delete) }
                )
            } label: {
                statColumn(value: "\(todayFeeds.count)", label: "feeds today", linked: true)
            }
            .buttonStyle(.plain)
            Rectangle().fill(FL.divider).frame(width: 1)
            statColumn(value: "\(todayML)", label: "ml today")
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func statColumn(value: String, label: String, linked: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.baloo(22, heavy: true)).foregroundStyle(FL.greenAccent)
            HStack(spacing: 5) {
                Text(label).font(.nunito(11.5, .bold)).foregroundStyle(FL.textMuted)
                if linked {
                    Image("icon-history")
                        .renderingMode(.original)
                        .resizable().scaledToFit()
                        .frame(width: 13, height: 13)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    /// Bottle millilitres per day for the last seven days, oldest first.
    private var weekVolumes: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            return feeds
                .filter { calendar.isDate($0.date ?? .distantPast, inSameDayAs: day) }
                .reduce(0) { $0 + Int($1.amountML) }
        }
    }

    private var historyRows: [HistoryRow] {
        feeds.map { feed in
            HistoryRow(
                id: feed.objectID,
                time: feed.date ?? .distantPast,
                title: feed.type ?? "Feed",
                detail: detailLabel(feed)
            )
        }
    }

    /// Bottles read in ml, breast feeds in minutes and side, solids in grams.
    private func detailLabel(_ feed: FeedSession) -> String {
        if feed.amountML > 0 { return "\(feed.amountML) ml" }
        if feed.durationMinutes > 0 {
            let side = feed.side ?? ""
            let mins = "\(feed.durationMinutes) min"
            return side.isEmpty ? mins : "\(mins) · \(side)"
        }
        return "—"
    }

    private func daySummary(_ day: Date) -> String {
        let list = feeds.filter { Calendar.current.isDate($0.date ?? .distantPast, inSameDayAs: day) }
        guard !list.isEmpty else { return "no entries" }
        let ml = list.reduce(0) { $0 + Int($1.amountML) }
        let count = "\(list.count) \(list.count == 1 ? "FEED" : "FEEDS")"
        return ml > 0 ? "\(count) · \(ml) ML" : count
    }

    private func delete(_ feed: FeedSession) {
        context.delete(feed)
        try? context.save()
    }

    private func relative(_ date: Date) -> String {
        let minutes = max(0, Int(Date().timeIntervalSince(date) / 60))
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        let rem = minutes % 60
        return rem == 0 ? "\(hours)h ago" : "\(hours)h \(rem)m ago"
    }
}

// MARK: - Feed log palette

private enum FL {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    // The design's rose scale — these kept their old `green*` names so every
    // call site below stays put.
    static let greenFill = Color(hex: 0xF6E6E9)
    static let greenRow = Color(hex: 0xF9EDEF)
    static let greenDeep = Color(hex: 0x7E3B50)
    static let greenMid = Color(hex: 0xB0899A)
    static let greenAccent = Color(hex: 0xD9758C)
    static let divider = Color(hex: 0x7A6248).opacity(0.12)
    static let backIcon = Color(hex: 0x8B7F72)
}

struct FeedSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let feed: FeedSession?
    var onLogged: (String) -> Void = { _ in }

    @State private var type: String
    @State private var date: Date
    @State private var amount: Int      // bottle ml / solid g
    @State private var duration: Int    // breast minutes
    @State private var side: String
    @State private var finished: Bool

    init(feed: FeedSession? = nil, onLogged: @escaping (String) -> Void = { _ in }) {
        self.feed = feed
        self.onLogged = onLogged
        _type = State(initialValue: feed?.type ?? "Bottle")
        _date = State(initialValue: feed?.date ?? Date())
        _amount = State(initialValue: Int(feed?.amountML ?? 120))
        _duration = State(initialValue: Int(feed?.durationMinutes ?? 20))
        _side = State(initialValue: feed?.side ?? "Both")
        _finished = State(initialValue: feed?.finished ?? true)
    }

    private var isEditing: Bool { feed != nil }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                sectionLabel("FEED TYPE").padding(.top, 20).padding(.bottom, 8)
                segments(options: FeedType.all, selection: type) { type = $0 }

                metricHero.padding(.top, 16)

                if type == "Breast" {
                    sectionLabel("SIDE").padding(.top, 20).padding(.bottom, 8)
                    segments(options: ["Left", "Right", "Both"], selection: side) { side = $0 }
                }

                sectionLabel("DETAILS").padding(.top, 20).padding(.bottom, 8)
                detailsCard

                footerNote.padding(.top, 14)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(LF.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(LF.sheetBg)
        .presentationDragIndicator(.hidden)
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit Feed" : "Log Feed")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(LF.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(LF.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(.white)
                        .padding(.vertical, 8).padding(.horizontal, 18)
                        .background(LF.accentRose, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(LF.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func segments(options: [String], selection: String, onSelect: @escaping (String) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { opt in
                let sel = opt == selection
                Button { onSelect(opt) } label: {
                    Text(opt)
                        .font(.nunito(13.5, .heavy))
                        .foregroundStyle(sel ? .white : LF.greenText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(sel ? LF.greenAccent : LF.greenFill, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Metric hero

    private var metricEyebrow: String {
        switch type {
        case "Breast": return "Time at the breast"
        case "Solid": return "Portion offered"
        default: return "Bottle volume"
        }
    }
    private var metricUnit: String {
        switch type {
        case "Breast": return "min"
        case "Solid": return "g"
        default: return "ml"
        }
    }
    private var metricValue: Int { type == "Breast" ? duration : amount }
    private var stepCaption: String {
        switch type {
        case "Breast": return "5 min steps"
        case "Solid": return "10 g steps"
        default: return "10 ml steps"
        }
    }

    private func stepMetric(_ delta: Int) {
        if type == "Breast" {
            duration = min(90, max(5, duration + delta * 5))
        } else {
            amount = min(500, max(0, amount + delta * 10))
        }
    }

    private var metricHero: some View {
        VStack(spacing: 0) {
            Text(metricEyebrow)
                .font(.nunito(12, .bold))
                .foregroundStyle(LF.greenMid)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(metricValue)")
                    .font(.baloo(42, heavy: true))
                    .foregroundStyle(LF.greenDeep)
                Text(metricUnit)
                    .font(.baloo(17, heavy: true))
                    .foregroundStyle(LF.greenMid)
            }
            .padding(.top, 4)
            HStack(spacing: 10) {
                Button { stepMetric(-1) } label: {
                    Text("−").font(.nunito(20, .heavy)).foregroundStyle(LF.greenMid)
                        .frame(width: 46, height: 46).background(.white, in: Circle())
                        .shadow(color: Color(hex: 0xBE5F78).opacity(0.12), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                Text(stepCaption)
                    .font(.nunito(12, .bold)).foregroundStyle(LF.greenMid).frame(minWidth: 46)
                Button { stepMetric(1) } label: {
                    Text("+").font(.nunito(20, .heavy)).foregroundStyle(.white)
                        .frame(width: 46, height: 46).background(LF.greenAccent, in: Circle())
                        .shadow(color: LF.greenAccent.opacity(0.35), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(LF.greenFill, in: RoundedRectangle(cornerRadius: 28))
    }

    // MARK: Details card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Time").font(.nunito(15, .bold)).foregroundStyle(LF.textPrimary)
                Spacer()
                HStack(spacing: 0) {
                    Button { date = date.addingTimeInterval(-15 * 60) } label: {
                        Text("−").font(.nunito(16, .heavy)).foregroundStyle(LF.textSecondary).frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                    Text(date.formatted(.dateTime.hour().minute()))
                        .font(.nunito(13, .heavy)).foregroundStyle(LF.valueText).frame(minWidth: 84)
                    Button { date = date.addingTimeInterval(15 * 60) } label: {
                        Text("+").font(.nunito(16, .heavy)).foregroundStyle(LF.greenAccent).frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .background(LF.fieldFill, in: Capsule())
            }
            .padding(.vertical, 12)

            Rectangle().fill(Color(hex: 0x7A6248).opacity(0.1)).frame(height: 1)

            HStack {
                Text("Baby finished the feed").font(.nunito(15, .bold)).foregroundStyle(LF.textPrimary)
                Spacer()
                Button { finished.toggle() } label: {
                    ZStack(alignment: finished ? .trailing : .leading) {
                        Capsule().fill(finished ? LF.toggleOn : LF.toggleOff).frame(width: 50, height: 30)
                        Circle().fill(.white).frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2.5, y: 2).padding(3)
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: finished)
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 18).padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    // MARK: Footer note

    private var footerNote: some View {
        Text(noteText)
            .font(.nunito(12.5, .bold)).lineSpacing(6)
            .foregroundStyle(LF.greenText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(LF.greenNote, in: RoundedRectangle(cornerRadius: 22))
    }

    private var noteText: String {
        switch type {
        case "Breast": return "Breast feeds are tracked by time and side, not volume."
        case "Solid": return "Solids are logged by portion — handy once weaning starts."
        default: return "Bottle volume counts toward today's ml total."
        }
    }

    // MARK: Save

    private func save() {
        let target = feed ?? FeedSession(context: context)
        if feed == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.type = type
        target.date = date
        target.amountML = type == "Breast" ? 0 : Int32(amount)
        target.durationMinutes = type == "Breast" ? Int32(duration) : 0
        target.side = type == "Breast" ? side : nil
        target.finished = finished
        try? context.save()
        if feed == nil { onLogged("\(type) feed logged") }
        dismiss()
    }
}

// MARK: - Log Feed palette

private enum LF {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let greenFill = Color(hex: 0xF9EDEF)
    static let greenNote = Color(hex: 0xF9EDEF)
    static let greenDeep = Color(hex: 0x7E3B50)
    static let greenMid = Color(hex: 0xB0899A)
    static let greenAccent = Color(hex: 0xD9758C)
    static let greenText = Color(hex: 0xA85F6F)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let accentRose = Color(hex: 0xD98FA0)
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = Color(hex: 0xD98FA0)
}

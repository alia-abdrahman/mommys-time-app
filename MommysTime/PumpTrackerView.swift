import SwiftUI
import CoreData

enum PumpSide {
    static let all = ["Left", "Right", "Both"]
}

struct PumpTrackerView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PumpSession.date, ascending: false)],
        animation: .default
    )
    private var sessions: FetchedResults<PumpSession>

    @AppStorage(SettingsKeys.pumpIntervalHours) private var intervalHours = 3

    @State private var showingLog = false
    @State private var editing: PumpSession?
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroCard
                    statsCard.padding(.top, 10)

                    if !sessions.isEmpty {
                        Text("HISTORY")
                            .font(.nunito(12, .heavy))
                            .tracking(0.8)
                            .foregroundStyle(PT.textMuted)
                            .padding(.top, 12)
                            .padding(.bottom, 7)
                        VStack(spacing: 7) {
                            ForEach(sessions, id: \.objectID) { session in
                                PumpSessionRow(session: session) { editing = session }
                                    .contextMenu {
                                        Button("Edit") { editing = session }
                                        Button("Delete", role: .destructive) { delete(session) }
                                    }
                            }
                        }
                    }
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)
                .padding(.bottom, 96)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PT.screenBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingLog) {
            PumpSessionSheet { showToast($0) }
        }
        .sheet(item: $editing) { session in
            PumpSessionSheet(session: session)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 190)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("Pump Tracker")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(PT.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(PT.backIcon)
                        .frame(width: 38, height: 38)
                        .background(.white, in: Circle())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: Hero card

    private var heroCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "drop.fill")
                .font(.system(size: 19))
                .foregroundStyle(PT.blueAccent)
                .frame(width: 38, height: 38)
                .background(.white, in: Circle())
                .padding(.bottom, 8)

            Text(statusText)
                .font(.baloo(20, heavy: true))
                .foregroundStyle(PT.blueDeep)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Text("Pump every")
                    .font(.nunito(13, .bold))
                    .foregroundStyle(PT.blueMid)
                Menu {
                    ForEach(1...6, id: \.self) { hours in
                        Button("\(hours) hour\(hours == 1 ? "" : "s")") { intervalHours = hours }
                    }
                } label: {
                    Text("\(intervalHours)h")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(PT.bluePill)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 9)
                        .background(.white, in: Capsule())
                }
            }
            .padding(.top, 4)

            Button { showingLog = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    Text("Log a session").font(.baloo(16))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(PT.blueAccent, in: Capsule())
                .shadow(color: PT.blueAccent.opacity(0.4), radius: 18, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(PT.blueFill, in: RoundedRectangle(cornerRadius: 28))
    }

    private var statusText: String {
        guard let next = nextSessionDate else { return "Log your first session" }
        if next <= Date() { return "Session due now" }
        return "Next in \(countdown(to: next))"
    }

    private func countdown(to date: Date) -> String {
        let minutes = max(1, Int(date.timeIntervalSinceNow / 60))
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private var nextSessionDate: Date? {
        guard let last = sessions.first?.date else { return nil }
        return last.addingTimeInterval(Double(intervalHours) * 3600)
    }

    // MARK: Stats card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(todaySessions.count)", label: "sessions today")
            Rectangle().fill(PT.divider).frame(width: 1)
            statColumn(value: "\(todayML)", label: "ml today")
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.baloo(22, heavy: true))
                .foregroundStyle(PT.blueAccent)
            Text(label)
                .font(.nunito(11.5, .bold))
                .foregroundStyle(PT.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var todaySessions: [PumpSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date ?? .distantPast) }
    }

    private var todayML: Int {
        todaySessions.reduce(0) { $0 + Int($1.amountML) }
    }

    private func delete(_ session: PumpSession) {
        context.delete(session)
        try? context.save()
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }
}

private struct PumpSessionRow: View {
    @ObservedObject var session: PumpSession
    var onTap: () -> Void

    private var detail: String {
        var parts = ["\(session.durationMinutes) min"]
        if session.amountML > 0 { parts.append("\(session.amountML) ml") }
        if let side = session.side, !side.isEmpty { parts.append(side) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 13))
                .foregroundStyle(PT.blueAccent)
                .frame(width: 30, height: 30)
                .background(.white, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text((session.date ?? Date()).formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                    .font(.nunito(14.5, .heavy))
                    .foregroundStyle(PT.textPrimary)
                Text(detail)
                    .font(.nunito(12, .semibold))
                    .foregroundStyle(PT.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PT.blueRow, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Pump tracker palette

private enum PT {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let blueFill = Color(hex: 0xE2EDF3)
    static let blueRow = Color(hex: 0xE9F1F6)
    static let blueDeep = Color(hex: 0x3E566A)
    static let blueMid = Color(hex: 0x7B93A5)
    static let blueAccent = Color(hex: 0x6D91AB)
    static let bluePill = Color(hex: 0x4E7488)
    static let divider = Color(hex: 0x7A6248).opacity(0.12)
    static let backIcon = Color(hex: 0x8B7F72)
}

struct PumpSessionSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.pumpIntervalHours) private var intervalHours = 3

    let session: PumpSession?
    var onLogged: (String) -> Void = { _ in }

    @State private var date: Date
    @State private var duration: Int
    @State private var amount: Int
    @State private var side: String
    @State private var addToFeed = false

    init(session: PumpSession? = nil, onLogged: @escaping (String) -> Void = { _ in }) {
        self.session = session
        self.onLogged = onLogged
        _date = State(initialValue: session?.date ?? Date())
        _duration = State(initialValue: Int(session?.durationMinutes ?? 20))
        _amount = State(initialValue: Int(session?.amountML ?? 110))
        _side = State(initialValue: session?.side ?? "Both")
    }

    private var isEditing: Bool { session != nil }
    private var canSave: Bool { duration > 0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                volumeHero.padding(.top, 20)
                sectionLabel("SIDE").padding(.top, 20).padding(.bottom, 8)
                sideSegments
                sectionLabel("DETAILS").padding(.top, 20).padding(.bottom, 8)
                detailsCard
                footerNote.padding(.top, 14)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(LS.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(LS.sheetBg)
        .presentationDragIndicator(.hidden)
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit Session" : "Log Session")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(LS.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(LS.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : LS.disabledText)
                        .padding(.vertical, 8).padding(.horizontal, 18)
                        .background(canSave ? LS.accentRose : LS.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
    }

    // MARK: Volume hero

    private var volumeHero: some View {
        VStack(spacing: 0) {
            Text("Volume expressed")
                .font(.nunito(12, .bold))
                .foregroundStyle(LS.blueMid)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(amount)")
                    .font(.baloo(42, heavy: true))
                    .foregroundStyle(LS.blueDeep)
                Text("ml")
                    .font(.baloo(17, heavy: true))
                    .foregroundStyle(LS.blueMid)
            }
            .padding(.top, 4)
            HStack(spacing: 10) {
                Button { amount = max(0, amount - 10) } label: {
                    Text("−").font(.nunito(20, .heavy)).foregroundStyle(LS.blueMid)
                        .frame(width: 46, height: 46).background(.white, in: Circle())
                        .shadow(color: Color(hex: 0x3E566A).opacity(0.12), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                VStack(spacing: 0) {
                    Text("10 ml"); Text("steps")
                }
                .font(.nunito(12, .bold)).foregroundStyle(LS.blueMid).frame(minWidth: 46)
                Button { amount = min(500, amount + 10) } label: {
                    Text("+").font(.nunito(20, .heavy)).foregroundStyle(.white)
                        .frame(width: 46, height: 46).background(LS.blueAccent, in: Circle())
                        .shadow(color: LS.blueAccent.opacity(0.4), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(LS.blueFill, in: RoundedRectangle(cornerRadius: 28))
    }

    // MARK: Side

    private var sideSegments: some View {
        HStack(spacing: 8) {
            ForEach(PumpSide.all, id: \.self) { seg in
                let sel = seg == side
                Button { side = seg } label: {
                    Text(seg)
                        .font(.nunito(13.5, .heavy))
                        .foregroundStyle(sel ? .white : LS.bluePill)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(sel ? LS.blueAccent : LS.blueFill, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(LS.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Details card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Started").font(.nunito(15, .bold)).foregroundStyle(LS.textPrimary)
                Spacer()
                stepper(value: date.formatted(.dateTime.hour().minute()),
                        onMinus: { date = date.addingTimeInterval(-15 * 60) },
                        onPlus: { date = date.addingTimeInterval(15 * 60) })
            }
            .padding(.vertical, 12)

            rowDivider

            HStack {
                Text("Duration").font(.nunito(15, .bold)).foregroundStyle(LS.textPrimary)
                Spacer()
                stepper(value: durationLabel(duration),
                        onMinus: { duration = max(5, duration - 5) },
                        onPlus: { duration = min(90, duration + 5) })
            }
            .padding(.vertical, 12)

            rowDivider

            HStack {
                Text("Add to feed log too").font(.nunito(15, .bold)).foregroundStyle(LS.textPrimary)
                Spacer()
                Button { addToFeed.toggle() } label: {
                    ZStack(alignment: addToFeed ? .trailing : .leading) {
                        Capsule().fill(addToFeed ? LS.toggleOn : LS.toggleOff).frame(width: 50, height: 30)
                        Circle().fill(.white).frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2.5, y: 2).padding(3)
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: addToFeed)
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 18).padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func stepper(value: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Button(action: onMinus) {
                Text("−").font(.nunito(16, .heavy)).foregroundStyle(LS.textSecondary).frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
            Text(value).font(.nunito(13, .heavy)).foregroundStyle(LS.valueText).frame(minWidth: 84)
            Button(action: onPlus) {
                Text("+").font(.nunito(16, .heavy)).foregroundStyle(LS.blueAccent).frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(LS.fieldFill, in: Capsule())
    }

    private var rowDivider: some View {
        Rectangle().fill(Color(hex: 0x7A6248).opacity(0.1)).frame(height: 1)
    }

    // MARK: Footer note

    private var footerNote: some View {
        Text(noteText)
            .font(.nunito(12.5, .bold)).lineSpacing(6)
            .foregroundStyle(LS.bluePill)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(LS.blueNote, in: RoundedRectangle(cornerRadius: 22))
    }

    private var noteText: String {
        if amount <= 0 {
            return "Logging a dry session is fine — it still counts toward your rhythm."
        }
        let nextDue = date.addingTimeInterval(Double(intervalHours) * 3600)
            .formatted(.dateTime.hour().minute())
        return "That's \(amount) ml in \(durationLabel(duration)). Next session due around \(nextDue)."
    }

    private func durationLabel(_ m: Int) -> String {
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }

    // MARK: Save

    private func save() {
        guard canSave else { return }
        let isNew = session == nil
        let target = session ?? PumpSession(context: context)
        if isNew {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.date = date
        target.durationMinutes = Int32(duration)
        target.amountML = Int32(amount)
        target.side = side

        if isNew && addToFeed {
            let feed = FeedSession(context: context)
            feed.id = UUID()
            feed.createdAt = Date()
            feed.date = date
            feed.type = "Bottle"
            feed.amountML = Int32(amount)
            feed.notes = "pumped"
        }

        try? context.save()
        if isNew {
            onLogged(addToFeed ? "Session logged and added to feeds" : "Pump session logged")
        }
        dismiss()
    }
}

// MARK: - Log Session palette

private enum LS {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let blueFill = Color(hex: 0xE2EDF3)
    static let blueNote = Color(hex: 0xE9F1F6)
    static let blueDeep = Color(hex: 0x3E566A)
    static let blueMid = Color(hex: 0x7B93A5)
    static let blueAccent = Color(hex: 0x6D91AB)
    static let bluePill = Color(hex: 0x4E7488)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let accentRose = Color(hex: 0xD98FA0)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = Color(hex: 0x7FBFAE)
}

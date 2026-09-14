import SwiftUI
import CoreData

struct GrowthLogView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GrowthEntry.date, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<GrowthEntry>

    @State private var showingAdd = false
    @State private var editing: GrowthEntry?
    @State private var metric = "Weight"
    @State private var toast: String?

    private let metrics = ["Weight", "Height", "Head"]
    private var latest: GrowthEntry? { entries.first }
    /// Oldest → newest (birth is entry 0).
    private var chrono: [GrowthEntry] { Array(entries).reversed() }

    var body: some View {
        VStack(spacing: 0) {
            header
            if entries.isEmpty {
                emptyState
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        heroCard
                        statsCard.padding(.top, 10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("How baby is growing")
                                .font(.baloo(19, heavy: true))
                                .foregroundStyle(Theme.ink)
                            Text("A visit at a time — every clinic check, plotted.")
                                .font(.nunito(12.5, .semibold))
                                .foregroundStyle(Theme.inkFaint)
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 2)

                        TrendLineChart(title: "WEIGHT · LAST 30 DAYS", unit: "kg",
                                       points: points { $0.weightKg })
                            .padding(.top, 14)
                        TrendLineChart(title: "HEIGHT · LAST 30 DAYS", unit: "cm",
                                       points: points { $0.heightCm })
                            .padding(.top, 14)
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 116)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GL.screenBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { GrowthSheet(previous: latest) { showToast($0) } }
        .sheet(item: $editing) { entry in GrowthSheet(entry: entry) }
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

    /// Real measurements for one field, ready for the trend chart.
    private func points(_ field: (GrowthEntry) -> Double) -> [(date: Date, value: Double)] {
        chrono.compactMap { entry in
            guard let date = entry.date else { return nil }
            let value = field(entry)
            return value > 0 ? (date, value) : nil
        }
    }

    // MARK: Header

    private var header: some View {
        DetailHeader(title: "Growth Log") { dismiss() }
            .padding(.top, 8)
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(spacing: 0) {
            Image("icon-growth-rose")
                .renderingMode(.original)
                .resizable().scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 38, height: 38)
                .background(.white, in: Circle())
                .padding(.bottom, 8)

            Text("\(fmt(latest?.weightKg ?? 0)) kg · \(fmt(latest?.heightCm ?? 0)) cm")
                .font(.baloo(20, heavy: true))
                .foregroundStyle(Theme.roseInk)

            HStack(spacing: 6) {
                Text("Measured")
                    .font(.nunito(13, .bold))
                    .foregroundStyle(Theme.roseMuted)
                Text(latest?.date?.formatted(.dateTime.day().month(.abbreviated)) ?? "—")
                    .font(.nunito(13, .heavy))
                    .foregroundStyle(Theme.roseAccentText)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 9)
                    .background(.white, in: Capsule())
            }
            .padding(.top, 4)

            PrimaryButton(title: "Add a measurement", icon: "icon-plus-white",
                          tint: Theme.tileGlyph, height: 50) {
                showingAdd = true
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(Theme.rosePillBg, in: RoundedRectangle(cornerRadius: 28))
    }

    // MARK: Stats

    private var statsCard: some View {
        NavigationLink {
            GrowthHistoryView(entries: Array(entries))
        } label: {
            HStack(spacing: 0) {
                statColumn(fmt(latest?.weightKg ?? 0), "weight (kg)", linked: true)
                Rectangle().fill(GL.divider).frame(width: 1)
                statColumn(fmt(latest?.heightCm ?? 0), "height (cm)")
                Rectangle().fill(GL.divider).frame(width: 1)
                statColumn(fmt(latest?.headCm ?? 0), "head (cm)")
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func statColumn(_ value: String, _ label: String, linked: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.baloo(22, heavy: true))
                .foregroundStyle(Theme.tileGlyph)
            HStack(spacing: 5) {
                Text(label)
                    .font(.nunito(11.5, .bold))
                    .foregroundStyle(GL.textMuted)
                if linked {
                    Image("icon-history")
                        .renderingMode(.original)
                        .resizable().scaledToFit()
                        .frame(width: 13, height: 13)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }


    // MARK: Metric helpers

    private func value(_ e: GrowthEntry) -> Double {
        switch metric {
        case "Height": return e.heightCm
        case "Head": return e.headCm
        default: return e.weightKg
        }
    }
    private var unit: String { metric == "Weight" ? "kg" : "cm" }
    private func fmt(_ v: Double) -> String { v.formatted(.number.precision(.fractionLength(0...1))) }
    private func valueLabel(_ v: Double) -> String { "\(fmt(v)) \(unit)" }

    private func ageLabel(_ entry: GrowthEntry) -> String {
        guard let birth = chrono.first?.date, let date = entry.date else { return "" }
        if entry.objectID == chrono.first?.objectID { return "Birth" }
        if Calendar.current.isDateInToday(date) { return "Today" }
        let months = Calendar.current.dateComponents([.month], from: birth, to: date).month ?? 0
        return months <= 0 ? "New" : "\(months) mo"
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No measurements yet")
                .font(.baloo(20, heavy: true))
                .foregroundStyle(GL.textPrimary)
            Text("Record your baby's weight, height and head size to watch them grow.")
                .font(.nunito(15))
                .foregroundStyle(GL.textMuted)
                .multilineTextAlignment(.center)
            Button { showingAdd = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                    Text("Add a measurement").font(.baloo(15))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22).padding(.vertical, 14)
                .background(GL.purpleAccent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Spacer(); Spacer()
        }
        .padding(.horizontal, 34)
    }

    private func delete(_ entry: GrowthEntry) {
        context.delete(entry)
        try? context.save()
    }
}

// MARK: - Growth log palette

private enum GL {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    // The design's rose scale — these kept their old `purple*` names so every
    // call site below stays put.
    static let purpleFill = Color(hex: 0xF6E6E9)
    static let purpleRow = Color(hex: 0xF9EDEF)
    static let purpleAccent = Color(hex: 0xC4788C)
    static let purpleLight = Color(hex: 0xEDC3CD)
    static let purpleMid = Color(hex: 0xB0899A)
    static let purpleText = Color(hex: 0x7E3B50)
    static let labelGrey = Color(hex: 0x8F8778)
    static let divider = Color(hex: 0x7A6248).opacity(0.12)
    static let footerText = Color(hex: 0xB0899A)
    static let backIcon = Color(hex: 0x8B7F72)
}

struct GrowthSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: GrowthEntry?
    var onSaved: (String) -> Void = { _ in }

    private let prevWeight: Double
    private let prevDate: Date?

    @State private var date: Date
    @State private var weight: Double
    @State private var height: Double
    @State private var head: Double
    @State private var metric = "Weight"
    @State private var weightToast = false

    private let metrics = ["Weight", "Height", "Head"]

    init(entry: GrowthEntry? = nil, previous: GrowthEntry? = nil, onSaved: @escaping (String) -> Void = { _ in }) {
        self.entry = entry
        self.onSaved = onSaved
        prevWeight = previous?.weightKg ?? 0
        prevDate = previous?.date
        if let entry {
            _weight = State(initialValue: entry.weightKg)
            _height = State(initialValue: entry.heightCm)
            _head = State(initialValue: entry.headCm)
            _date = State(initialValue: entry.date ?? Date())
        } else {
            _weight = State(initialValue: previous?.weightKg ?? 0)
            _height = State(initialValue: previous?.heightCm ?? 0)
            _head = State(initialValue: previous?.headCm ?? 0)
            _date = State(initialValue: Date())
        }
    }

    private var isEditing: Bool { entry != nil }
    private var canSave: Bool { weight > 0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                metricHero.padding(.top, 20)
                sectionLabel("THIS VISIT").padding(.top, 20).padding(.bottom, 8)
                visitCard
                footerNote.padding(.top, 14)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(AM.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(AM.sheetBg)
        .presentationDragIndicator(.hidden)
        .overlay(alignment: .bottom) {
            if weightToast {
                Toast(text: "Add a weight first")
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit Measurement" : "Add Measurement")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(AM.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(AM.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : AM.disabledText)
                        .padding(.vertical, 8).padding(.horizontal, 18)
                        .background(canSave ? AM.accentRose : AM.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Metric hero

    private var eyebrow: String {
        switch metric {
        case "Height": return "Height"
        case "Head": return "Head circumference"
        default: return "Weight"
        }
    }
    private var unit: String { metric == "Weight" ? "kg" : "cm" }
    private var currentValue: Double {
        switch metric { case "Height": return height; case "Head": return head; default: return weight }
    }
    private var stepCaption: String {
        switch metric {
        case "Height": return "0.5 cm steps"
        case "Head": return "0.1 cm steps"
        default: return "0.1 kg steps"
        }
    }

    private func step(_ dir: Double) {
        switch metric {
        case "Height": height = round1(max(0, height + dir * 0.5))
        case "Head": head = round1(max(0, head + dir * 0.1))
        default: weight = round1(max(0, weight + dir * 0.1))
        }
    }

    private var metricHero: some View {
        VStack(spacing: 0) {
            Text(eyebrow).font(.nunito(12, .bold)).foregroundStyle(AM.purpleMid)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(fmt(currentValue)).font(.baloo(42, heavy: true)).foregroundStyle(AM.purpleDeep)
                Text(unit).font(.baloo(17, heavy: true)).foregroundStyle(AM.purpleMid)
            }
            .padding(.top, 4)
            HStack(spacing: 10) {
                Button { step(-1) } label: {
                    Text("−").font(.nunito(20, .heavy)).foregroundStyle(AM.purpleMid)
                        .frame(width: 46, height: 46).background(.white, in: Circle())
                        .shadow(color: Color(hex: 0xC4788C).opacity(0.12), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                Text(stepCaption).font(.nunito(12, .bold)).foregroundStyle(AM.purpleMid).frame(minWidth: 52)
                Button { step(1) } label: {
                    Text("+").font(.nunito(20, .heavy)).foregroundStyle(.white)
                        .frame(width: 46, height: 46).background(AM.purpleAccent, in: Circle())
                        .shadow(color: AM.purpleAccent.opacity(0.4), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
            HStack(spacing: 6) {
                ForEach(metrics, id: \.self) { m in
                    let sel = m == metric
                    Button { metric = m } label: {
                        Text(m)
                            .font(.nunito(12.5, .heavy))
                            .foregroundStyle(sel ? .white : AM.purpleText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(sel ? AM.purpleAccent : .white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(AM.purpleFill, in: RoundedRectangle(cornerRadius: 28))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(AM.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Visit card

    private var visitCard: some View {
        VStack(spacing: 0) {
            valueRow("Weight", "\(fmt(weight)) kg"); rowDivider
            valueRow("Height", "\(fmt(height)) cm"); rowDivider
            valueRow("Head", "\(fmt(head)) cm"); rowDivider
            HStack {
                Text("Measured on").font(.nunito(15, .bold)).foregroundStyle(AM.textPrimary)
                Spacer()
                HStack(spacing: 0) {
                    Button { date = date.addingTimeInterval(-86400) } label: {
                        Text("−").font(.nunito(16, .heavy)).foregroundStyle(AM.textSecondary).frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                    Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.nunito(13, .heavy)).foregroundStyle(AM.valueText).frame(minWidth: 96)
                    Button { date = date.addingTimeInterval(86400) } label: {
                        Text("+").font(.nunito(16, .heavy)).foregroundStyle(AM.purpleAccent).frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .background(AM.fieldFill, in: Capsule())
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 18).padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func valueRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.nunito(15, .bold)).foregroundStyle(AM.textPrimary)
            Spacer()
            Text(value).font(.nunito(14, .heavy)).foregroundStyle(AM.purpleAccent)
        }
        .padding(.vertical, 13)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color(hex: 0x7A6248).opacity(0.1)).frame(height: 1)
    }

    // MARK: Footer note

    private var footerNote: some View {
        Text(noteText)
            .font(.nunito(12.5, .bold)).lineSpacing(6)
            .foregroundStyle(AM.noteText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(AM.purpleNote, in: RoundedRectangle(cornerRadius: 22))
    }

    private var noteText: String {
        if weight > prevWeight, prevWeight > 0, let d = prevDate {
            let since = d.formatted(.dateTime.day().month(.abbreviated))
            return "Up \(fmt(weight - prevWeight)) kg since \(since). Growing beautifully."
        }
        return "Fill in all three while you're at the clinic — the chart needs every visit."
    }

    // MARK: Helpers

    private func round1(_ v: Double) -> Double { (v * 10).rounded() / 10 }
    private func fmt(_ v: Double) -> String { v.formatted(.number.precision(.fractionLength(0...1))) }

    private func save() {
        guard weight > 0 else {
            withAnimation { weightToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { weightToast = false }
            }
            return
        }
        let target = entry ?? GrowthEntry(context: context)
        if entry == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.date = date
        target.weightKg = weight
        target.heightCm = height
        target.headCm = head
        try? context.save()
        if entry == nil { onSaved("Measurement saved") }
        dismiss()
    }
}

// MARK: - Add measurement palette

private enum AM {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let purpleFill = Color(hex: 0xF6E6E9)
    static let purpleNote = Color(hex: 0xF9EDEF)
    static let purpleDeep = Color(hex: 0x7E3B50)
    static let purpleMid = Color(hex: 0xB3697E)
    static let purpleAccent = Color(hex: 0xC4788C)
    static let purpleText = Color(hex: 0xA85F73)
    static let noteText = Color(hex: 0xA85F73)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let accentRose = Color(hex: 0xD98FA0)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
}

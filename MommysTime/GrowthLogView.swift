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
                        latestCard
                        ctaButton.padding(.top, 10)
                        chartCard.padding(.top, 12)

                        Text("HISTORY")
                            .font(.nunito(12, .heavy)).tracking(0.8)
                            .foregroundStyle(GL.textMuted)
                            .padding(.top, 12).padding(.bottom, 7)
                        VStack(spacing: 7) {
                            ForEach(entries, id: \.objectID) { entry in
                                GrowthRow(entry: entry, age: ageLabel(entry)) { editing = entry }
                                    .contextMenu {
                                        Button("Edit") { editing = entry }
                                        Button("Delete", role: .destructive) { delete(entry) }
                                    }
                            }
                        }
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 96)
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
                    .padding(.bottom, 190)
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

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("Growth Log")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(GL.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(GL.backIcon)
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

    // MARK: Latest card

    private var latestCard: some View {
        VStack(spacing: 0) {
            Text("Latest measurements")
                .font(.nunito(12, .bold))
                .foregroundStyle(GL.purpleMid)
            HStack(spacing: 0) {
                latestColumn(value: latest?.weightKg ?? 0, label: "Weight (kg)")
                Rectangle().fill(GL.divider).frame(width: 1)
                latestColumn(value: latest?.heightCm ?? 0, label: "Height (cm)")
                Rectangle().fill(GL.divider).frame(width: 1)
                latestColumn(value: latest?.headCm ?? 0, label: "Head (cm)")
            }
            .padding(.top, 8)
            if let date = latest?.date {
                Text("as of \(date.formatted(.dateTime.day().month().year()))")
                    .font(.nunito(11.5, .semibold))
                    .foregroundStyle(GL.footerText)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(GL.purpleFill, in: RoundedRectangle(cornerRadius: 26))
    }

    private func latestColumn(value: Double, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value > 0 ? fmt(value) : "—")
                .font(.baloo(24, heavy: true))
                .foregroundStyle(GL.purpleAccent)
            Text(label)
                .font(.nunito(11, .bold))
                .foregroundStyle(GL.labelGrey)
        }
        .frame(maxWidth: .infinity)
    }

    private var ctaButton: some View {
        Button { showingAdd = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                Text("Add a measurement").font(.baloo(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(GL.purpleAccent, in: Capsule())
            .shadow(color: GL.purpleAccent.opacity(0.35), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Chart card

    private var chartCard: some View {
        let bars = chrono.filter { value($0) > 0 }
        let values = bars.map { value($0) }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(metric) over time")
                    .font(.baloo(15, heavy: true))
                    .foregroundStyle(GL.textPrimary)
                Spacer()
                Text(trendLabel)
                    .font(.nunito(12, .bold))
                    .foregroundStyle(GL.purpleMid)
            }
            .padding(.bottom, 7)

            HStack(spacing: 6) {
                ForEach(metrics, id: \.self) { m in
                    let sel = m == metric
                    Button { metric = m } label: {
                        Text(m)
                            .font(.nunito(12.5, .heavy))
                            .foregroundStyle(sel ? .white : GL.purpleText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(sel ? GL.purpleAccent : GL.purpleRow, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 10)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(bars, id: \.objectID) { entry in
                    let isLatest = entry.objectID == bars.last?.objectID
                    VStack(spacing: 6) {
                        Text(valueLabel(value(entry)))
                            .font(.nunito(11.5, .heavy))
                            .foregroundStyle(GL.purpleAccent)
                        UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 4,
                                               bottomTrailingRadius: 4, topTrailingRadius: 12)
                            .fill(isLatest ? GL.purpleAccent : GL.purpleLight)
                            .frame(height: barHeight(value(entry), min: minV, max: maxV))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 92, alignment: .bottom)

            HStack(spacing: 8) {
                ForEach(bars, id: \.objectID) { entry in
                    Text((entry.date ?? Date()).formatted(.dateTime.day().month(.abbreviated)))
                        .font(.nunito(11, .semibold))
                        .foregroundStyle(GL.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 6)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func barHeight(_ v: Double, min: Double, max: Double) -> CGFloat {
        guard max > min else { return 74 }
        return 26 + 48 * CGFloat((v - min) / (max - min))
    }

    private var trendLabel: String {
        let bars = chrono.filter { value($0) > 0 }
        guard let first = bars.first, let last = bars.last, bars.count > 1 else { return "" }
        let diff = value(last) - value(first)
        let sign = diff >= 0 ? "+" : "−"
        return "\(sign)\(fmt(abs(diff))) \(unit) since birth"
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

private struct GrowthRow: View {
    @ObservedObject var entry: GrowthEntry
    let age: String
    var onTap: () -> Void

    private var detail: String {
        func f(_ v: Double) -> String { v.formatted(.number.precision(.fractionLength(0...1))) }
        var parts: [String] = []
        if entry.weightKg > 0 { parts.append("\(f(entry.weightKg)) kg") }
        if entry.heightCm > 0 { parts.append("\(f(entry.heightCm)) cm") }
        if entry.headCm > 0 { parts.append("head \(f(entry.headCm)) cm") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text((entry.date ?? Date()).formatted(.dateTime.day().month().year()))
                    .font(.nunito(14.5, .heavy))
                    .foregroundStyle(GL.textPrimary)
                Text(detail)
                    .font(.nunito(12, .semibold))
                    .foregroundStyle(GL.textMuted)
            }
            Spacer(minLength: 0)
            Text(age)
                .font(.nunito(12, .bold))
                .foregroundStyle(GL.purpleMid)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GL.purpleRow, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Growth log palette

private enum GL {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let purpleFill = Color(hex: 0xE7E5F4)
    static let purpleRow = Color(hex: 0xEFEDF7)
    static let purpleAccent = Color(hex: 0x7C77B5)
    static let purpleLight = Color(hex: 0xC9C5E4)
    static let purpleMid = Color(hex: 0x8A83B0)
    static let purpleText = Color(hex: 0x6B6497)
    static let labelGrey = Color(hex: 0x8F8778)
    static let divider = Color(hex: 0x7C77B5).opacity(0.25)
    static let footerText = Color(hex: 0x9A93B5)
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
                        .shadow(color: Color(hex: 0x4B4570).opacity(0.12), radius: 12, y: 4)
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
    static let purpleFill = Color(hex: 0xE7E5F4)
    static let purpleNote = Color(hex: 0xEFEDF7)
    static let purpleDeep = Color(hex: 0x4B4570)
    static let purpleMid = Color(hex: 0x8A83B0)
    static let purpleAccent = Color(hex: 0x7C77B5)
    static let purpleText = Color(hex: 0x6B6497)
    static let noteText = Color(hex: 0x5B5490)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let accentRose = Color(hex: 0xD98FA0)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
}

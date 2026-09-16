import SwiftUI

struct AddBlockSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: BlockCategory = .kids
    @State private var start: Date
    @State private var lengthMinutes = 60
    @State private var repeatsDaily = false
    @State private var repeatsUntil: Date
    @State private var showTimePicker = false
    @State private var titleToast = false

    private let day: Date
    /// Called on a successful save with the toast message to show on Schedule.
    var onSaved: (String) -> Void = { _ in }

    init(day: Date = Date(), onSaved: @escaping (String) -> Void = { _ in }) {
        self.day = day
        self.onSaved = onSaved
        let calendar = Calendar.current
        let now = Date()
        let time = calendar.dateComponents([.hour, .minute], from: now)
        let base = calendar.date(
            bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: day
        ) ?? day
        _start = State(initialValue: base)
        // A week of repeats is the useful default — long enough to be worth
        // ticking, short enough that nobody has to clean it up later.
        _repeatsUntil = State(initialValue: calendar.date(byAdding: .day, value: 6, to: day) ?? day)
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                sectionLabel(L.AddBlock.quickAdd).padding(.top, 20).padding(.bottom, 8)
                chipRow
                sectionLabel(L.AddBlock.details).padding(.top, 20).padding(.bottom, 8)
                detailsCard
                if repeatsDaily { recurNote.padding(.top, 10) }
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(AB.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(AB.sheetBg)
        .presentationDragIndicator(.hidden)
        .overlay(alignment: .bottom) {
            if titleToast {
                Toast(text: L.AddBlock.toastNeedsTitle)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showTimePicker) {
            timePickerSheet
        }
    }

    // MARK: 1 — Header

    private var header: some View {
        ZStack {
            Text(L.AddBlock.title)
                .font(.baloo(17, heavy: true))
                .foregroundStyle(AB.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text(L.Common.cancel)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(AB.textSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)

                Spacer()

                Button { save() } label: {
                    Text(L.Common.save)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : AB.disabledText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 18)
                        .background(canSave ? AB.accentRose : AB.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy))
            .tracking(0.8)
            .foregroundStyle(AB.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 3 — Quick-add chips

    private var chipRow: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(AB.chips) { chip in
                let selected = chip.title == title
                Button { apply(chip) } label: {
                    Text(chip.title)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(selected ? .white : chip.color)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(selected ? AB.accentRose : AB.chipIdle, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 5 — Details card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            // Row 1 — Title
            TextField(L.AddBlock.titlePlaceholder, text: $title)
                .font(.nunito(15, .bold))
                .foregroundStyle(AB.textPrimary)
                .tint(AB.accentRose)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)

            rowDivider

            // Row 2 — Starts
            HStack {
                Text(L.AddBlock.starts).font(.nunito(15, .bold)).foregroundStyle(AB.textPrimary)
                Spacer()
                Button { showTimePicker = true } label: {
                    Text(start, format: .dateTime.hour().minute())
                        .font(.nunito(14, .heavy))
                        .foregroundStyle(AB.valueText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(AB.fieldFill, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)

            rowDivider

            // Row 3 — Length
            HStack {
                Text(L.AddBlock.length).font(.nunito(15, .bold)).foregroundStyle(AB.textPrimary)
                Spacer()
                stepper
            }
            .padding(.vertical, 12)

            rowDivider

            // Row 4 — Recurring
            Button { withAnimation(.easeOut(duration: 0.18)) { repeatsDaily.toggle() } } label: {
                HStack(spacing: 11) {
                    checkbox
                    VStack(alignment: .leading, spacing: 1) {
                        Text(L.AddBlock.recurring).font(.nunito(15, .bold)).foregroundStyle(AB.textPrimary)
                        Text(L.AddBlock.recurringSub)
                            .font(.nunito(11.5, .semibold))
                            .foregroundStyle(AB.textMuted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Row 5 — how long it keeps repeating
            if repeatsDaily {
                rowDivider
                HStack {
                    Text(L.AddBlock.endsOn).font(.nunito(15, .bold)).foregroundStyle(AB.textPrimary)
                    Spacer()
                    HStack(spacing: 0) {
                        Button { shiftEnd(-1) } label: {
                            Text(L.Glyph.minus).font(.nunito(16, .heavy)).foregroundStyle(AB.textSecondary)
                                .frame(width: 36, height: 32)
                        }
                        .buttonStyle(.plain)
                        Text(repeatsUntil.formatted(.dateTime.day().month(.abbreviated)))
                            .font(.nunito(13, .heavy))
                            .foregroundStyle(AB.valueText)
                            .frame(minWidth: 96)
                        Button { shiftEnd(1) } label: {
                            Text(L.Glyph.plus).font(.nunito(16, .heavy)).foregroundStyle(AB.accentPlus)
                                .frame(width: 36, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(AB.fieldFill, in: Capsule())
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(AB.cardWhite, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    /// Days from the block's own day up to and including the end date.
    private var recurDays: Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: day)
        let to = calendar.startOfDay(for: repeatsUntil)
        return (calendar.dateComponents([.day], from: from, to: to).day ?? 0) + 1
    }

    private var recurNote: some View {
        Text(L.AddBlock.recurNote(
            days: recurDays,
            until: repeatsUntil.formatted(.dateTime.day().month(.abbreviated))
        ))
            .font(.nunito(11.5, .semibold))
            .lineSpacing(4)
            .foregroundStyle(AB.textMuted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shiftEnd(_ direction: Int) {
        let calendar = Calendar.current
        guard let next = calendar.date(byAdding: .day, value: direction, to: repeatsUntil) else { return }
        // Never before the block's own day — a block can't stop repeating
        // before it starts.
        guard calendar.startOfDay(for: next) >= calendar.startOfDay(for: day) else { return }
        repeatsUntil = next
    }

    private var checkbox: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(repeatsDaily ? AB.toggleOn : AB.fieldFill)
            .frame(width: 22, height: 22)
            .overlay {
                if repeatsDaily {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                }
            }
    }

    private var rowDivider: some View {
        Rectangle().fill(AB.divider).frame(height: 1)
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            Button { lengthMinutes = max(15, lengthMinutes - 15) } label: {
                Text(L.Glyph.minus).font(.nunito(16, .heavy)).foregroundStyle(AB.textSecondary)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
            Text(L.Duration.compact(lengthMinutes))
                .font(.nunito(13, .heavy))
                .foregroundStyle(AB.valueText)
                .frame(minWidth: 66)
            Button { lengthMinutes = min(360, lengthMinutes + 15) } label: {
                Text(L.Glyph.plus).font(.nunito(16, .heavy)).foregroundStyle(AB.accentPlus)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(AB.fieldFill, in: Capsule())
    }

    private var timePickerSheet: some View {
        NavigationStack {
            DatePicker(L.AddBlock.starts, selection: $start, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(AB.accentRose)
                .padding()
                .frame(maxHeight: .infinity, alignment: .center)
                .background(AB.sheetBg)
                .navigationTitle(L.AddBlock.starts)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L.Common.done) { showTimePicker = false }.tint(AB.accentRose)
                    }
                }
        }
        .presentationDetents([.height(300)])
        .presentationBackground(AB.sheetBg)
    }

    // MARK: Logic

    private func apply(_ chip: AB.Chip) {
        title = chip.title
        category = chip.category
        lengthMinutes = chip.minutes
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation { titleToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { titleToast = false }
            }
            return
        }
        let block = ScheduleBlock(context: context)
        block.id = UUID()
        block.title = trimmed
        block.category = category.rawValue
        block.startTime = start
        block.endTime = start.addingTimeInterval(Double(lengthMinutes) * 60)
        block.repeatsDaily = repeatsDaily
        block.repeatsUntil = repeatsDaily ? repeatsUntil : nil
        try? context.save()
        onSaved(repeatsDaily
                ? L.AddBlock.toastRepeating(until: repeatsUntil.formatted(.dateTime.day().month(.abbreviated)))
                : L.AddBlock.toastAdded(trimmed))
        dismiss()
    }
}

// MARK: - Toast

struct Toast: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.nunito(14, .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color(hex: 0x4A423B).opacity(0.92), in: Capsule())
            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}

// MARK: - Palette & presets

private enum AB {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let cardWhite = Color.white
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let accentRose = Color(hex: 0xD98FA0)
    static let accentPlus = Color(hex: 0xC97B8C)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let divider = Color(hex: 0x7A6248).opacity(0.1)
    static let chipIdle = Color(hex: 0xF9EDEF)
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = Color(hex: 0xD98FA0)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
    static let valueText = Color(hex: 0x6E6358)

    // Chip category label colours
    static let kids = Color(hex: 0xC4788C)
    static let chores = Color(hex: 0xB98B58)
    static let baby = Color(hex: 0xD9758C)

    struct Chip: Identifiable {
        let title: String
        let category: BlockCategory
        let color: Color
        let minutes: Int
        var id: String { title }
    }

    // Computed, not stored: the titles are translated copy, and a `static let`
    // would pin them to whichever language the app first rendered in.
    static var chips: [Chip] { [
        Chip(title: L.Blocks.Template.schoolRun, category: .kids, color: kids, minutes: 45),
        Chip(title: L.Blocks.Template.schoolHours, category: .kids, color: kids, minutes: 300),
        Chip(title: L.Blocks.Template.napTime, category: .quiet, color: baby, minutes: 90),
        Chip(title: L.Blocks.Template.laundry, category: .chores, color: chores, minutes: 40),
    ] }
}

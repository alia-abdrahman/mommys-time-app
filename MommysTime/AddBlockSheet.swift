import SwiftUI

struct AddBlockSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: BlockCategory = .kids
    @State private var start: Date
    @State private var lengthMinutes = 60
    @State private var repeatsDaily = false
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
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                sectionLabel("QUICK ADD").padding(.top, 20).padding(.bottom, 8)
                chipRow
                sectionLabel("DETAILS").padding(.top, 20).padding(.bottom, 8)
                detailsCard
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
        }
        .background(AB.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(AB.sheetBg)
        .presentationDragIndicator(.hidden)
        .overlay(alignment: .bottom) {
            if titleToast {
                Toast(text: "Give it a title first")
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
            Text("Add to your day")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(AB.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
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
                    Text("Save")
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
            TextField("Title (e.g. Nap time)", text: $title)
                .font(.nunito(15, .bold))
                .foregroundStyle(AB.textPrimary)
                .tint(AB.accentRose)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)

            rowDivider

            // Row 2 — Starts
            HStack {
                Text("Starts").font(.nunito(15, .bold)).foregroundStyle(AB.textPrimary)
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
                Text("Length").font(.nunito(15, .bold)).foregroundStyle(AB.textPrimary)
                Spacer()
                stepper
            }
            .padding(.vertical, 12)

            rowDivider

            // Row 4 — Repeats every day
            HStack {
                Text("Repeats every day").font(.nunito(15, .bold)).foregroundStyle(AB.textPrimary)
                Spacer()
                toggle
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(AB.cardWhite, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private var rowDivider: some View {
        Rectangle().fill(AB.divider).frame(height: 1)
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            Button { lengthMinutes = max(15, lengthMinutes - 15) } label: {
                Text("−").font(.nunito(16, .heavy)).foregroundStyle(AB.textSecondary)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
            Text(AB.lengthLabel(lengthMinutes))
                .font(.nunito(13, .heavy))
                .foregroundStyle(AB.valueText)
                .frame(minWidth: 66)
            Button { lengthMinutes = min(360, lengthMinutes + 15) } label: {
                Text("+").font(.nunito(16, .heavy)).foregroundStyle(AB.accentPlus)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(AB.fieldFill, in: Capsule())
    }

    private var toggle: some View {
        Button { repeatsDaily.toggle() } label: {
            ZStack(alignment: repeatsDaily ? .trailing : .leading) {
                Capsule().fill(repeatsDaily ? AB.toggleOn : AB.toggleOff)
                    .frame(width: 50, height: 30)
                Circle().fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2.5, y: 2)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: repeatsDaily)
    }

    private var timePickerSheet: some View {
        NavigationStack {
            DatePicker("Starts", selection: $start, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(AB.accentRose)
                .padding()
                .frame(maxHeight: .infinity, alignment: .center)
                .background(AB.sheetBg)
                .navigationTitle("Starts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showTimePicker = false }.tint(AB.accentRose)
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
        try? context.save()
        onSaved(repeatsDaily ? "Added to every day this week" : "\(trimmed) added")
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
    static let chipIdle = Color(hex: 0xEFE8F1)
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = Color(hex: 0x7FBFAE)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
    static let valueText = Color(hex: 0x6E6358)

    // Chip category label colours
    static let kids = Color(hex: 0x7C77B5)
    static let chores = Color(hex: 0xB98B58)
    static let baby = Color(hex: 0x4E9E86)

    struct Chip: Identifiable {
        let title: String
        let category: BlockCategory
        let color: Color
        let minutes: Int
        var id: String { title }
    }

    static let chips: [Chip] = [
        Chip(title: "School run", category: .kids, color: kids, minutes: 45),
        Chip(title: "School hours", category: .kids, color: kids, minutes: 300),
        Chip(title: "Nap time", category: .quiet, color: baby, minutes: 90),
        Chip(title: "Laundry", category: .chores, color: chores, minutes: 40),
    ]

    static func lengthLabel(_ m: Int) -> String {
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }
}

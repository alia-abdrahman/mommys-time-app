import SwiftUI
import CoreData

struct FindTimeSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 23
    @AppStorage(SettingsKeys.bedtimeHour) private var bedtimeHour = 21
    @AppStorage(SettingsKeys.minGapMinutes) private var minGapMinutes = 30
    @AppStorage(SettingsKeys.maxSlotMinutes) private var maxSlotMinutes = 120

    let intervals: [BlockInterval]
    var date: Date = Date()
    var onBooked: (String) -> Void = { _ in }

    private var slots: [FreeSlot] {
        TimeFinder(
            dayStartHour: dayStartHour,
            dayEndHour: dayEndHour,
            bedtimeHour: bedtimeHour,
            minGapMinutes: minGapMinutes,
            maxSlotMinutes: maxSlotMinutes
        )
        .findSlots(in: intervals, on: date)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                if slots.isEmpty {
                    noSlotsView
                } else {
                    VStack(spacing: 11) {
                        ForEach(slots) { slot in
                            WindowCard(slot: slot, note: note(for: slot)) { book(slot) }
                        }
                    }
                    .padding(.top, 20)

                    footerNote.padding(.top, 12)
                }
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(FT.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(FT.sheetBg)
        .presentationDragIndicator(.hidden)
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("Your best windows")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(FT.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Close")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(FT.textSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(FT.cardWhite, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Color.clear.frame(width: 64, height: 1)
            }
        }
    }

    private var footerNote: some View {
        Text("Booking a slot adds it to today's schedule — your me-time becomes as official as the chores.")
            .font(.nunito(12.5, .bold))
            .lineSpacing(6)
            .foregroundStyle(FT.noteText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(FT.noteBg, in: RoundedRectangle(cornerRadius: 22))
    }

    private var noSlotsView: some View {
        VStack(spacing: 12) {
            Text("😮‍💨").font(.system(size: 52))
            Text("No free windows left today")
                .font(.baloo(20, heavy: true))
                .foregroundStyle(FT.textPrimary)
            Text("Today is a full one, mama. Try again tomorrow, or shorten the minimum gap in Settings.")
                .font(.nunito(15))
                .foregroundStyle(FT.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }

    // MARK: Logic

    private func note(for slot: FreeSlot) -> String {
        let r = slot.reasons
        if r.contains(where: { $0.contains("bedtime") }) {
            return "After bedtime — nobody will need you."
        }
        if r.contains(where: { $0.contains("quiet") }) {
            return "The kids are settled — the house is quiet."
        }
        if slot.minutes >= 90 {
            return "A lovely long stretch — a real pocket for you."
        }
        return "\(slot.minutes) free minutes just for you."
    }

    private func book(_ slot: FreeSlot) {
        let block = ScheduleBlock(context: context)
        block.id = UUID()
        block.title = "Me-time"
        block.category = BlockCategory.meTime.rawValue
        block.startTime = slot.start
        block.endTime = slot.end
        block.repeatsDaily = false

        let session = MeTimeSession(context: context)
        session.id = UUID()
        session.date = slot.start
        session.durationMinutes = Int32(slot.minutes)
        session.completed = false
        session.block = block

        try? context.save()
        onBooked("Booked \(FT.durationLabel(slot.minutes)) of me-time")
        dismiss()
    }
}

// MARK: - Window card

private struct WindowCard: View {
    let slot: FreeSlot
    let note: String
    let onBook: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(slot.start, format: .dateTime.hour().minute()) – \(slot.end, format: .dateTime.hour().minute())")
                    .font(.baloo(19, heavy: true))
                    .foregroundStyle(FT.textPrimary)
                Spacer()
                Text("\(slot.minutes) min")
                    .font(.nunito(12, .heavy))
                    .foregroundStyle(FT.textMuted)
            }

            Text(note)
                .font(.nunito(13, .semibold))
                .foregroundStyle(FT.textMuted)
                .padding(.top, 4)

            Button(action: onBook) {
                Text("Book this time")
                    .font(.baloo(15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(FT.accentRose, in: Capsule())
                    .shadow(color: FT.accentRose.opacity(0.38), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FT.cardWhite, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 16, y: 6)
    }
}

// MARK: - Palette & helpers

private enum FT {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let cardWhite = Color.white
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let accentRose = Color(hex: 0xD98FA0)
    static let noteBg = Color(hex: 0xFBEBD8)
    static let noteText = Color(hex: 0x8A6A44)

    static func durationLabel(_ m: Int) -> String {
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }
}

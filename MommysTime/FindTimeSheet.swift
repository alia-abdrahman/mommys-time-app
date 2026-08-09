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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Goal.createdAt, ascending: true)],
        animation: .default
    )
    private var goals: FetchedResults<Goal>

    let intervals: [BlockInterval]

    private var slots: [FreeSlot] {
        TimeFinder(
            dayStartHour: dayStartHour,
            dayEndHour: dayEndHour,
            bedtimeHour: bedtimeHour,
            minGapMinutes: minGapMinutes,
            maxSlotMinutes: maxSlotMinutes
        )
        .findSlots(in: intervals, on: Date())
    }

    var body: some View {
        NavigationStack {
            Group {
                if slots.isEmpty {
                    noSlotsView
                } else {
                    List {
                        Section {
                            ForEach(Array(slots.prefix(3).enumerated()), id: \.element.id) { index, slot in
                                SlotRow(slot: slot, rank: index + 1, goals: Array(goals), onBook: book)
                            }
                        } footer: {
                            Text("Booking a slot adds it to today's schedule — your me-time becomes as official as the chores. 💛")
                        }
                    }
                }
            }
            .navigationTitle("Your best windows")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var noSlotsView: some View {
        VStack(spacing: 12) {
            Text("😮‍💨")
                .font(.system(size: 56))
            Text("No free windows left today")
                .font(.title3.bold())
            Text("Today is a full one, mama. Tomorrow is a new day — try again in the morning, or shorten the minimum gap in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private func book(slot: FreeSlot, goal: Goal?) {
        let block = ScheduleBlock(context: context)
        block.id = UUID()
        block.title = goal.flatMap { $0.name } ?? "Me time"
        block.category = BlockCategory.meTime.rawValue
        block.startTime = slot.start
        block.endTime = slot.end
        block.repeatsDaily = false

        let session = MeTimeSession(context: context)
        session.id = UUID()
        session.date = slot.start
        session.durationMinutes = Int32(slot.minutes)
        session.completed = false
        session.goal = goal
        session.block = block

        try? context.save()
        dismiss()
    }
}

struct SlotRow: View {
    let slot: FreeSlot
    let rank: Int
    let goals: [Goal]
    let onBook: (FreeSlot, Goal?) -> Void

    private var rankEmoji: String {
        switch rank {
        case 1: return "✨"
        case 2: return "🌟"
        default: return "⭐️"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(rankEmoji) \(slot.start, format: .dateTime.hour().minute()) – \(slot.end, format: .dateTime.hour().minute())")
                    .font(.headline)
                Spacer()
                Text("\(slot.minutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(slot.reasons, id: \.self) { reason in
                Text("• \(reason)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Menu {
                ForEach(goals, id: \.objectID) { goal in
                    Button("\(goal.icon ?? "🌸") \(goal.name ?? "")") {
                        onBook(slot, goal)
                    }
                }
                Button("Just me time 💆‍♀️") {
                    onBook(slot, nil)
                }
            } label: {
                Label("Book this time", systemImage: "calendar.badge.plus")
                    .font(.subheadline.bold())
            }
        }
        .padding(.vertical, 4)
    }
}

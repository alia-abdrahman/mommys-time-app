import SwiftUI

enum BlockCategory: String, CaseIterable, Identifiable {
    case kids
    case chores
    case appointment
    case quiet
    case meTime = "metime"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .kids: return "Kids"
        case .chores: return "Chores"
        case .appointment: return "Appointment"
        case .quiet: return "Quiet time"
        case .meTime: return "Me time"
        }
    }

    var systemImage: String {
        switch self {
        case .kids: return "figure.2.and.child.holdinghands"
        case .chores: return "house.fill"
        case .appointment: return "calendar.badge.clock"
        case .quiet: return "moon.zzz.fill"
        case .meTime: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .kids: return .blue
        case .chores: return .orange
        case .appointment: return .purple
        case .quiet: return .indigo
        case .meTime: return .pink
        }
    }
}

struct BlockTemplate: Identifiable {
    let id = UUID()
    let title: String
    let category: BlockCategory
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int

    static let all: [BlockTemplate] = [
        BlockTemplate(title: "School run", category: .kids, startHour: 7, startMinute: 15, durationMinutes: 45),
        BlockTemplate(title: "School hours", category: .quiet, startHour: 8, startMinute: 0, durationMinutes: 300),
        BlockTemplate(title: "Nap time", category: .quiet, startHour: 13, startMinute: 0, durationMinutes: 120),
        BlockTemplate(title: "Cooking", category: .chores, startHour: 17, startMinute: 0, durationMinutes: 60),
        BlockTemplate(title: "Kids' dinner & bath", category: .kids, startHour: 18, startMinute: 30, durationMinutes: 90),
        BlockTemplate(title: "Bedtime routine", category: .kids, startHour: 20, startMinute: 0, durationMinutes: 60),
        BlockTemplate(title: "Laundry", category: .chores, startHour: 10, startMinute: 0, durationMinutes: 45),
        BlockTemplate(title: "Groceries", category: .chores, startHour: 11, startMinute: 0, durationMinutes: 60),
    ]
}

extension ScheduleBlock {
    var blockCategory: BlockCategory {
        BlockCategory(rawValue: category ?? "") ?? .chores
    }

    /// Returns this block's start/end projected onto the given day, or nil
    /// if the block doesn't apply to that day.
    func resolvedTimes(on day: Date, calendar: Calendar = .current) -> (start: Date, end: Date)? {
        guard let start = startTime, let end = endTime else { return nil }
        if repeatsDaily {
            let s = calendar.dateComponents([.hour, .minute], from: start)
            let e = calendar.dateComponents([.hour, .minute], from: end)
            guard let projectedStart = calendar.date(bySettingHour: s.hour ?? 0, minute: s.minute ?? 0, second: 0, of: day),
                  let projectedEnd = calendar.date(bySettingHour: e.hour ?? 0, minute: e.minute ?? 0, second: 0, of: day),
                  projectedStart < projectedEnd
            else { return nil }
            return (projectedStart, projectedEnd)
        }
        guard calendar.isDate(start, inSameDayAs: day) else { return nil }
        return (start, end)
    }
}

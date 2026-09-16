import SwiftUI

// The calendar surfaces the design reuses: the Week/Month card on Daily Task
// and the drop-down month grid on the log-history screens. Both share one day
// cell so a selected day looks identical everywhere.

/// One day in a calendar grid — rose when selected, amber dot when the day has
/// something logged.
struct CalendarDayCell: View {
    let day: Date?
    let selected: Bool
    let busy: Bool
    var disabled = false
    var height: CGFloat = 34
    var onTap: () -> Void = {}

    private let calendar = Calendar.current

    var body: some View {
        Group {
            if let day {
                VStack(spacing: 2) {
                    Text(day.formatted(.dateTime.day()))
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(selected ? .white : Theme.inkSoft)
                    Circle()
                        .fill(dotColour)
                        .frame(width: 4, height: 4)
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.rose)
                            .shadow(color: Theme.rose.opacity(0.35), radius: 5, y: 4)
                    }
                }
                .opacity(disabled ? 0.3 : 1)
                .contentShape(Rectangle())
                .onTapGesture { if !disabled { onTap() } }
            } else {
                Color.clear.frame(height: height)
            }
        }
    }

    private var dotColour: Color {
        guard busy else { return .clear }
        return selected ? .white.opacity(0.95) : Theme.calendarBusy
    }
}

/// Mon–Sun initials above a calendar grid.
struct WeekdayHeader: View {
    private let heads = L.CalendarCopy.weekdayInitials

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(heads.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.nunito(9.5, .heavy))
                    .tracking(0.4)
                    .foregroundStyle(Theme.inkWhisper)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

enum CalendarMode: String, CaseIterable {
    case week, month

    var label: String {
        switch self {
        case .week: return L.CalendarCopy.week
        case .month: return L.CalendarCopy.month
        }
    }
}

/// Grid maths shared by both calendars — weeks start on Monday.
enum CalendarGridMaths {
    static var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    /// The seven days of the week containing `date`.
    static func week(containing date: Date) -> [Date] {
        let cal = calendar
        guard let start = cal.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    /// The month containing `date`, padded with leading blanks so the 1st lands
    /// under its weekday column.
    static func month(containing date: Date) -> [Date?] {
        let cal = calendar
        guard let interval = cal.dateInterval(of: .month, for: date),
              let count = cal.range(of: .day, in: .month, for: date)?.count
        else { return [] }
        // Monday-based offset for the 1st of the month.
        let leading = (cal.component(.weekday, from: interval.start) - cal.firstWeekday + 7) % 7
        let days: [Date?] = (0..<count).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
        return Array(repeating: nil, count: leading) + days
    }
}

/// Daily Task's calendar: Week/Month toggle, arrows, grid and the day caption.
struct ScheduleCalendarCard: View {
    @Binding var date: Date
    @Binding var mode: CalendarMode
    var hasEntries: (Date) -> Bool = { _ in false }

    private let calendar = CalendarGridMaths.calendar

    private var cells: [Date?] {
        mode == .month
            ? CalendarGridMaths.month(containing: date)
            : CalendarGridMaths.week(containing: date).map { Optional($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            modePicker
            navRow.padding(.top, 8)
            WeekdayHeader.init().padding(.top, 8)
            grid.padding(.top, 3)
            Text(date.formatted(.dateTime.weekday(.wide).day().month().year()))
                .font(.nunito(11.5, .bold))
                .foregroundStyle(Theme.inkMuted)
                .padding(.top, 7)
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(CalendarMode.allCases, id: \.self) { m in
                let on = mode == m
                Button { withAnimation(.easeInOut(duration: 0.18)) { mode = m } } label: {
                    Text(m.label)
                        .font(.nunito(12.5, .heavy))
                        .foregroundStyle(on ? Theme.roseText : Theme.inkFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if on {
                                Capsule().fill(.white)
                                    .shadow(color: Color(hex: 0x7A6248).opacity(0.14), radius: 4, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.field, in: Capsule())
    }

    private var navRow: some View {
        HStack(spacing: 8) {
            arrow("chevron.left") { shift(-1) }
            Text(rangeLabel)
                .font(.baloo(15, heavy: true))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
            arrow("chevron.right") { shift(1) }
        }
    }

    private func arrow(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(Theme.reminderStroke)
                .frame(width: 34, height: 34)
                .background(Theme.peach, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                CalendarDayCell(
                    day: day,
                    selected: day.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                    busy: day.map(hasEntries) ?? false
                ) {
                    if let day { withAnimation(.easeInOut(duration: 0.15)) { date = day } }
                }
            }
        }
    }

    private var rangeLabel: String {
        if mode == .month {
            return date.formatted(.dateTime.month(.wide).year())
        }
        let days = CalendarGridMaths.week(containing: date)
        guard let first = days.first, let last = days.last else { return "" }
        let month = last.formatted(.dateTime.month(.abbreviated))
        let sameMonth = calendar.isDate(first, equalTo: last, toGranularity: .month)
        let start = first.formatted(.dateTime.day())
        let end = last.formatted(.dateTime.day())
        return sameMonth
            ? L.CalendarCopy.rangeSameMonth(start: start, end: end, month: month)
            : L.CalendarCopy.rangeAcrossMonths(
                start: start,
                startMonth: first.formatted(.dateTime.month(.abbreviated)),
                end: end,
                endMonth: month
              )
    }

    private func shift(_ direction: Int) {
        let component: Calendar.Component = mode == .month ? .month : .weekOfYear
        guard let next = calendar.date(byAdding: component, value: direction, to: date) else { return }
        withAnimation(.easeInOut(duration: 0.18)) { date = next }
    }
}

/// The month grid that drops out of a history screen's date header.
struct MiniCalendarPopover: View {
    @Binding var date: Date
    var hasEntries: (Date) -> Bool = { _ in false }
    var onPick: (Date) -> Void

    private let calendar = CalendarGridMaths.calendar

    var body: some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.month(.wide).year()))
                .font(.baloo(14, heavy: true))
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 8)
            WeekdayHeader()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(Array(CalendarGridMaths.month(containing: date).enumerated()), id: \.offset) { _, day in
                    CalendarDayCell(
                        day: day,
                        selected: day.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                        busy: day.map(hasEntries) ?? false,
                        // You can't log anything in the future, so don't offer it.
                        disabled: day.map { $0 > Date() } ?? false,
                        height: 32
                    ) {
                        if let day { onPick(day) }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.24), radius: 20, y: 18)
    }
}

import SwiftUI
import CoreData

// "Session History" / "Feed History" — step back through the days one at a
// time, or drop the month grid open and jump.

/// One line in a history list.
struct HistoryRow: Identifiable {
    let id: NSManagedObjectID
    let time: Date
    let title: String
    let detail: String
}

struct LogHistoryView: View {
    let title: String
    /// Every logged entry, so the calendar can dot the days that have one.
    let entries: [HistoryRow]
    /// "3 SESSIONS · 320 ML" for the chosen day.
    let summary: (Date) -> String
    /// The design's history is read-only, but editing and deleting a mislogged
    /// entry has to live somewhere — so rows stay tappable.
    var onSelect: ((NSManagedObjectID) -> Void)?
    var onDelete: ((NSManagedObjectID) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var day = Date()
    @State private var calendarOpen = false

    private let calendar = Calendar.current

    private var dayRows: [HistoryRow] {
        entries
            .filter { calendar.isDate($0.time, inSameDayAs: day) }
            .sorted { $0.time > $1.time }
    }

    private var isToday: Bool { calendar.isDateInToday(day) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                DetailHeader(title: title) { dismiss() }

                ZStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        dateBar
                        rowsCard.padding(.top, 12)
                    }
                    if calendarOpen { popover }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
            .padding(.top, 8)
            .padding(.bottom, 116)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: Date navigation

    private var dateBar: some View {
        HStack(spacing: 10) {
            arrow("chevron.left", enabled: true) { shift(-1) }

            Button { withAnimation(.easeOut(duration: 0.16)) { calendarOpen.toggle() } } label: {
                VStack(spacing: 1) {
                    HStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                            .font(.baloo(16, heavy: true))
                            .foregroundStyle(Theme.ink)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.reminderStroke)
                            .rotationEffect(.degrees(calendarOpen ? 180 : 0))
                    }
                    Text(summary(day))
                        .font(.nunito(11, .bold))
                        .foregroundStyle(Theme.inkMuted)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            arrow("chevron.right", enabled: !isToday) { shift(1) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    private func arrow(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Theme.reminderStroke)
                .frame(width: 36, height: 36)
                .background(Theme.peach, in: Circle())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.35)
        .disabled(!enabled)
    }

    /// Tapping outside the grid closes it, matching the design's scrim.
    private var popover: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 60)
            MiniCalendarPopover(date: $day, hasEntries: hasEntries) { picked in
                withAnimation(.easeOut(duration: 0.16)) {
                    day = picked
                    calendarOpen = false
                }
            }
        }
        .zIndex(2)
    }

    // MARK: Rows

    private var rowsCard: some View {
        VStack(spacing: 0) {
            if dayRows.isEmpty {
                Text(L.History.empty)
                    .font(.nunito(13.5, .bold))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .padding(.horizontal, 22)
            } else {
                ForEach(Array(dayRows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { CardDivider() }
                    HStack(spacing: 10) {
                        Text(row.time, format: .dateTime.hour().minute())
                            .font(.nunito(13, .heavy))
                            .foregroundStyle(Theme.roseInk)
                            .frame(width: 74, alignment: .leading)
                        Text(row.title)
                            .font(.nunito(13, .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(row.detail)
                            .font(.nunito(12, .bold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect?(row.id) }
                    .contextMenu {
                        if let onSelect {
                            Button(L.Common.edit) { onSelect(row.id) }
                        }
                        if let onDelete {
                            Button(L.Common.delete, role: .destructive) { onDelete(row.id) }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.07), radius: 8, y: 4)
    }

    private func hasEntries(_ date: Date) -> Bool {
        entries.contains { calendar.isDate($0.time, inSameDayAs: date) }
    }

    private func shift(_ direction: Int) {
        guard let next = calendar.date(byAdding: .day, value: direction, to: day) else { return }
        // Never walk past today — there's nothing logged in the future.
        guard next <= Date() else { return }
        withAnimation(.easeInOut(duration: 0.15)) { day = next }
    }
}

// MARK: - Growth history

/// Growth is measured at clinic visits, not daily, so its history is one flat
/// list rather than a per-day view.
struct GrowthHistoryView: View {
    let entries: [GrowthEntry]

    @Environment(\.dismiss) private var dismiss

    private var sorted: [GrowthEntry] {
        entries.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                DetailHeader(title: L.Growth.historyTitle) { dismiss() }

                Text(L.Growth.historyHeading)
                    .font(.baloo(15, heavy: true))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                VStack(spacing: 0) {
                    if sorted.isEmpty {
                        Text(L.Growth.historyEmpty)
                            .font(.nunito(13.5, .bold))
                            .foregroundStyle(Theme.inkFaint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 26)
                    } else {
                        ForEach(Array(sorted.enumerated()), id: \.element.objectID) { index, entry in
                            if index > 0 { CardDivider() }
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(entry.date?.formatted(.dateTime.day().month(.abbreviated)) ?? L.Common.none)
                                        .font(.nunito(13, .heavy))
                                        .foregroundStyle(Theme.roseInk)
                                    Text(ageLabel(entry))
                                        .font(.nunito(10.5, .bold))
                                        .foregroundStyle(Theme.inkMuted)
                                }
                                .frame(width: 78, alignment: .leading)
                                Text(detail(entry))
                                    .font(.nunito(13, .bold))
                                    .foregroundStyle(Theme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Theme.cardBorder, lineWidth: 2)
                }
                .shadow(color: Color(hex: 0x7A6248).opacity(0.07), radius: 8, y: 4)
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 116)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private func detail(_ entry: GrowthEntry) -> String {
        var parts = [L.Growth.valueKg(trim(entry.weightKg)), L.Growth.valueCm(trim(entry.heightCm))]
        if entry.headCm > 0 { parts.append(L.Growth.headDetail(trim(entry.headCm))) }
        return parts.joined(separator: " · ")
    }

    /// Baby's age at the visit, measured from the earliest recorded measurement.
    private func ageLabel(_ entry: GrowthEntry) -> String {
        guard let birth = entries.compactMap(\.date).min(), let date = entry.date else { return "" }
        let months = Calendar.current.dateComponents([.month], from: birth, to: date).month ?? 0
        return months <= 0 ? L.Growth.birth : L.Growth.months(months)
    }

    private func trim(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

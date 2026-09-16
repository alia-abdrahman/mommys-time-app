import SwiftUI
import CoreData

struct WeeklyProgressView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleBlock.startTime, ascending: true)],
        animation: .default
    )
    private var allBlocks: FetchedResults<ScheduleBlock>

    /// Monday-first list of this week's 7 days.
    private var weekDays: [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    /// Minutes of booked me-time on a given day (Schedule "Me-time" blocks only).
    private func minutes(on day: Date) -> Int {
        allBlocks
            .filter { $0.blockCategory == .meTime }
            .compactMap { $0.resolvedTimes(on: day) }
            .reduce(0) { $0 + Int($1.end.timeIntervalSince($1.start) / 60) }
    }

    private var dayMinutes: [Int] { weekDays.map { minutes(on: $0) } }
    private var totalMinutes: Int { dayMinutes.reduce(0, +) }

    private func totalLabel(_ m: Int) -> String {
        m == 0 ? L.Duration.zeroMinutes : L.Duration.compact(m)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L.Progress.title)
                    .font(.baloo(30, heavy: true))
                    .foregroundStyle(PR.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L.Progress.weekLabel)
                        .font(.nunito(12, .heavy)).tracking(0.8)
                        .foregroundStyle(PR.textMuted)
                        .padding(.bottom, 8)

                    weekCard
                    reassuranceNote.padding(.top, 14)
                }
                .padding(.top, 16)
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PR.screenBg.ignoresSafeArea())
    }

    private var weekCard: some View {
        let minutes = dayMinutes
        let busiest = max(60, minutes.max() ?? 0)
        let labels = L.CalendarCopy.weekdayInitials

        return VStack(alignment: .leading, spacing: 0) {
            Text(totalLabel(totalMinutes))
                .font(.baloo(40, heavy: true))
                .foregroundStyle(PR.roseAccent)
            Text(totalMinutes > 0 ? L.Progress.booked : L.Progress.nothingYet)
                .font(.nunito(14))
                .lineSpacing(5)
                .foregroundStyle(PR.bodyText)
                .padding(.top, 6)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let m = minutes[i]
                    RoundedRectangle(cornerRadius: 8)
                        .fill(m > 0 ? PR.roseAccent : PR.emptyBar)
                        .frame(height: m > 0 ? max(16, 16 + 48 * CGFloat(m) / CGFloat(busiest)) : 14)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 64, alignment: .bottom)
            .padding(.top, 16)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    Text(labels[i])
                        .font(.nunito(10.5, .bold))
                        .foregroundStyle(PR.barLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 16, y: 6)
    }

    private var reassuranceNote: some View {
        Text(L.Progress.reassurance)
            .font(.nunito(13, .bold)).lineSpacing(6)
            .foregroundStyle(PR.noteText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16).padding(.horizontal, 18)
            .background(PR.noteBg, in: RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Progress palette

private enum PR {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let bodyText = Color(hex: 0x8A7E72)
    static let roseAccent = Color(hex: 0xD98FA0)
    static let emptyBar = Color(hex: 0xF0E7DC)
    static let barLabel = Color(hex: 0xB7AA9B)
    static let noteBg = Color(hex: 0xFBEBD8)
    static let noteText = Color(hex: 0x8A6A44)
}

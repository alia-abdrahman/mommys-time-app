import Foundation

struct BlockInterval {
    let start: Date
    let end: Date
    let category: BlockCategory
}

struct FreeSlot: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let score: Int
    let reasons: [String]

    var minutes: Int { Int(end.timeIntervalSince(start) / 60) }
}

/// Finds and ranks free pockets of time in a day's schedule.
///
/// "Quiet" blocks (nap time, school hours) are treated as FREE time for mom
/// with a scoring bonus — the kids are asleep or away, so those are the best
/// windows for me-time.
struct TimeFinder {
    var dayStartHour = 6
    var dayEndHour = 23
    var bedtimeHour = 21
    var minGapMinutes = 30
    var maxSlotMinutes = 120

    func findSlots(in blocks: [BlockInterval], on day: Date, now: Date = Date(), calendar: Calendar = .current) -> [FreeSlot] {
        guard let dayStart = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: day),
              let dayEnd = calendar.date(bySettingHour: dayEndHour, minute: 0, second: 0, of: day),
              let bedtime = calendar.date(bySettingHour: bedtimeHour, minute: 0, second: 0, of: day)
        else { return [] }

        let searchStart = max(dayStart, now)
        guard searchStart < dayEnd else { return [] }

        let busy = blocks
            .filter { $0.category != .quiet }
            .map { (start: max($0.start, searchStart), end: min($0.end, dayEnd)) }
            .filter { $0.start < $0.end }
            .sorted { $0.start < $1.start }

        var merged: [(start: Date, end: Date)] = []
        for interval in busy {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1].end = max(last.end, interval.end)
            } else {
                merged.append(interval)
            }
        }

        var gaps: [(start: Date, end: Date)] = []
        var cursor = searchStart
        for interval in merged {
            if interval.start > cursor {
                gaps.append((cursor, interval.start))
            }
            cursor = max(cursor, interval.end)
        }
        if cursor < dayEnd {
            gaps.append((cursor, dayEnd))
        }

        return gaps
            .filter { $0.end.timeIntervalSince($0.start) >= Double(minGapMinutes * 60) }
            .compactMap { gap -> FreeSlot? in
                candidateWindows(for: gap, bedtime: bedtime)
                    .filter { $0.end.timeIntervalSince($0.start) >= Double(minGapMinutes * 60) }
                    .map { score(gap: $0, blocks: blocks, bedtime: bedtime) }
                    .max { $0.score < $1.score }
            }
            .sorted { $0.score > $1.score }
    }

    /// For a gap longer than `maxSlotMinutes`, returns a few capped windows to
    /// choose from — anchored to the start, the end, and (if it falls inside)
    /// the kids' bedtime. The caller keeps the best-scoring one, so an evening
    /// gap that crosses bedtime naturally suggests the calm after-bedtime hour
    /// rather than the whole stretch.
    private func candidateWindows(for gap: (start: Date, end: Date), bedtime: Date) -> [(start: Date, end: Date)] {
        let maxSeconds = Double(maxSlotMinutes * 60)
        guard gap.end.timeIntervalSince(gap.start) > maxSeconds else { return [gap] }

        var windows: [(start: Date, end: Date)] = [
            (gap.start, gap.start.addingTimeInterval(maxSeconds)),
            (gap.end.addingTimeInterval(-maxSeconds), gap.end),
        ]
        if bedtime > gap.start && bedtime < gap.end {
            let end = min(gap.end, bedtime.addingTimeInterval(maxSeconds))
            let start = max(gap.start, end.addingTimeInterval(-maxSeconds))
            windows.append((start, end))
        }
        return windows
    }

    private func score(gap: (start: Date, end: Date), blocks: [BlockInterval], bedtime: Date) -> FreeSlot {
        let minutes = Int(gap.end.timeIntervalSince(gap.start) / 60)
        var score = min(minutes, 120)
        var reasons: [String] = []

        if minutes >= 90 {
            reasons.append("A lovely long stretch — \(minutes) minutes")
        }

        let overlapsQuiet = blocks.contains {
            $0.category == .quiet && $0.start < gap.end && gap.start < $0.end
        }
        if overlapsQuiet {
            score += 40
            reasons.append("The kids are settled — quiet time 🌙")
        }

        if gap.start >= bedtime {
            score += 30
            reasons.append("After the kids' bedtime")
        }

        let afterBigChore = blocks.contains { block in
            guard block.category == .chores else { return false }
            let choreSeconds = block.end.timeIntervalSince(block.start)
            let secondsFromChoreToGap = abs(block.end.timeIntervalSince(gap.start))
            return choreSeconds >= 3600 && secondsFromChoreToGap < 600
        }
        if afterBigChore {
            score -= 15
            reasons.append("Right after a big chore — maybe start with something light")
        }

        if reasons.isEmpty {
            reasons.append("\(minutes) free minutes just for you")
        }

        return FreeSlot(start: gap.start, end: gap.end, score: score, reasons: reasons)
    }
}

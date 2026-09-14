import SwiftUI

// The two chart cards the design uses on the log screens: a seven-day bar
// chart for pump/feed volume, and a forward-filled trend line for growth.

/// "ML PUMPED · LAST 7 DAYS" — one bar per day, today's bar in the accent tint.
struct WeeklyBarChart: View {
    let title: String
    /// Millilitres per day, oldest first, ending today.
    let values: [Int]
    var tint: Color = Theme.rose
    var unit = "ml"

    private let calendar = Calendar.current

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<values.count).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private var peak: Int { max(values.max() ?? 0, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.nunito(12, .heavy))
                    .tracking(0.8)
                    .foregroundStyle(Theme.inkFaint)
                Spacer()
                // "peak 1 ml" on an all-zero week reads like a bug, so say the
                // truthful thing instead.
                Text(values.contains { $0 > 0 } ? "peak \(peak) \(unit)" : "nothing logged yet")
                    .font(.nunito(11.5, .heavy))
                    .foregroundStyle(Theme.roseAccentText)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    bar(value: value, day: days[safe: index])
                }
            }
            .frame(height: 184)
            .padding(.top, 14)
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 8, y: 4)
    }

    private func bar(value: Int, day: Date?) -> some View {
        let isToday = day.map { calendar.isDateInToday($0) } ?? false
        let height = value == 0 ? 4 : max(4, CGFloat(value) / CGFloat(peak) * 138)
        return VStack(spacing: 5) {
            Spacer(minLength: 0)
            Text(value == 0 ? "" : "\(value)")
                .font(.nunito(9.5, .heavy))
                .foregroundStyle(Theme.inkMuted)
            UnevenRoundedRectangle(
                topLeadingRadius: 8, bottomLeadingRadius: 4,
                bottomTrailingRadius: 4, topTrailingRadius: 8,
                style: .continuous
            )
            .fill(value == 0 ? Theme.chartEmptyBar : (isToday ? tint : Theme.chartPastBar))
            .frame(height: height)
            Text(isToday ? "Today" : (day?.formatted(.dateTime.day()) ?? ""))
                .font(.nunito(10, .heavy))
                .foregroundStyle(isToday ? Theme.roseAccentText : Theme.inkWhisper)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A measurement carried forward day by day, drawn as an area + line with a dot
/// on each real reading.
struct TrendLineChart: View {
    let title: String
    let unit: String
    /// Real measurements, any order.
    let points: [(date: Date, value: Double)]
    var days = 30

    private let calendar = Calendar.current

    private var window: [Date] {
        let end = calendar.startOfDay(for: points.map(\.date).max() ?? Date())
        return (0..<days).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: end) }
    }

    /// Carries the last recorded value across days with no entry, so the line is
    /// continuous even though clinic visits are weeks apart.
    private var filled: [Double] {
        let sorted = points.sorted { $0.date < $1.date }
        guard let first = sorted.first else { return [] }
        return window.map { day in
            sorted.last(where: { calendar.startOfDay(for: $0.date) <= day })?.value ?? first.value
        }
    }

    private var bounds: (low: Double, high: Double) {
        let values = filled
        guard let lo = values.min(), let hi = values.max() else { return (0, 1) }
        let pad = max((hi - lo) * 0.25, 0.1)
        return (max(0, lo - pad), hi + pad)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.nunito(12, .heavy))
                    .tracking(0.8)
                    .foregroundStyle(Theme.inkFaint)
                Spacer()
                Text(trendLabel)
                    .font(.nunito(11.5, .heavy))
                    .foregroundStyle(Theme.roseAccentText)
            }

            HStack(alignment: .top, spacing: 9) {
                axisLabels
                VStack(spacing: 0) {
                    plot.frame(height: 132)
                    dateAxis.padding(.top, 7)
                }
            }
            .padding(.top, 12)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(latestLabel)
                    .font(.baloo(20, heavy: true))
                    .foregroundStyle(Theme.roseInk)
                Text("latest · \(lastPointLabel)")
                    .font(.nunito(11.5, .bold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 15)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 8, y: 4)
    }

    private var axisLabels: some View {
        let b = bounds
        return VStack(alignment: .trailing) {
            Text(round1(b.high))
            Spacer()
            Text(round1((b.high + b.low) / 2))
            Spacer()
            Text(round1(b.low))
        }
        .font(.nunito(9.5, .heavy))
        .foregroundStyle(Theme.inkWhisper)
        .frame(height: 132)
    }

    private var plot: some View {
        Canvas { context, size in
            let values = filled
            let b = bounds
            let span = max(b.high - b.low, 0.001)
            let w = size.width, h = size.height

            func point(_ index: Int, _ value: Double) -> CGPoint {
                let x = values.count > 1 ? CGFloat(index) / CGFloat(values.count - 1) * w : w / 2
                let y = h - CGFloat((value - b.low) / span) * (h - 8) - 4
                return CGPoint(x: x, y: y)
            }

            for fraction in [0.0, 0.5, 1.0] {
                var grid = Path()
                let y = 4 + (h - 8) * fraction
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: w, y: y))
                context.stroke(grid, with: .color(Theme.chartGrid), lineWidth: 1)
            }

            guard values.count > 1 else { return }

            var area = Path()
            area.move(to: CGPoint(x: 0, y: h))
            for (i, v) in values.enumerated() { area.addLine(to: point(i, v)) }
            area.addLine(to: CGPoint(x: w, y: h))
            area.closeSubpath()
            context.fill(area, with: .color(Theme.chartArea))

            var line = Path()
            for (i, v) in values.enumerated() {
                let pt = point(i, v)
                if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
            }
            context.stroke(
                line,
                with: .color(Theme.tileGlyph),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )

            // A ring on every day an actual measurement was taken.
            for dot in realDots {
                let pt = point(dot.index, dot.value)
                let ring = Path(ellipseIn: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8))
                context.fill(ring, with: .color(.white))
                context.stroke(ring, with: .color(Theme.tileGlyph), lineWidth: 2.5)
            }
        }
    }

    /// Indices in the 30-day window where a real measurement was taken.
    private var realDots: [(index: Int, value: Double)] {
        points.compactMap { entry in
            let day = calendar.startOfDay(for: entry.date)
            guard let index = window.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) }) else { return nil }
            return (index, entry.value)
        }
    }

    private var dateAxis: some View {
        HStack {
            ForEach([0, 10, 20, days - 1], id: \.self) { index in
                Text(window[safe: index]?.formatted(.dateTime.day().month(.abbreviated)) ?? "")
                    .font(.nunito(9.5, .heavy))
                    .foregroundStyle(Theme.inkWhisper)
                if index != days - 1 { Spacer() }
            }
        }
    }

    private var trendLabel: String {
        guard let first = filled.first, let last = filled.last else { return "—" }
        let delta = (last - first * 1.0)
        let rounded = (delta * 10).rounded() / 10
        return "\(rounded > 0 ? "+" : "")\(round1(rounded)) \(unit) this month"
    }

    private var latestLabel: String {
        guard let last = points.sorted(by: { $0.date < $1.date }).last else { return "—" }
        return "\(round1(last.value)) \(unit)"
    }

    private var lastPointLabel: String {
        points.map(\.date).max()?.formatted(.dateTime.day().month(.abbreviated)) ?? "—"
    }

    private func round1(_ value: Double) -> String {
        let r = (value * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(format: "%.1f", r)
    }
}

extension Collection {
    /// Bounds-checked subscript — the charts index by day offset.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

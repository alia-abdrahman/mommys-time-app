import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleBlock.startTime, ascending: true)],
        animation: .default
    )
    private var allBlocks: FetchedResults<ScheduleBlock>

    @State private var showingAddBlock = false
    @State private var showingFindTime = false
    @State private var editingBlock: ScheduleBlock?
    @State private var selectedDate = Date()
    @State private var toast: String?

    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKeys.showGuide) private var showGuide = true

    @StateObject private var guide = GuideController(steps: [
        GuideStep(
            id: .addBlock,
            title: "Map out your day",
            message: "Add your kids' routines, chores and quiet times here. The more the app knows, the better it can find your me-time. 🌸"
        ),
        GuideStep(
            id: .findTime,
            title: "Find your time",
            message: "Once your day is mapped out, tap Find my time and the app spots the pockets of time that are just for you. ✨"
        ),
    ])

    private var dayBlocks: [(block: ScheduleBlock, start: Date, end: Date)] {
        allBlocks
            .compactMap { block in
                block.resolvedTimes(on: selectedDate).map { (block, $0.start, $0.end) }
            }
            .sorted { $0.1 < $1.1 }
    }

    private var intervals: [BlockInterval] {
        dayBlocks.map { BlockInterval(start: $0.start, end: $0.end, category: $0.block.blockCategory) }
    }

    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    private var isPast: Bool {
        Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: Date())
    }

    /// Past days are read-only for the schedule itself; today and future days
    /// can be added to, edited and searched for me-time.
    private var isEditable: Bool { !isPast }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScheduleDateCard(date: $selectedDate, hasBlocks: dayHasBlocks)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            if dayBlocks.isEmpty {
                ScrollView { emptyState }
            } else {
                ScrollView {
                    VStack(spacing: 9) {
                        ForEach(dayBlocks, id: \.block.objectID) { item in
                            BlockCard(block: item.block, start: item.start, end: item.end,
                                      onTap: { if isEditable { editingBlock = item.block } },
                                      onRemove: isEditable ? { delete(item.block) } : nil)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if isEditable { findMyTimeButton }
        }
        .sheet(isPresented: $showingAddBlock) {
            AddBlockSheet(day: selectedDate) { message in
                showToast(message)
            }
        }
        .sheet(isPresented: $showingFindTime) {
            FindTimeSheet(intervals: intervals, date: selectedDate) { message in
                showToast(message)
            }
        }
        .sheet(item: $editingBlock) { block in
            EditBlockSheet(block: block)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 190)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .guideOverlay(guide)
        .onAppear { maybeStartGuide() }
        .onChange(of: hasCompletedOnboarding) { _, done in
            if done { maybeStartGuide() }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("Schedule")
                .font(.baloo(20, heavy: true))
                .foregroundStyle(Theme.ink)
            HStack {
                if !isToday {
                    Button { withAnimation(.easeInOut) { selectedDate = Date() } } label: {
                        Text("Today")
                            .font(.nunito(15, .bold))
                            .foregroundStyle(Theme.roseText)
                    }
                }
                Spacer()
                if isEditable {
                    Button { showingAddBlock = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Theme.rose, in: Circle())
                            .shadow(color: Theme.rose.opacity(0.4), radius: 8, y: 6)
                    }
                    .buttonStyle(.plain)
                    .guideAnchor(.addBlock)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    // MARK: Find my time

    private var findMyTimeButton: some View {
        Button { showingFindTime = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Find my time")
                    .font(.baloo(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.rose, in: Capsule())
            .shadow(color: Theme.rose.opacity(0.4), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 22)
        .padding(.bottom, 74)
        .guideAnchor(.findTime)
    }

    // MARK: Empty state

    @ViewBuilder
    private var emptyState: some View {
        if isEditable {
            VStack(spacing: 14) {
                Text("Your day is a blank page")
                    .font(.baloo(21, heavy: true))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("Add your kids' routines, chores and appointments — then let the app find the pockets of time that belong to you.")
                    .font(.nunito(15))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button { showingAddBlock = true } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text("Add your first block").font(.nunito(14, .bold))
                    }
                    .foregroundStyle(Theme.roseText)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .background(.white, in: Capsule())
                    .shadow(color: Theme.cardShadow, radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .guideAnchor(.addBlock)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        } else {
            VStack(spacing: 12) {
                Text("Nothing was scheduled")
                    .font(.baloo(24, heavy: true))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("This day is in the past and has no blocks to show.")
                    .font(.nunito(16))
                    .foregroundStyle(Theme.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 40)
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }

    private func maybeStartGuide() {
        guard hasCompletedOnboarding, !guide.isActive else { return }
        guard !showingAddBlock, !showingFindTime, editingBlock == nil else { return }
        guard showGuide else { return }
        if allBlocks.isEmpty {
            guide.start()
        }
        showGuide = false
    }

    private func delete(_ block: ScheduleBlock) {
        withAnimation { context.delete(block) }
        try? context.save()
    }

    /// True when the given day has at least one block (for the week-strip dots).
    private func dayHasBlocks(_ day: Date) -> Bool {
        allBlocks.contains { $0.resolvedTimes(on: day) != nil }
    }
}

// MARK: - Date card with week strip

private struct ScheduleDateCard: View {
    @Binding var date: Date
    var hasBlocks: (Date) -> Bool = { _ in false }
    private let calendar = Calendar.current

    private var weekDates: [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text((relativeLabel ?? "").uppercased())
                .font(.nunito(11, .heavy))
                .tracking(1.2)
                .foregroundStyle(Color(hex: 0xC97B8C))
                .opacity(relativeLabel == nil ? 0 : 1)
            Text(date.formatted(.dateTime.weekday(.wide).day().month()))
                .font(.baloo(19, heavy: true))
                .foregroundStyle(Theme.ink)
                .padding(.top, 1)
                .padding(.bottom, 12)

            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.10), radius: 18, y: 6)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -40 { shiftWeek(by: 1) }
                    else if value.translation.width > 40 { shiftWeek(by: -1) }
                }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: date)
        let busy = hasBlocks(day)
        return VStack(spacing: 3) {
            Text(day.formatted(.dateTime.weekday(.narrow)))
                .font(.nunito(11, .bold))
                .foregroundStyle(isSelected ? .white : Color(hex: 0x7A6F64))
                .opacity(isSelected ? 1 : 0.65)
            Text(day.formatted(.dateTime.day()))
                .font(.nunito(15, .heavy))
                .foregroundStyle(isSelected ? .white : Color(hex: 0x7A6F64))
            Circle()
                .fill(dotColor(isSelected: isSelected, busy: busy))
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 9)
        .padding(.bottom, 7)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.rose)
                    .shadow(color: Theme.rose.opacity(0.38), radius: 14, y: 6)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeInOut) { date = day } }
    }

    private func dotColor(isSelected: Bool, busy: Bool) -> Color {
        if isSelected { return .white.opacity(busy ? 0.9 : 0.35) }
        return busy ? Color(hex: 0xE7C9A6) : .clear
    }

    private var relativeLabel: String? {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return nil
    }

    private func shiftWeek(by weeks: Int) {
        guard let newDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: date) else { return }
        withAnimation(.easeInOut) { date = newDate }
    }
}

// MARK: - Block card

struct BlockCard: View {
    @ObservedObject var block: ScheduleBlock
    let start: Date
    let end: Date
    var onTap: () -> Void = {}
    var onRemove: (() -> Void)? = nil

    private var timeLabel: String {
        let s = start.formatted(.dateTime.hour().minute())
        let e = end.formatted(.dateTime.hour().minute())
        let minutes = max(0, Int(end.timeIntervalSince(start) / 60))
        return "\(s) – \(e) · \(durationLabel(minutes))"
    }

    private func durationLabel(_ m: Int) -> String {
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(block.blockCategory.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title ?? "")
                    .font(.nunito(15, .heavy))
                    .foregroundStyle(Color(hex: 0x4A423B))
                Text(timeLabel)
                    .font(.nunito(12, .bold))
                    .foregroundStyle(Color(hex: 0x9A8D80))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            if block.blockCategory == .meTime, let session = block.session {
                CompletionButton(session: session)
            }

            if let onRemove {
                Button(action: onRemove) {
                    Text("×")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(Color(hex: 0xB7AA9B))
                        .frame(width: 26, height: 26)
                        .background(.white, in: Circle())
                        .overlay(Circle().stroke(Color(hex: 0x7A6248).opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }
}

private struct CompletionButton: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var session: MeTimeSession

    var body: some View {
        Button {
            session.completed.toggle()
            try? context.save()
        } label: {
            Image(systemName: session.completed ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(Theme.rose)
        }
        .buttonStyle(.plain)
    }
}

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
        NavigationStack {
            VStack(spacing: 0) {
                WeekStrip(date: $selectedDate)
                Group {
                    if dayBlocks.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(dayBlocks, id: \.block.objectID) { item in
                                BlockRow(block: item.block, start: item.start, end: item.end) {
                                    if isEditable { editingBlock = item.block }
                                }
                            }
                            .onDelete(perform: isEditable ? deleteBlocks : nil)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isToday {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Today") {
                            withAnimation(.easeInOut) { selectedDate = Date() }
                        }
                    }
                }
                if isEditable {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddBlock = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isEditable {
                    Button {
                        showingFindTime = true
                    } label: {
                        Label("Find my time", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .guideAnchor(.findTime)
                }
            }
            .sheet(isPresented: $showingAddBlock) {
                AddBlockSheet(day: selectedDate)
            }
            .sheet(isPresented: $showingFindTime) {
                FindTimeSheet(intervals: intervals, date: selectedDate)
            }
            .sheet(item: $editingBlock) { block in
                EditBlockSheet(block: block)
            }
        }
        .guideOverlay(guide)
        .onAppear { maybeStartGuide() }
        .onChange(of: hasCompletedOnboarding) { _, done in
            if done { maybeStartGuide() }
        }
    }

    private func maybeStartGuide() {
        guard hasCompletedOnboarding, !guide.isActive else { return }
        guard !showingAddBlock, !showingFindTime, editingBlock == nil else { return }
        guard showGuide else { return }
        // Show the tips only on the blank "main" page (a brand-new user with no
        // schedule yet), never over an existing schedule. Either way it's a
        // one-shot: the toggle turns itself off after this first eligible visit,
        // so it won't reappear unless switched back on in Settings.
        if allBlocks.isEmpty {
            guide.start()
        }
        showGuide = false
    }

    @ViewBuilder
    private var emptyState: some View {
        if isEditable {
            VStack(spacing: 12) {
                Text("🌸")
                    .font(.system(size: 56))
                Text("Your day is a blank page")
                    .font(.title3.bold())
                Text("Add your kids' routines, chores and appointments — then let the app find the pockets of time that belong to you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Add your first block") {
                    showingAddBlock = true
                }
                .buttonStyle(.bordered)
                .guideAnchor(.addBlock)
            }
            .padding(32)
            .frame(maxHeight: .infinity)
        } else {
            VStack(spacing: 12) {
                Text("🗓️")
                    .font(.system(size: 56))
                Text("Nothing was scheduled")
                    .font(.title3.bold())
                Text("This day is in the past and has no blocks to show.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxHeight: .infinity)
        }
    }

    private func deleteBlocks(at offsets: IndexSet) {
        for index in offsets {
            context.delete(dayBlocks[index].block)
        }
        try? context.save()
    }
}

private struct WeekStrip: View {
    @Binding var date: Date

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                if let relative = relativeLabel {
                    Text(relative.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.pink)
                }
                Text(date.formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.title3.bold())
            }

            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -40 {
                        shiftWeek(by: 1)
                    } else if value.translation.width > 40 {
                        shiftWeek(by: -1)
                    }
                }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: date)
        let isToday = calendar.isDateInToday(day)
        return VStack(spacing: 6) {
            Text(day.formatted(.dateTime.weekday(.narrow)))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(day.formatted(.dateTime.day()))
                .font(.subheadline.weight(isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : (isToday ? .pink : .primary))
                .frame(width: 36, height: 36)
                .background {
                    if isSelected {
                        Circle().fill(.pink)
                    } else if isToday {
                        Circle().fill(.pink.opacity(0.15))
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut) { date = day }
        }
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

struct BlockRow: View {
    @ObservedObject var block: ScheduleBlock
    let start: Date
    let end: Date
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .trailing) {
                    Text(start, format: .dateTime.hour().minute())
                        .font(.subheadline.bold())
                    Text(end, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 70, alignment: .trailing)

                RoundedRectangle(cornerRadius: 2)
                    .fill(block.blockCategory.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(block.title ?? "")
                        .font(.body)
                    Label(block.blockCategory.label, systemImage: block.blockCategory.systemImage)
                        .font(.caption)
                        .foregroundStyle(block.blockCategory.color)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            if block.blockCategory == .meTime, let session = block.session {
                CompletionButton(session: session)
            }
        }
        .padding(.vertical, 4)
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
                .foregroundStyle(.pink)
                .padding(.leading, 8)
        }
        .buttonStyle(.plain)
    }
}

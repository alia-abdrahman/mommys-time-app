import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleBlock.startTime, ascending: true)],
        animation: .default
    )
    private var allBlocks: FetchedResults<ScheduleBlock>

    @Environment(\.dismiss) private var dismiss

    @State private var showingAddBlock = false
    @State private var editingBlock: ScheduleBlock?
    @State private var selectedDate = Date()
    @State private var calendarMode = CalendarMode.week
    @State private var toast: String?

    private var dayBlocks: [(block: ScheduleBlock, start: Date, end: Date)] {
        allBlocks
            .compactMap { block in
                block.resolvedTimes(on: selectedDate).map { (block, $0.start, $0.end) }
            }
            .sorted { $0.1 < $1.1 }
    }

    private var isPast: Bool {
        Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: Date())
    }

    /// Past days are read-only for the schedule itself; today and future days
    /// can be added to, edited and searched for me-time.
    private var isEditable: Bool { !isPast }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScheduleCalendarCard(date: $selectedDate, mode: $calendarMode, hasEntries: dayHasBlocks)
                .padding(.horizontal, 16)
                .padding(.top, 12)

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
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddBlock) {
            AddBlockSheet(day: selectedDate) { message in
                showToast(message)
            }
        }
        .sheet(item: $editingBlock) { block in
            EditBlockSheet(block: block)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        DetailHeader(title: L.Schedule.title, onBack: { dismiss() }) {
            if isEditable {
                CircleAddButton { showingAddBlock = true }
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Empty state

    @ViewBuilder
    private var emptyState: some View {
        if isEditable {
            VStack(spacing: 14) {
                Text(L.Schedule.emptyTitle)
                    .font(.baloo(21, heavy: true))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(L.Schedule.emptyBody)
                    .font(.nunito(14, .semibold))
                    .lineSpacing(6)
                    .foregroundStyle(Theme.inkFaint)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button { showingAddBlock = true } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text(L.Schedule.emptyCTA).font(.nunito(13, .heavy))
                    }
                    .foregroundStyle(Theme.roseText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(.white, in: Capsule())
                    .shadow(color: Theme.cardShadow, radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 34)
            .padding(.top, 22)
        } else {
            VStack(spacing: 12) {
                Text(L.Schedule.pastTitle)
                    .font(.baloo(24, heavy: true))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(L.Schedule.pastBody)
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

    private func delete(_ block: ScheduleBlock) {
        withAnimation { context.delete(block) }
        try? context.save()
    }

    /// True when the given day has at least one block (for the week-strip dots).
    private func dayHasBlocks(_ day: Date) -> Bool {
        allBlocks.contains { $0.resolvedTimes(on: day) != nil }
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
        return L.Schedule.blockTime(s, e, L.Duration.compact(minutes))
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
                    Text(L.Glyph.remove)
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

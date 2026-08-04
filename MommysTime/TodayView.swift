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

    private var todaysBlocks: [(block: ScheduleBlock, start: Date, end: Date)] {
        let today = Date()
        return allBlocks
            .compactMap { block in
                block.resolvedTimes(on: today).map { (block, $0.start, $0.end) }
            }
            .sorted { $0.1 < $1.1 }
    }

    private var intervals: [BlockInterval] {
        todaysBlocks.map { BlockInterval(start: $0.start, end: $0.end, category: $0.block.blockCategory) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if todaysBlocks.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(todaysBlocks, id: \.block.objectID) { item in
                            BlockRow(block: item.block, start: item.start, end: item.end) {
                                editingBlock = item.block
                            }
                        }
                        .onDelete(perform: deleteBlocks)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(Date().formatted(.dateTime.weekday(.wide).day().month()))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBlock = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
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
            }
            .sheet(isPresented: $showingAddBlock) {
                AddBlockSheet()
            }
            .sheet(isPresented: $showingFindTime) {
                FindTimeSheet(intervals: intervals)
            }
            .sheet(item: $editingBlock) { block in
                EditBlockSheet(block: block)
            }
        }
    }

    private var emptyState: some View {
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
        }
        .padding(32)
    }

    private func deleteBlocks(at offsets: IndexSet) {
        for index in offsets {
            context.delete(todaysBlocks[index].block)
        }
        try? context.save()
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

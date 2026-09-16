import SwiftUI

struct EditBlockSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var block: ScheduleBlock

    @State private var title: String
    @State private var category: BlockCategory
    @State private var start: Date
    @State private var end: Date
    @State private var repeatsDaily: Bool
    @State private var showingDeleteConfirmation = false

    init(block: ScheduleBlock) {
        self.block = block
        _title = State(initialValue: block.title ?? "")
        _category = State(initialValue: block.blockCategory)
        _start = State(initialValue: block.startTime ?? Date())
        _end = State(initialValue: block.endTime ?? Date().addingTimeInterval(60 * 60))
        _repeatsDaily = State(initialValue: block.repeatsDaily)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L.EditBlock.details) {
                    TextField(L.AddBlock.titlePlaceholder, text: $title)
                    if category == .meTime {
                        Label(BlockCategory.meTime.label, systemImage: BlockCategory.meTime.systemImage)
                            .foregroundStyle(BlockCategory.meTime.color)
                    } else {
                        Picker(L.EditBlock.category, selection: $category) {
                            ForEach(BlockCategory.allCases.filter { $0 != .meTime }) { cat in
                                Label(cat.label, systemImage: cat.systemImage).tag(cat)
                            }
                        }
                    }
                    DatePicker(L.EditBlock.starts, selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker(L.EditBlock.ends, selection: $end, displayedComponents: .hourAndMinute)
                    Toggle(L.EditBlock.repeatsDaily, isOn: $repeatsDaily)
                }

                if category == .quiet {
                    Section {
                        Text(L.EditBlock.quietHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(L.EditBlock.deleteButton, role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L.EditBlock.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.Common.save) { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || end <= start)
                }
            }
            .confirmationDialog(
                deleteConfirmationTitle,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L.Common.delete, role: .destructive) { deleteBlock() }
                Button(L.Common.cancel, role: .cancel) {}
            } message: {
                Text(deleteConfirmationMessage)
            }
        }
    }

    private var deleteConfirmationTitle: String {
        repeatsDaily ? L.EditBlock.deleteRepeatingTitle : L.EditBlock.deleteTitle
    }

    private var deleteConfirmationMessage: String {
        if category == .meTime { return L.EditBlock.deleteMeTimeMessage }
        if repeatsDaily { return L.EditBlock.deleteRepeatingMessage }
        return L.EditBlock.deleteMessage
    }

    private func save() {
        block.title = title.trimmingCharacters(in: .whitespaces)
        block.category = category.rawValue
        block.startTime = start
        block.endTime = end
        block.repeatsDaily = repeatsDaily
        try? context.save()
        dismiss()
    }

    private func deleteBlock() {
        context.delete(block)
        try? context.save()
        dismiss()
    }
}

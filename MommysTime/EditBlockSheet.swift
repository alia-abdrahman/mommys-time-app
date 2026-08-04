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
                Section("Details") {
                    TextField("Title (e.g. Nap time)", text: $title)
                    if category == .meTime {
                        Label(BlockCategory.meTime.label, systemImage: BlockCategory.meTime.systemImage)
                            .foregroundStyle(BlockCategory.meTime.color)
                    } else {
                        Picker("Category", selection: $category) {
                            ForEach(BlockCategory.allCases.filter { $0 != .meTime }) { cat in
                                Label(cat.label, systemImage: cat.systemImage).tag(cat)
                            }
                        }
                    }
                    DatePicker("Starts", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("Ends", selection: $end, displayedComponents: .hourAndMinute)
                    Toggle("Repeats every day", isOn: $repeatsDaily)
                }

                if category == .quiet {
                    Section {
                        Text("Quiet time (naps, school hours) counts as free time for YOU — the app will favour these windows when finding your me-time. 🌙")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Delete block", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || end <= start)
                }
            }
            .confirmationDialog(
                deleteConfirmationTitle,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteBlock() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(deleteConfirmationMessage)
            }
        }
    }

    private var deleteConfirmationTitle: String {
        repeatsDaily ? "Delete this repeating block?" : "Delete this block?"
    }

    private var deleteConfirmationMessage: String {
        if category == .meTime {
            return "This me-time session will no longer count towards your goal."
        }
        if repeatsDaily {
            return "It will be removed from every day, not just today."
        }
        return "This can't be undone."
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

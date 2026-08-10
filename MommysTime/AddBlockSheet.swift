import SwiftUI

struct AddBlockSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: BlockCategory = .kids
    @State private var start: Date
    @State private var end: Date
    @State private var repeatsDaily = false

    private let day: Date

    init(day: Date = Date()) {
        self.day = day
        let calendar = Calendar.current
        let now = Date()
        let time = calendar.dateComponents([.hour, .minute], from: now)
        let base = calendar.date(
            bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: day
        ) ?? day
        _start = State(initialValue: base)
        _end = State(initialValue: base.addingTimeInterval(60 * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick add") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(BlockTemplate.all) { template in
                                Button {
                                    apply(template)
                                } label: {
                                    Label(template.title, systemImage: template.category.systemImage)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(template.category.color.opacity(0.15))
                                        .foregroundStyle(template.category.color)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Details") {
                    TextField("Title (e.g. Nap time)", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(BlockCategory.allCases.filter { $0 != .meTime }) { cat in
                            Label(cat.label, systemImage: cat.systemImage).tag(cat)
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
            }
            .navigationTitle("Add to your day")
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
        }
    }

    private func apply(_ template: BlockTemplate) {
        title = template.title
        category = template.category
        let calendar = Calendar.current
        if let s = calendar.date(bySettingHour: template.startHour, minute: template.startMinute, second: 0, of: day) {
            start = s
            end = s.addingTimeInterval(Double(template.durationMinutes) * 60)
        }
    }

    private func save() {
        let block = ScheduleBlock(context: context)
        block.id = UUID()
        block.title = title.trimmingCharacters(in: .whitespaces)
        block.category = category.rawValue
        block.startTime = start
        block.endTime = end
        block.repeatsDaily = repeatsDaily
        try? context.save()
        dismiss()
    }
}

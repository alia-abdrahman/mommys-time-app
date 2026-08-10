import SwiftUI
import CoreData
import Charts

struct GrowthLogView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GrowthEntry.date, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<GrowthEntry>

    @State private var showingAdd = false
    @State private var editing: GrowthEntry?

    private var latest: GrowthEntry? { entries.first }

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        latestCard
                        if entries.count > 1 { weightChart }
                        history
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Growth Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { GrowthSheet() }
        .sheet(item: $editing) { entry in GrowthSheet(entry: entry) }
    }

    private var latestCard: some View {
        VStack(spacing: 12) {
            Text("Latest measurements")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                measure(value: latest?.weightKg ?? 0, unit: "kg", label: "Weight")
                Divider().frame(height: 40)
                measure(value: latest?.heightCm ?? 0, unit: "cm", label: "Height")
                Divider().frame(height: 40)
                measure(value: latest?.headCm ?? 0, unit: "cm", label: "Head")
            }
            if let date = latest?.date {
                Text("as of \(date.formatted(.dateTime.day().month().year()))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
    }

    private func measure(value: Double, unit: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value > 0 ? "\(value.formatted(.number.precision(.fractionLength(0...1))))" : "—")
                .font(.title2.bold())
                .foregroundStyle(.indigo)
            Text("\(label) (\(unit))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight over time").font(.headline)
            Chart(entries.filter { $0.weightKg > 0 }, id: \.objectID) { entry in
                LineMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Weight", entry.weightKg)
                )
                .foregroundStyle(.indigo)
                PointMark(
                    x: .value("Date", entry.date ?? Date()),
                    y: .value("Weight", entry.weightKg)
                )
                .foregroundStyle(.indigo)
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History").font(.headline).foregroundStyle(.secondary)
            ForEach(entries, id: \.objectID) { entry in
                GrowthCard(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture { editing = entry }
                    .contextMenu {
                        Button("Edit") { editing = entry }
                        Button("Delete", role: .destructive) { delete(entry) }
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("📏")
                .font(.system(size: 56))
            Text("No measurements yet")
                .font(.title3.bold())
            Text("Record your baby's weight, height and head size to watch them grow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add a measurement") { showingAdd = true }
                .buttonStyle(.bordered)
        }
        .padding(32)
    }

    private func delete(_ entry: GrowthEntry) {
        context.delete(entry)
        try? context.save()
    }
}

private struct GrowthCard: View {
    @ObservedObject var entry: GrowthEntry

    private var detail: String {
        var parts: [String] = []
        if entry.weightKg > 0 { parts.append("\(entry.weightKg.formatted(.number.precision(.fractionLength(0...1)))) kg") }
        if entry.heightCm > 0 { parts.append("\(entry.heightCm.formatted(.number.precision(.fractionLength(0...1)))) cm") }
        if entry.headCm > 0 { parts.append("head \(entry.headCm.formatted(.number.precision(.fractionLength(0...1)))) cm") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "ruler.fill")
                .foregroundStyle(.indigo)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                if let date = entry.date {
                    Text(date.formatted(.dateTime.day().month().year()))
                        .font(.body)
                }
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct GrowthSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: GrowthEntry?

    @State private var date: Date
    @State private var weight: Double
    @State private var height: Double
    @State private var head: Double
    @State private var notes: String
    @State private var showingDeleteConfirmation = false

    init(entry: GrowthEntry? = nil) {
        self.entry = entry
        _date = State(initialValue: entry?.date ?? Date())
        _weight = State(initialValue: entry?.weightKg ?? 0)
        _height = State(initialValue: entry?.heightCm ?? 0)
        _head = State(initialValue: entry?.headCm ?? 0)
        _notes = State(initialValue: entry?.notes ?? "")
    }

    private var isEditing: Bool { entry != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Measurement") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    measureRow(label: "Weight", unit: "kg", value: $weight)
                    measureRow(label: "Height", unit: "cm", value: $height)
                    measureRow(label: "Head", unit: "cm", value: $head)
                }
                Section("Notes") {
                    TextField("Anything to note…", text: $notes, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                }
                if isEditing {
                    Section {
                        Button("Delete measurement", role: .destructive) { showingDeleteConfirmation = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Measurement" : "New Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .confirmationDialog("Delete this measurement?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteEntry() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func measureRow(label: String, unit: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    private func save() {
        let target = entry ?? GrowthEntry(context: context)
        if entry == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.date = date
        target.weightKg = weight
        target.heightCm = height
        target.headCm = head
        target.notes = notes
        try? context.save()
        dismiss()
    }

    private func deleteEntry() {
        if let entry {
            context.delete(entry)
            try? context.save()
        }
        dismiss()
    }
}

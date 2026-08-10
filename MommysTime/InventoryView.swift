import SwiftUI
import CoreData

/// Common baby-supply categories used for grouping and the add/edit picker.
enum InventoryCategory {
    static let all = ["Diapers", "Wipes", "Formula", "Food", "Clothes", "Health", "Toys", "Other"]

    static func order(_ name: String) -> Int {
        all.firstIndex(of: name) ?? all.count
    }
}

struct InventoryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<InventoryItem>

    @State private var showingAdd = false
    @State private var editing: InventoryItem?

    private var grouped: [(category: String, items: [InventoryItem])] {
        let dict = Dictionary(grouping: items) { $0.category ?? "Other" }
        return dict.keys
            .sorted { InventoryCategory.order($0) < InventoryCategory.order($1) }
            .map { key in (key, dict[key] ?? []) }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(grouped, id: \.category) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.category)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                ForEach(group.items, id: \.objectID) { item in
                                    InventoryCard(item: item)
                                        .contentShape(Rectangle())
                                        .onTapGesture { editing = item }
                                        .contextMenu {
                                            Button("Edit") { editing = item }
                                            Button("Delete", role: .destructive) { delete(item) }
                                        }
                                }
                            }
                        }
                        addCard
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            InventorySheet()
        }
        .sheet(item: $editing) { item in
            InventorySheet(item: item)
        }
    }

    private var addCard: some View {
        Button { showingAdd = true } label: {
            HStack {
                Spacer()
                Label("Add item", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.teal)
                Spacer()
            }
            .padding(.vertical, 18)
            .background(Color.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.teal.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("📦")
                .font(.system(size: 56))
            Text("Your inventory is empty")
                .font(.title3.bold())
            Text("Keep track of diapers, wipes, formula and more — with quantities and a link to reorder when you're running low.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add your first item") { showingAdd = true }
                .buttonStyle(.bordered)
        }
        .padding(32)
    }

    private func delete(_ item: InventoryItem) {
        context.delete(item)
        try? context.save()
    }
}

private struct InventoryCard: View {
    @ObservedObject var item: InventoryItem
    @Environment(\.openURL) private var openURL

    private var url: URL? {
        guard let link = item.link, !link.isEmpty else { return nil }
        return URL(string: link)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "")
                    .font(.headline)
                if url != nil {
                    Label("Reorder link", systemImage: "link")
                        .font(.caption2)
                        .foregroundStyle(.teal)
                }
            }

            Spacer()

            Text("×\(item.quantity)")
                .font(.title3.bold())
                .foregroundStyle(.teal)

            if let url {
                Button { openURL(url) } label: {
                    Image(systemName: "cart.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.teal, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct InventorySheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let item: InventoryItem?

    @State private var name: String
    @State private var quantity: Int
    @State private var category: String
    @State private var link: String
    @State private var showingDeleteConfirmation = false

    init(item: InventoryItem? = nil) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _quantity = State(initialValue: Int(item?.quantity ?? 1))
        _category = State(initialValue: item?.category ?? "Diapers")
        _link = State(initialValue: item?.link ?? "")
    }

    private var isEditing: Bool { item != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name (e.g. Diapers)", text: $name)
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("0", value: $quantity, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Stepper("", value: $quantity, in: 0...999)
                            .labelsHidden()
                    }
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.all, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section {
                    TextField("https://…", text: $link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Reorder link")
                } footer: {
                    Text("Paste a Shopee or other online shop link to reorder this item quickly.")
                }
                if isEditing {
                    Section {
                        Button("Delete item", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "Delete this item?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteItem() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let target = item ?? InventoryItem(context: context)
        if item == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.quantity = Int32(quantity)
        target.category = category
        target.link = link.trimmingCharacters(in: .whitespaces)
        try? context.save()
        dismiss()
    }

    private func deleteItem() {
        if let item {
            context.delete(item)
            try? context.save()
        }
        dismiss()
    }
}

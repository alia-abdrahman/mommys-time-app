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
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<InventoryItem>

    @State private var showingAdd = false
    @State private var editing: InventoryItem?
    @State private var toast: String?

    private var grouped: [(category: String, items: [InventoryItem])] {
        let dict = Dictionary(grouping: items) { $0.category ?? "Other" }
        return dict.keys
            .sorted { InventoryCategory.order($0) < InventoryCategory.order($1) }
            .map { key in (key, dict[key] ?? []) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if items.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(grouped.enumerated()), id: \.element.category) { index, group in
                            Text(group.category.uppercased())
                                .font(.nunito(12, .heavy))
                                .tracking(0.8)
                                .foregroundStyle(IN.textMuted)
                                .padding(.top, index == 0 ? 0 : 18)
                                .padding(.bottom, 7)
                            VStack(spacing: 9) {
                                ForEach(group.items, id: \.objectID) { item in
                                    InventoryItemCard(item: item) { editing = item }
                                        .contextMenu {
                                            Button("Edit") { editing = item }
                                            Button("Delete", role: .destructive) { delete(item) }
                                        }
                                }
                            }

                            if index == grouped.count - 1 { addCard.padding(.top, 18) }
                        }
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 96)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IN.sheetBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) {
            InventorySheet { showToast($0) }
        }
        .sheet(item: $editing) { item in
            InventorySheet(item: item) { showToast($0) }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 190)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Inventory")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(IN.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(IN.backIcon)
                        .frame(width: 38, height: 38)
                        .background(.white, in: Circle())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }

    private var addCard: some View {
        Button { showingAdd = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                Text("Add item").font(.nunito(14, .heavy))
            }
            .foregroundStyle(IN.sageText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(IN.sageFill.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(IN.sageAccent.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Text("Your inventory is empty")
                .font(.baloo(21, heavy: true))
                .foregroundStyle(IN.textPrimary)
            Text("Keep track of diapers, wipes, formula and more — with quantities and a reorder link when you're running low.")
                .font(.nunito(15))
                .foregroundStyle(IN.textMuted)
                .multilineTextAlignment(.center)
            Button { showingAdd = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                    Text("Add your first item").font(.nunito(14, .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(IN.sageAccent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 34)
    }

    private func delete(_ item: InventoryItem) {
        context.delete(item)
        try? context.save()
    }
}

private struct InventoryItemCard: View {
    @ObservedObject var item: InventoryItem
    var onTap: () -> Void
    @Environment(\.openURL) private var openURL

    private var url: URL? {
        guard let link = item.link, !link.isEmpty else { return nil }
        return URL(string: link)
    }
    private var isLow: Bool { item.quantity <= item.threshold }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "")
                    .font(.nunito(16, .heavy))
                    .foregroundStyle(IN.sageDeep)
                if url != nil {
                    Text("Reorder link")
                        .font(.nunito(12, .bold))
                        .foregroundStyle(IN.sageMid)
                }
            }
            Spacer(minLength: 0)
            Text("×\(item.quantity)")
                .font(.nunito(17, .heavy))
                .foregroundStyle(isLow ? IN.lowStock : IN.sageText)
            if let url {
                Button { openURL(url) } label: {
                    Image(systemName: "cart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(IN.sageAccent, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 18)
        .padding(.trailing, url == nil ? 18 : 14)
        .padding(.vertical, url == nil ? 18 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(IN.sageFill, in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture(perform: onTap)
    }
}

struct InventorySheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let item: InventoryItem?
    var onToast: (String) -> Void = { _ in }

    @State private var name: String
    @State private var quantity: Int
    @State private var threshold: Int
    @State private var remindReorder: Bool
    @State private var category: String
    @State private var link: String
    @State private var nameToast = false
    @State private var showingRemoveConfirmation = false

    private let chips = ["Diapers", "Wipes", "Formula", "Clothes", "Medicine"]

    init(item: InventoryItem? = nil, onToast: @escaping (String) -> Void = { _ in }) {
        self.item = item
        self.onToast = onToast
        _name = State(initialValue: item?.name ?? "")
        _quantity = State(initialValue: Int(item?.quantity ?? 1))
        _threshold = State(initialValue: Int(item?.threshold ?? 6))
        _remindReorder = State(initialValue: item?.remindReorder ?? false)
        _category = State(initialValue: item?.category ?? "Diapers")
        _link = State(initialValue: item?.link ?? "")
    }

    private var isEditing: Bool { item != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var statusText: String {
        quantity <= threshold ? "Running low — time to reorder" : "Plenty in stock"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                itemHeaderCard.padding(.top, 20)

                sectionLabel("ITEM").padding(.top, 20).padding(.bottom, 8)
                itemCard

                sectionLabel("CATEGORY").padding(.top, 20).padding(.bottom, 8)
                categoryChips

                if isEditing { removeRow.padding(.top, 22) }
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(IN.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(IN.sheetBg)
        .presentationDragIndicator(.hidden)
        .overlay(alignment: .bottom) {
            if nameToast {
                Toast(text: "Give the item a name")
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .confirmationDialog(
            "Remove \(name.isEmpty ? "this item" : name) from inventory?",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { removeItem() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit Item" : "New Item")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(IN.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(IN.textSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : IN.disabledText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 18)
                        .background(canSave ? IN.accentRose : IN.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Item header card

    private var itemHeaderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(IN.plusGreen)
                .frame(width: 48, height: 48)
                .background(.white, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Item" : name)
                    .font(.baloo(19, heavy: true))
                    .foregroundStyle(IN.sageDeep)
                Text(statusText)
                    .font(.nunito(12.5, .bold))
                    .foregroundStyle(IN.sageMid)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(IN.sageFill, in: RoundedRectangle(cornerRadius: 26))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy))
            .tracking(0.8)
            .foregroundStyle(IN.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Item card

    private var itemCard: some View {
        VStack(spacing: 0) {
            TextField("Item name", text: $name)
                .font(.nunito(15, .bold))
                .foregroundStyle(IN.textPrimary)
                .tint(IN.plusGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)

            rowDivider

            HStack {
                Text("In stock").font(.nunito(15, .bold)).foregroundStyle(IN.textPrimary)
                Spacer()
                stepper(value: $quantity, range: 0...999)
            }
            .padding(.vertical, 12)

            rowDivider

            HStack {
                Text("Warn me below").font(.nunito(15, .bold)).foregroundStyle(IN.textPrimary)
                Spacer()
                stepper(value: $threshold, range: 0...99)
            }
            .padding(.vertical, 12)

            rowDivider

            HStack {
                Text("Remind me to reorder").font(.nunito(15, .bold)).foregroundStyle(IN.textPrimary)
                Spacer()
                toggle
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func stepper(value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 0) {
            Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                Text("−").font(.nunito(16, .heavy)).foregroundStyle(IN.textSecondary)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
            Text("×\(value.wrappedValue)")
                .font(.nunito(13, .heavy))
                .foregroundStyle(IN.valueText)
                .frame(minWidth: 66)
            Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                Text("+").font(.nunito(16, .heavy)).foregroundStyle(IN.plusGreen)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(IN.fieldFill, in: Capsule())
    }

    private var toggle: some View {
        Button { remindReorder.toggle() } label: {
            ZStack(alignment: remindReorder ? .trailing : .leading) {
                Capsule().fill(remindReorder ? IN.toggleOn : IN.toggleOff)
                    .frame(width: 50, height: 30)
                Circle().fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2.5, y: 2)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: remindReorder)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color(hex: 0x7A6248).opacity(0.1)).frame(height: 1)
    }

    // MARK: Category chips

    private var categoryChips: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(chips, id: \.self) { chip in
                let selected = chip == category
                Button { category = chip } label: {
                    Text(chip)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(selected ? .white : IN.sageText)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(selected ? IN.sageAccent : IN.sageFill, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Remove row

    private var removeRow: some View {
        Button { showingRemoveConfirmation = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                Text("Remove from inventory")
                    .font(.nunito(14, .heavy))
            }
            .foregroundStyle(IN.destructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .background(.white, in: RoundedRectangle(cornerRadius: 26))
            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: Logic

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation { nameToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { nameToast = false }
            }
            return
        }
        let target = item ?? InventoryItem(context: context)
        if item == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.name = trimmed
        target.quantity = Int32(quantity)
        target.threshold = Int32(threshold)
        target.remindReorder = remindReorder
        target.category = category
        try? context.save()
        onToast(isEditing ? "\(trimmed) updated" : "\(trimmed) added")
        dismiss()
    }

    private func removeItem() {
        let removed = name.trimmingCharacters(in: .whitespaces)
        if let item {
            context.delete(item)
            try? context.save()
        }
        onToast(removed.isEmpty ? "Item removed" : "\(removed) removed")
        dismiss()
    }
}

// MARK: - Edit Item sheet palette

private enum IN {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let sageFill = Color(hex: 0xDFEDE5)
    static let sageText = Color(hex: 0x4E7D68)
    static let sageDeep = Color(hex: 0x3F5B4E)
    static let sageMid = Color(hex: 0x6E9C87)
    static let sageAccent = Color(hex: 0x7FBFAE)
    static let plusGreen = Color(hex: 0x4E9E86)
    static let lowStock = Color(hex: 0xC08A64)
    static let backIcon = Color(hex: 0x8B7F72)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let accentRose = Color(hex: 0xD98FA0)
    static let destructive = Color(hex: 0xC4788C)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = Color(hex: 0x7FBFAE)
}

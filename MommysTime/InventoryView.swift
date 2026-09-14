import SwiftUI
import CoreData
import PhotosUI

/// What you keep running out of — one flat list, quantity on the left, a refill
/// warning when stock drops to the threshold.
struct InventoryView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<InventoryItem>

    @State private var filter = Filter.all
    @State private var editing: InventoryItem?
    @State private var creating = false
    @State private var toast: String?

    private enum Filter: String, CaseIterable {
        case all = "All", low = "Needs refill"
    }

    private var lowItems: [InventoryItem] {
        items.filter { $0.quantity <= $0.threshold }
    }

    private var shown: [InventoryItem] {
        filter == .low ? lowItems : Array(items)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    filterPills
                    countRow
                    listCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $creating) { InventorySheet(onToast: showToast) }
        .sheet(item: $editing) { item in InventorySheet(item: item, onToast: showToast) }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        DetailHeader(title: "Inventory", onBack: { dismiss() }) {
            CircleAddButton { creating = true }
        }
        .padding(.top, 8)
    }

    // MARK: Filter + counts

    private var filterPills: some View {
        HStack(spacing: 4) {
            ForEach(Filter.allCases, id: \.self) { f in
                let on = filter == f
                Button { withAnimation(.easeInOut(duration: 0.18)) { filter = f } } label: {
                    Text(f.rawValue)
                        .font(.nunito(12.5, .heavy))
                        .foregroundStyle(on ? Theme.roseText : Theme.inkFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if on {
                                Capsule().fill(.white)
                                    .shadow(color: Color(hex: 0x7A6248).opacity(0.14), radius: 4, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.field, in: Capsule())
    }

    private var countRow: some View {
        HStack {
            Text("\(items.count) \(items.count == 1 ? "ITEM" : "ITEMS")")
                .font(.nunito(10.5, .heavy))
                .tracking(0.9)
                .foregroundStyle(Theme.inkMuted)
            Spacer()
            Text(lowItems.isEmpty ? "ALL STOCKED" : "\(lowItems.count) NEEDS REFILL")
                .font(.nunito(10.5, .heavy))
                .tracking(0.9)
                .foregroundStyle(Theme.roseDeep)
        }
        .padding(.horizontal, 6)
        .padding(.top, 12)
        .padding(.bottom, 7)
    }

    // MARK: List

    private var listCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.element.objectID) { index, item in
                if index > 0 { CardDivider() }
                InventoryRow(item: item) { editing = item }
                    .contextMenu {
                        Button("Edit") { editing = item }
                        Button("Delete", role: .destructive) { delete(item) }
                    }
            }
            if shown.isEmpty { emptyRow }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 8, y: 4)
    }

    private var emptyRow: some View {
        VStack(spacing: 5) {
            Text(filter == .low ? "Nothing needs refilling" : "Nothing tracked yet")
                .font(.baloo(16, heavy: true))
                .foregroundStyle(Theme.ink)
            Text(filter == .low
                 ? "Every item is above its warning level."
                 : "Add whatever you keep running out of — and paste the link you reorder it from.")
                .font(.nunito(12.5, .semibold))
                .lineSpacing(5)
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 22)
    }

    private func delete(_ item: InventoryItem) {
        context.delete(item)
        try? context.save()
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Row

private struct InventoryRow: View {
    @ObservedObject var item: InventoryItem
    var onTap: () -> Void

    private var isLow: Bool { item.quantity <= item.threshold }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    Text("\(item.quantity)")
                        .font(.nunito(15, .heavy))
                    Text("LEFT")
                        .font(.nunito(8, .heavy))
                        .tracking(0.5)
                        .opacity(0.75)
                }
                .foregroundStyle(isLow ? Theme.roseLabel : Color(hex: 0xA8814F))
                .frame(width: 42, height: 42)
                .background(
                    isLow ? Theme.roseBadgeBg : Theme.peach,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

                Text(item.name ?? "")
                    .font(.nunito(14.5, .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if isLow {
                    Text("NEEDS REFILL")
                        .font(.nunito(9, .heavy))
                        .tracking(0.3)
                        .foregroundStyle(Theme.roseLabel)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 1)
                        .background(Theme.roseBadgeBg, in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.roseBadgeBorder, lineWidth: 1.5))
                        .fixedSize()
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.chevron)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isLow ? Color(hex: 0xFFFBF6) : .white)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item detail

struct InventorySheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let item: InventoryItem?
    var onToast: (String) -> Void = { _ in }

    @State private var name: String
    @State private var quantity: Int
    @State private var remindReorder: Bool
    @State private var link: String
    @State private var photo: Data?
    @State private var pickerItem: PhotosPickerItem?

    init(item: InventoryItem? = nil, onToast: @escaping (String) -> Void = { _ in }) {
        self.item = item
        self.onToast = onToast
        _name = State(initialValue: item?.name ?? "")
        _quantity = State(initialValue: Int(item?.quantity ?? 1))
        _remindReorder = State(initialValue: item?.remindReorder ?? false)
        _link = State(initialValue: item?.link ?? "")
        _photo = State(initialValue: item?.photo)
    }

    private var isEditing: Bool { item != nil }
    private var canSave: Bool { !name.isBlank }
    private var url: URL? {
        let trimmed = link.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: isEditing ? "Edit item" : "New item",
                            enabled: canSave,
                            onCancel: { dismiss() }, onConfirm: save)

                hero.padding(.top, 20)

                SectionLabel("ITEM").padding(.top, 20).padding(.bottom, 8)
                itemCard

                SectionLabel("PHOTO").padding(.top, 20).padding(.bottom, 8)
                photoCard
                Text("A photo helps you spot the exact brand next time you reorder.")
                    .font(.nunito(11.5, .semibold))
                    .lineSpacing(4)
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                if isEditing { removeButton.padding(.top, 22) }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(Theme.canvas)
        .presentationBackground(Theme.canvas)
        .presentationDragIndicator(.hidden)
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            photo = try? await pickerItem.loadTransferable(type: Data.self)
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            Image("icon-cart")
                .renderingMode(.original)
                .resizable().scaledToFit()
                .frame(width: 22, height: 22)
                .frame(width: 48, height: 48)
                .background(.white, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isBlank ? "New item" : name)
                    .font(.baloo(19, heavy: true))
                    .foregroundStyle(Theme.roseInk)
                    .lineLimit(1)
                Text("×\(quantity) on hand")
                    .font(.nunito(12.5, .bold))
                    .foregroundStyle(Theme.roseDeep)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.rosePillBg, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var itemCard: some View {
        VStack(spacing: 0) {
            TextField("Item name", text: $name)
                .font(.nunito(15, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 14)
            CardDivider()

            HStack {
                Text("In stock")
                    .font(.nunito(15, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                SoftStepper(label: "×\(quantity)", minWidth: 66, tint: Theme.roseStrong) {
                    quantity = max(0, quantity - 1)
                } onIncrement: {
                    quantity = min(999, quantity + 1)
                }
            }
            .padding(.vertical, 12)
            CardDivider()

            HStack {
                Text("Remind me to reorder")
                    .font(.nunito(15, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                SoftToggle(isOn: $remindReorder)
            }
            .padding(.vertical, 12)
            CardDivider()

            HStack(spacing: 10) {
                TextField("Reorder link (paste a URL)", text: $link)
                    .font(.nunito(14, .bold))
                    .foregroundStyle(Theme.ink)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button { if let url { openURL(url) } } label: {
                    Image("icon-external")
                        .renderingMode(.original)
                        .resizable().scaledToFit()
                        .frame(width: 15, height: 15)
                        .frame(width: 36, height: 36)
                        .background(url == nil ? Color(hex: 0xE3CFC0) : Theme.rose, in: Circle())
                        .opacity(url == nil ? 0.75 : 1)
                }
                .buttonStyle(.plain)
                .disabled(url == nil)
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    private var photoCard: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                if let photo, let image = UIImage(data: photo) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.peachBorder,
                                      style: StrokeStyle(lineWidth: 2, dash: [6]))
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .regular))
                        Text("Add a photo of this item")
                            .font(.nunito(12.5, .bold))
                    }
                    .foregroundStyle(Color(hex: 0xB08A5E))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    private var removeButton: some View {
        Button(action: remove) {
            HStack(spacing: 8) {
                Image("icon-trash")
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 14, height: 14)
                Text("Remove from inventory")
                    .font(.nunito(14, .heavy))
                    .foregroundStyle(Theme.tileGlyph)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Theme.softShadow, radius: 9, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard canSave else {
            onToast("Name the item first")
            return
        }
        let target = item ?? InventoryItem(context: context)
        if item == nil {
            target.id = UUID()
            target.createdAt = Date()
            target.category = "Other"
            target.threshold = 3
        }
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.quantity = Int32(quantity)
        target.remindReorder = remindReorder
        target.link = link.trimmingCharacters(in: .whitespacesAndNewlines)
        target.photo = photo
        try? context.save()

        dismiss()
        onToast("\(target.name ?? "Item") \(isEditing ? "updated" : "added")")
    }

    private func remove() {
        guard let item else { return }
        let label = item.name ?? "Item"
        context.delete(item)
        try? context.save()
        dismiss()
        onToast("\(label) removed")
    }
}

#Preview {
    InventoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

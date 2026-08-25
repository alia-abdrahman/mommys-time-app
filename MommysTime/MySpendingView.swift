import SwiftUI
import CoreData

enum SpendingCategory {
    static let all = ["Diapers", "Clothes", "Formula", "Food", "Medicine", "Other"]
}

/// Formats an amount as "RM 60.00".
func spendingCurrency(_ value: Double) -> String {
    "RM " + value.formatted(.number.precision(.fractionLength(2)))
}

struct MySpendingView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)],
        animation: .default
    )
    private var expenses: FetchedResults<Expense>

    @State private var showingAdd = false
    @State private var range = "This month"
    @State private var toast: String?

    private let ranges = ["This week", "This month", "All time"]

    private var filtered: [Expense] {
        let cal = Calendar.current
        let now = Date()
        return expenses.filter { e in
            guard let d = e.date else { return false }
            switch range {
            case "This week": return cal.isDate(d, equalTo: now, toGranularity: .weekOfYear)
            case "This month": return cal.isDate(d, equalTo: now, toGranularity: .month)
            default: return true
            }
        }
    }

    private var total: Double { filtered.reduce(0) { $0 + $1.amount } }

    private var byCategory: [(category: String, total: Double)] {
        Dictionary(grouping: filtered) { $0.category ?? "Other" }
            .mapValues { $0.reduce(0.0) { $0 + $1.amount } }
            .map { (category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    private var eyebrow: String {
        switch range {
        case "This week": return "Spent this week"
        case "All time": return "Spent all time"
        default: return "Spent this month"
        }
    }

    private var compareLine: String {
        guard let top = byCategory.first else { return "No purchases in this range yet." }
        return "Biggest slice: \(top.category) at \(spendingCurrency(top.total))"
    }

    /// Total already spent per category in the current range — feeds the Add
    /// Purchase sheet's live footer note.
    private var priorSpendByCategory: [String: Double] {
        Dictionary(grouping: filtered) { $0.category ?? "Other" }
            .mapValues { $0.reduce(0.0) { $0 + $1.amount } }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    totalCard

                    HStack {
                        Text("By category")
                            .font(.baloo(15, heavy: true))
                            .foregroundStyle(SP.textPrimary)
                        Spacer()
                        Text("\(filtered.count) purchase\(filtered.count == 1 ? "" : "s")")
                            .font(.nunito(12, .bold))
                            .foregroundStyle(SP.textMuted)
                    }
                    .padding(.top, 16).padding(.bottom, 10)

                    if byCategory.isEmpty {
                        rangeEmptyState
                    } else {
                        categoryBars
                    }

                    Text("RECENT")
                        .font(.nunito(12, .heavy)).tracking(0.8)
                        .foregroundStyle(SP.textMuted)
                        .padding(.top, 18).padding(.bottom, 8)
                    recentList
                }
                .padding(.top, 14)
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SP.screenBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) {
            ExpenseSheet(priorSpend: priorSpendByCategory) { showToast($0) }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 190)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("My Spending")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(SP.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SP.backIcon)
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

    // MARK: Total card

    private var totalCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow).font(.nunito(12, .bold)).foregroundStyle(SP.roseTag)
                    Text(spendingCurrency(total))
                        .font(.baloo(32, heavy: true))
                        .foregroundStyle(SP.roseValue)
                }
                Spacer(minLength: 0)
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(SP.roseCTA, in: Circle())
                        .shadow(color: Color(hex: 0xBE5F78).opacity(0.4), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                ForEach(ranges, id: \.self) { r in
                    let sel = r == range
                    Button { withAnimation(.easeInOut(duration: 0.2)) { range = r } } label: {
                        Text(r)
                            .font(.nunito(12.5, .heavy))
                            .foregroundStyle(sel ? .white : SP.roseTag)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background { if sel { Capsule().fill(SP.roseCTA) } }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(.white, in: Capsule())
            .padding(.top, 14)

            Text(compareLine)
                .font(.nunito(12, .bold))
                .foregroundStyle(SP.roseTag)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
        }
        .padding(.vertical, 16).padding(.horizontal, 18)
        .background(SP.roseFill, in: RoundedRectangle(cornerRadius: 26))
    }

    // MARK: Category bars

    private var categoryBars: some View {
        let maxAmount = byCategory.map(\.total).max() ?? 1
        return VStack(spacing: 11) {
            ForEach(byCategory, id: \.category) { item in
                VStack(spacing: 4) {
                    HStack {
                        Text(item.category).font(.nunito(12, .bold)).foregroundStyle(SP.textSecondary)
                        Spacer()
                        Text(spendingCurrency(item.total)).font(.nunito(12, .bold)).foregroundStyle(SP.roseValue)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(SP.trackBg)
                            Capsule().fill(SP.categoryColor(item.category))
                                .frame(width: geo.size.width * CGFloat(item.total / maxAmount))
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
    }

    private var rangeEmptyState: some View {
        VStack(spacing: 5) {
            Text("Nothing logged yet")
                .font(.baloo(16, heavy: true))
                .foregroundStyle(SP.textPrimary)
            Text("Add a purchase with the + button to start tracking where the money goes.")
                .font(.nunito(13, .semibold)).lineSpacing(4)
                .foregroundStyle(SP.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(SP.roseRow, in: RoundedRectangle(cornerRadius: 22))
        .padding(.top, 8)
    }

    // MARK: Recent list

    private var recentList: some View {
        VStack(spacing: 9) {
            ForEach(filtered, id: \.objectID) { expense in
                ExpenseRow(expense: expense) { delete(expense) }
            }
        }
    }

    private func delete(_ expense: Expense) {
        let name = expense.title ?? "Purchase"
        withAnimation { context.delete(expense) }
        try? context.save()
        showToast("\(name) removed")
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }
}

private struct ExpenseRow: View {
    @ObservedObject var expense: Expense
    var onDelete: () -> Void

    private var meta: String {
        let cat = expense.category ?? "Other"
        let date = (expense.date ?? Date()).formatted(.dateTime.day().month())
        return "\(cat) · \(date)"
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(expense.title ?? "")
                    .font(.nunito(14.5, .heavy))
                    .foregroundStyle(SP.textPrimary)
                Text(meta)
                    .font(.nunito(12, .semibold))
                    .foregroundStyle(SP.textMuted)
            }
            Spacer(minLength: 8)
            Text(spendingCurrency(expense.amount))
                .font(.nunito(14.5, .heavy))
                .foregroundStyle(SP.roseValue)
                .fixedSize()
            Button(action: onDelete) {
                Text("×")
                    .font(.nunito(13, .heavy))
                    .foregroundStyle(SP.removeIcon)
                    .frame(width: 26, height: 26)
                    .background(.white, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SP.roseRow, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Spending palette

private enum SP {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let roseRow = Color(hex: 0xF9EDEF)
    static let roseTag = Color(hex: 0xB0899A)
    static let roseValue = Color(hex: 0xC46A82)
    static let roseCTA = Color(hex: 0xD9758C)
    static let trackBg = Color(hex: 0xF3E7E2)
    static let removeIcon = Color(hex: 0xB7AA9B)
    static let backIcon = Color(hex: 0x8B7F72)

    static func categoryColor(_ name: String) -> Color {
        switch name {
        case "Formula": return Color(hex: 0xD98FA0)
        case "Diapers": return Color(hex: 0xDFA0AE)
        case "Clothes": return Color(hex: 0xE8B6BF)
        case "Food": return Color(hex: 0xF0CBD1)
        case "Medicine", "Health": return Color(hex: 0xF5DDE1)
        default: return Color(hex: 0xE8B6BF)
        }
    }
}

struct ExpenseSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let expense: Expense?
    var priorSpend: [String: Double] = [:]
    var onSaved: (String) -> Void = { _ in }

    @State private var title: String
    @State private var amount: Double
    @State private var category: String
    @State private var date: Date
    @State private var addToInventory = false
    @State private var nameToast = false

    private let chips = ["Formula", "Diapers", "Clothes", "Food", "Medicine"]

    init(expense: Expense? = nil, priorSpend: [String: Double] = [:], onSaved: @escaping (String) -> Void = { _ in }) {
        self.expense = expense
        self.priorSpend = priorSpend
        self.onSaved = onSaved
        _title = State(initialValue: expense?.title ?? "")
        _amount = State(initialValue: expense?.amount ?? 30)
        _category = State(initialValue: expense?.category ?? "Formula")
        _date = State(initialValue: expense?.date ?? Date())
    }

    private var isEditing: Bool { expense != nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                amountHero.padding(.top, 20)
                sectionLabel("CATEGORY").padding(.top, 20).padding(.bottom, 8)
                categoryChips
                sectionLabel("DETAILS").padding(.top, 20).padding(.bottom, 8)
                detailsCard
                footerNote.padding(.top, 14)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(EX.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(EX.sheetBg)
        .presentationDragIndicator(.hidden)
        .overlay(alignment: .bottom) {
            if nameToast {
                Toast(text: amount <= 0 ? "Add an amount first" : "Name the purchase first")
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit Purchase" : "Add Purchase")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(EX.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(EX.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : EX.disabledText)
                        .padding(.vertical, 8).padding(.horizontal, 18)
                        .background(canSave ? EX.accentRose : EX.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Amount hero

    private var amountHero: some View {
        VStack(spacing: 0) {
            Text("Amount").font(.nunito(12, .bold)).foregroundStyle(EX.roseTag)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("RM ").font(.baloo(17, heavy: true)).foregroundStyle(EX.roseTag)
                Text(amount.formatted(.number.precision(.fractionLength(2))))
                    .font(.baloo(42, heavy: true)).foregroundStyle(EX.roseValue)
            }
            .padding(.top, 4)
            HStack(spacing: 10) {
                Button { amount = max(0, amount - 5) } label: {
                    Text("−").font(.nunito(20, .heavy)).foregroundStyle(EX.roseTag)
                        .frame(width: 46, height: 46).background(.white, in: Circle())
                        .shadow(color: Color(hex: 0xC46A82).opacity(0.14), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                Text("RM 5 steps").font(.nunito(12, .bold)).foregroundStyle(EX.roseTag).frame(minWidth: 52)
                Button { amount = min(2000, amount + 5) } label: {
                    Text("+").font(.nunito(20, .heavy)).foregroundStyle(.white)
                        .frame(width: 46, height: 46).background(EX.roseCTA, in: Circle())
                        .shadow(color: Color(hex: 0xBE5F78).opacity(0.4), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(EX.roseFill, in: RoundedRectangle(cornerRadius: 28))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(EX.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Category chips

    private var categoryChips: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(chips, id: \.self) { chip in
                let sel = chip == category
                Button { category = chip } label: {
                    Text(chip)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(sel ? .white : EX.roseChipText)
                        .padding(.vertical, 10).padding(.horizontal, 16)
                        .background(sel ? EX.roseCTA : EX.roseFill, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Details card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            TextField("What did you buy?", text: $title)
                .font(.nunito(15, .bold)).foregroundStyle(EX.textPrimary).tint(EX.roseCTA)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)

            rowDivider

            HStack {
                Text("Bought on").font(.nunito(15, .bold)).foregroundStyle(EX.textPrimary)
                Spacer()
                HStack(spacing: 0) {
                    Button { date = date.addingTimeInterval(-86400) } label: {
                        Text("−").font(.nunito(16, .heavy)).foregroundStyle(EX.textSecondary).frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                    Text(date.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.nunito(13, .heavy)).foregroundStyle(EX.valueText).frame(minWidth: 84)
                    Button { date = date.addingTimeInterval(86400) } label: {
                        Text("+").font(.nunito(16, .heavy)).foregroundStyle(EX.roseValue).frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .background(EX.fieldFill, in: Capsule())
            }
            .padding(.vertical, 12)

            rowDivider

            HStack {
                Text("Add to inventory too").font(.nunito(15, .bold)).foregroundStyle(EX.textPrimary)
                Spacer()
                Button { addToInventory.toggle() } label: {
                    ZStack(alignment: addToInventory ? .trailing : .leading) {
                        Capsule().fill(addToInventory ? EX.toggleOn : EX.toggleOff).frame(width: 50, height: 30)
                        Circle().fill(.white).frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.15), radius: 2.5, y: 2).padding(3)
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: addToInventory)
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 18).padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color(hex: 0x7A6248).opacity(0.1)).frame(height: 1)
    }

    // MARK: Footer note

    private var footerNote: some View {
        Text(noteText)
            .font(.nunito(12.5, .bold)).lineSpacing(6)
            .foregroundStyle(EX.noteText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(EX.roseNote, in: RoundedRectangle(cornerRadius: 22))
    }

    private var noteText: String {
        let prior = priorSpend[category] ?? 0
        let cat = category.lowercased()
        if prior > 0 {
            return "You've spent \(spendingCurrency(prior)) on \(cat) so far. This takes it to \(spendingCurrency(prior + amount))."
        }
        return "First \(cat) purchase logged in this range."
    }

    // MARK: Save

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, amount > 0 else {
            withAnimation { nameToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { nameToast = false }
            }
            return
        }
        let target = expense ?? Expense(context: context)
        if expense == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.title = trimmed
        target.amount = amount
        target.category = category
        target.date = date

        if expense == nil && addToInventory {
            let item = InventoryItem(context: context)
            item.id = UUID()
            item.createdAt = Date()
            item.name = trimmed
            item.category = category
            item.quantity = 1
            item.threshold = 6
            item.remindReorder = false
        }

        try? context.save()
        if expense == nil {
            onSaved(addToInventory ? "Logged and added to inventory" : "\(spendingCurrency(amount)) logged")
        }
        dismiss()
    }
}

// MARK: - Add purchase palette

private enum EX {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let roseNote = Color(hex: 0xF9EDEF)
    static let roseTag = Color(hex: 0xB0899A)
    static let roseValue = Color(hex: 0xC46A82)
    static let roseCTA = Color(hex: 0xD9758C)
    static let roseChipText = Color(hex: 0xB0778C)
    static let noteText = Color(hex: 0xA85F73)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let accentRose = Color(hex: 0xD98FA0)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = Color(hex: 0x7FBFAE)
}

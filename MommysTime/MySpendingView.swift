import SwiftUI
import CoreData
import Charts

enum SpendingCategory {
    static let all = ["Diapers", "Clothes", "Formula", "Food", "Health", "Toys", "Other"]
}

func spendingCurrency(_ value: Double) -> String {
    value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
}

struct MySpendingView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)],
        animation: .default
    )
    private var expenses: FetchedResults<Expense>

    @State private var showingAdd = false
    @State private var editing: Expense?

    private var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var byCategory: [(category: String, total: Double)] {
        Dictionary(grouping: expenses) { $0.category ?? "Other" }
            .mapValues { $0.reduce(0.0) { $0 + $1.amount } }
            .map { (category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        Group {
            if expenses.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        totalCard
                        chartCard
                        expenseList
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Spending")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            ExpenseSheet()
        }
        .sheet(item: $editing) { expense in
            ExpenseSheet(expense: expense)
        }
    }

    private var totalCard: some View {
        VStack(spacing: 4) {
            Text("Total spending")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(spendingCurrency(total))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.pink)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.pink.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By category")
                .font(.headline)
            Chart(byCategory, id: \.category) { item in
                BarMark(
                    x: .value("Amount", item.total),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(.pink)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(spendingCurrency(item.total))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(byCategory.count) * 44 + 10)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var expenseList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)
                .foregroundStyle(.secondary)
            ForEach(expenses, id: \.objectID) { expense in
                ExpenseCard(expense: expense)
                    .contentShape(Rectangle())
                    .onTapGesture { editing = expense }
                    .contextMenu {
                        Button("Edit") { editing = expense }
                        Button("Delete", role: .destructive) { delete(expense) }
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("💸")
                .font(.system(size: 56))
            Text("No spending logged yet")
                .font(.title3.bold())
            Text("Add what you spend on the little one and see where the money goes, by category.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add an expense") { showingAdd = true }
                .buttonStyle(.bordered)
        }
        .padding(32)
    }

    private func delete(_ expense: Expense) {
        context.delete(expense)
        try? context.save()
    }
}

private struct ExpenseCard: View {
    @ObservedObject var expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title ?? "")
                    .font(.body)
                HStack(spacing: 6) {
                    Text(expense.category ?? "Other")
                    if let date = expense.date {
                        Text("·")
                        Text(date.formatted(.dateTime.day().month()))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(spendingCurrency(expense.amount))
                .font(.headline)
                .foregroundStyle(.pink)
        }
        .padding()
        .background(Color.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ExpenseSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let expense: Expense?

    @State private var title: String
    @State private var amount: Double
    @State private var category: String
    @State private var date: Date
    @State private var showingDeleteConfirmation = false

    init(expense: Expense? = nil) {
        self.expense = expense
        _title = State(initialValue: expense?.title ?? "")
        _amount = State(initialValue: expense?.amount ?? 0)
        _category = State(initialValue: expense?.category ?? "Diapers")
        _date = State(initialValue: expense?.date ?? Date())
    }

    private var isEditing: Bool { expense != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    TextField("What was it? (e.g. Diapers)", text: $title)
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(SpendingCategory.all, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                if isEditing {
                    Section {
                        Button("Delete expense", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "Delete this expense?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteExpense() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let target = expense ?? Expense(context: context)
        if expense == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.amount = amount
        target.category = category
        target.date = date
        try? context.save()
        dismiss()
    }

    private func deleteExpense() {
        if let expense {
            context.delete(expense)
            try? context.save()
        }
        dismiss()
    }
}

import SwiftUI
import CoreData

struct SyncToCloudView: View {
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                explanation
                ShareLink(item: backupText()) {
                    Label("Export a backup", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sync to Cloud")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "icloud.and.arrow.up.fill")
                .font(.system(size: 52))
                .foregroundStyle(.pink)
            Label("Premium feature", systemImage: "lock.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.pink)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keep your data safe")
                .font(.headline)
            Text("Automatic cloud sync across your devices is coming soon. In the meantime, you can export a copy of everything and save it to Files or iCloud Drive, or send it to yourself.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    /// Builds a readable text backup of the user's data for the share sheet.
    private func backupText() -> String {
        var lines = ["MommysTime backup", ""]

        func fetch<T: NSManagedObject>(_ type: T.Type, _ name: String, sortKey: String) -> [T] {
            let request = NSFetchRequest<T>(entityName: name)
            request.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: true)]
            return (try? context.fetch(request)) ?? []
        }

        let appts = fetch(Appointment.self, "Appointment", sortKey: "date")
        if !appts.isEmpty {
            lines.append("Appointments:")
            for a in appts {
                let when = a.date?.formatted(.dateTime.day().month().year().hour().minute()) ?? ""
                lines.append("• \(a.title ?? "") — \(when)")
            }
            lines.append("")
        }

        let items = fetch(InventoryItem.self, "InventoryItem", sortKey: "name")
        if !items.isEmpty {
            lines.append("Inventory:")
            for i in items { lines.append("• \(i.name ?? "") ×\(i.quantity) (\(i.category ?? ""))") }
            lines.append("")
        }

        let growth = fetch(GrowthEntry.self, "GrowthEntry", sortKey: "date")
        if !growth.isEmpty {
            lines.append("Growth:")
            for g in growth {
                let when = g.date?.formatted(.dateTime.day().month().year()) ?? ""
                lines.append("• \(when): \(g.weightKg) kg, \(g.heightCm) cm")
            }
            lines.append("")
        }

        let expenses = fetch(Expense.self, "Expense", sortKey: "date")
        if !expenses.isEmpty {
            let total = expenses.reduce(0.0) { $0 + $1.amount }
            lines.append("Spending: \(spendingCurrency(total)) total across \(expenses.count) expenses")
            lines.append("")
        }

        lines.append("Exported from MommysTime 🌸")
        return lines.joined(separator: "\n")
    }
}

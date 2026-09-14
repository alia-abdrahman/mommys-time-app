import SwiftUI
import CoreData

struct SyncToCloudView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var exported = false
    @State private var showingShare = false
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 0) {
                Image("sync-to-cloud")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(SC.roseAccent)
                    .frame(width: 92, height: 92)
                    .background(SC.roseFill, in: Circle())
                    .padding(.bottom, 12)

                Text("Premium feature")
                    .font(.nunito(12, .heavy))
                    .foregroundStyle(SC.roseAccent)
                    .padding(.vertical, 6).padding(.horizontal, 14)
                    .background(SC.roseFill, in: Capsule())

                explainerCard.padding(.top, 18)

                exportButton.padding(.top, 16)
            }
            .padding(.top, 26)
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SC.screenBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingShare) {
            ShareSheet(text: backupText())
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Sync to Cloud")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(SC.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SC.backIcon)
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

    private var explainerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Keep your data safe")
                .font(.baloo(16, heavy: true))
                .foregroundStyle(SC.textPrimary)
            Text("Automatic cloud sync across your devices is coming soon. In the meantime, export a copy of everything and save it to Files or send it to yourself.")
                .font(.nunito(13, .semibold))
                .lineSpacing(5)
                .foregroundStyle(SC.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private var exportButton: some View {
        Button {
            showingShare = true
            exported = true
            showToast("Backup exported to Files")
        } label: {
            HStack(spacing: 9) {
                Image(systemName: exported ? "checkmark" : "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                Text(exported ? "Backup saved" : "Export a backup")
                    .font(.baloo(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(SC.roseCTA, in: Capsule())
            .shadow(color: SC.roseCTA.opacity(0.4), radius: 20, y: 9)
        }
        .buttonStyle(.plain)
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
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

// MARK: - Share sheet & palette

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private enum SC {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let roseAccent = Color(hex: 0xC97B8C)
    static let roseCTA = Color(hex: 0xD98FA0)
    static let backIcon = Color(hex: 0x8B7F72)
}

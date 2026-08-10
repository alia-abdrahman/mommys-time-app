import SwiftUI
import CoreData

enum PumpSide {
    static let all = ["Left", "Right", "Both"]
}

struct PumpTrackerView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PumpSession.date, ascending: false)],
        animation: .default
    )
    private var sessions: FetchedResults<PumpSession>

    @AppStorage(SettingsKeys.pumpIntervalHours) private var intervalHours = 3

    @State private var showingLog = false
    @State private var editing: PumpSession?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                nextCard
                todayCard
                historySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pump Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingLog = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingLog) {
            PumpSessionSheet()
        }
        .sheet(item: $editing) { session in
            PumpSessionSheet(session: session)
        }
    }

    // MARK: Next session

    private var nextCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "drop.fill")
                .font(.largeTitle)
                .foregroundStyle(.cyan)
            Text(nextText)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Text("Pump every")
                    .foregroundStyle(.secondary)
                Menu {
                    ForEach(1...6, id: \.self) { hours in
                        Button("\(hours) hour\(hours == 1 ? "" : "s")") { intervalHours = hours }
                    }
                } label: {
                    Text("\(intervalHours)h")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.2), in: Capsule())
                }
            }
            .font(.subheadline)

            Button {
                showingLog = true
            } label: {
                Label("Log a session", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
    }

    private var nextText: String {
        guard let next = nextSessionDate else {
            return "Log your first session to start tracking 🍼"
        }
        if next > Date() {
            return "Next session \(timeUntil(next))"
        }
        return "Session due now 🍼"
    }

    private var nextSessionDate: Date? {
        guard let last = sessions.first?.date else { return nil }
        return last.addingTimeInterval(Double(intervalHours) * 3600)
    }

    // MARK: Today summary

    private var todayCard: some View {
        HStack {
            summaryStat(value: "\(todaySessions.count)", label: todaySessions.count == 1 ? "session today" : "sessions today")
            Divider().frame(height: 36)
            summaryStat(value: "\(todayML)", label: "ml today")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.cyan)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var todaySessions: [PumpSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date ?? .distantPast) }
    }

    private var todayML: Int {
        todaySessions.reduce(0) { $0 + Int($1.amountML) }
    }

    // MARK: History

    @ViewBuilder
    private var historySection: some View {
        if sessions.isEmpty {
            VStack(spacing: 10) {
                Text("No sessions logged yet")
                    .font(.headline)
                Text("Tap “Log a session” after you pump to keep a record and get your next-session reminder.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("History")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                ForEach(sessions, id: \.objectID) { session in
                    PumpSessionCard(session: session)
                        .contentShape(Rectangle())
                        .onTapGesture { editing = session }
                        .contextMenu {
                            Button("Edit") { editing = session }
                            Button("Delete", role: .destructive) { delete(session) }
                        }
                }
            }
        }
    }

    private func delete(_ session: PumpSession) {
        context.delete(session)
        try? context.save()
    }

    private func timeUntil(_ date: Date) -> String {
        let minutes = max(0, Int(date.timeIntervalSinceNow / 60))
        if minutes < 1 { return "now" }
        if minutes < 60 { return "in \(minutes) min" }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "in \(hours)h" : "in \(hours)h \(remainder)m"
    }
}

private struct PumpSessionCard: View {
    @ObservedObject var session: PumpSession

    private var detail: String {
        var parts = ["\(session.durationMinutes) min"]
        if session.amountML > 0 { parts.append("\(session.amountML) ml") }
        if let side = session.side, !side.isEmpty { parts.append(side) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.cyan)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                if let date = session.date {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                        .font(.body)
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct PumpSessionSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: PumpSession?

    @State private var date: Date
    @State private var duration: Int
    @State private var amount: Int
    @State private var side: String
    @State private var notes: String
    @State private var showingDeleteConfirmation = false

    init(session: PumpSession? = nil) {
        self.session = session
        _date = State(initialValue: session?.date ?? Date())
        _duration = State(initialValue: Int(session?.durationMinutes ?? 15))
        _amount = State(initialValue: Int(session?.amountML ?? 0))
        _side = State(initialValue: session?.side ?? "Both")
        _notes = State(initialValue: session?.notes ?? "")
    }

    private var isEditing: Bool { session != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Time", selection: $date)
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("0", value: $duration, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("min").foregroundStyle(.secondary)
                        Stepper("", value: $duration, in: 0...180).labelsHidden()
                    }
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("ml").foregroundStyle(.secondary)
                    }
                    Picker("Side", selection: $side) {
                        ForEach(PumpSide.all, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Notes") {
                    TextField("Anything to note…", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                if isEditing {
                    Section {
                        Button("Delete session", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Session" : "Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .confirmationDialog(
                "Delete this session?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteSession() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let target = session ?? PumpSession(context: context)
        if session == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.date = date
        target.durationMinutes = Int32(duration)
        target.amountML = Int32(amount)
        target.side = side
        target.notes = notes
        try? context.save()
        dismiss()
    }

    private func deleteSession() {
        if let session {
            context.delete(session)
            try? context.save()
        }
        dismiss()
    }
}

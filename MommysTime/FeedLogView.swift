import SwiftUI
import CoreData

enum FeedType {
    static let all = ["Breast", "Bottle", "Solid"]
}

struct FeedLogView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedSession.date, ascending: false)],
        animation: .default
    )
    private var feeds: FetchedResults<FeedSession>

    @State private var showingAdd = false
    @State private var editing: FeedSession?

    private var todayFeeds: [FeedSession] {
        feeds.filter { Calendar.current.isDateInToday($0.date ?? .distantPast) }
    }

    private var todayML: Int {
        todayFeeds.reduce(0) { $0 + Int($1.amountML) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                if feeds.isEmpty {
                    emptyState
                } else {
                    history
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Feed Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { FeedSheet() }
        .sheet(item: $editing) { feed in FeedSheet(feed: feed) }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.largeTitle)
                .foregroundStyle(.mint)
            if let last = feeds.first?.date {
                Text("Last feed \(relative(last))")
                    .font(.title3.bold())
            } else {
                Text("No feeds logged yet 🍼")
                    .font(.title3.bold())
            }
            HStack {
                stat(value: "\(todayFeeds.count)", label: todayFeeds.count == 1 ? "feed today" : "feeds today")
                Divider().frame(height: 32)
                stat(value: "\(todayML)", label: "ml today")
            }
            Button { showingAdd = true } label: {
                Label("Log a feed", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold()).foregroundStyle(.mint)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History").font(.headline).foregroundStyle(.secondary)
            ForEach(feeds, id: \.objectID) { feed in
                FeedCard(feed: feed)
                    .contentShape(Rectangle())
                    .onTapGesture { editing = feed }
                    .contextMenu {
                        Button("Edit") { editing = feed }
                        Button("Delete", role: .destructive) { delete(feed) }
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Track every feed")
                .font(.headline)
            Text("Log breast, bottle and solid feeds to spot your baby's rhythm.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private func delete(_ feed: FeedSession) {
        context.delete(feed)
        try? context.save()
    }

    private func relative(_ date: Date) -> String {
        let minutes = max(0, Int(Date().timeIntervalSince(date) / 60))
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        let rem = minutes % 60
        return rem == 0 ? "\(hours)h ago" : "\(hours)h \(rem)m ago"
    }
}

private struct FeedCard: View {
    @ObservedObject var feed: FeedSession

    private var detail: String {
        var parts: [String] = []
        if feed.durationMinutes > 0 { parts.append("\(feed.durationMinutes) min") }
        if feed.amountML > 0 { parts.append("\(feed.amountML) ml") }
        if let side = feed.side, !side.isEmpty { parts.append(side) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundStyle(.mint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(feed.type ?? "Feed").font(.body)
                    if let date = feed.date {
                        Text("·").foregroundStyle(.secondary)
                        Text(date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if !detail.isEmpty {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.mint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct FeedSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let feed: FeedSession?

    @State private var type: String
    @State private var date: Date
    @State private var amount: Int
    @State private var duration: Int
    @State private var side: String
    @State private var notes: String
    @State private var showingDeleteConfirmation = false

    init(feed: FeedSession? = nil) {
        self.feed = feed
        _type = State(initialValue: feed?.type ?? "Breast")
        _date = State(initialValue: feed?.date ?? Date())
        _amount = State(initialValue: Int(feed?.amountML ?? 0))
        _duration = State(initialValue: Int(feed?.durationMinutes ?? 0))
        _side = State(initialValue: feed?.side ?? "Both")
        _notes = State(initialValue: feed?.notes ?? "")
    }

    private var isEditing: Bool { feed != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed") {
                    Picker("Type", selection: $type) {
                        ForEach(FeedType.all, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Time", selection: $date)
                    if type == "Breast" {
                        Picker("Side", selection: $side) {
                            ForEach(["Left", "Right", "Both"], id: \.self) { Text($0).tag($0) }
                        }
                        HStack {
                            Text("Duration")
                            Spacer()
                            TextField("0", value: $duration, format: .number)
                                .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 50)
                            Text("min").foregroundStyle(.secondary)
                            Stepper("", value: $duration, in: 0...120).labelsHidden()
                        }
                    } else {
                        HStack {
                            Text("Amount")
                            Spacer()
                            TextField("0", value: $amount, format: .number)
                                .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 60)
                            Text("ml").foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Anything to note…", text: $notes, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                }
                if isEditing {
                    Section {
                        Button("Delete feed", role: .destructive) { showingDeleteConfirmation = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Feed" : "Log Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .confirmationDialog("Delete this feed?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteFeed() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let target = feed ?? FeedSession(context: context)
        if feed == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.type = type
        target.date = date
        target.amountML = type == "Breast" ? 0 : Int32(amount)
        target.durationMinutes = type == "Breast" ? Int32(duration) : 0
        target.side = type == "Breast" ? side : nil
        target.notes = notes
        try? context.save()
        dismiss()
    }

    private func deleteFeed() {
        if let feed {
            context.delete(feed)
            try? context.save()
        }
        dismiss()
    }
}

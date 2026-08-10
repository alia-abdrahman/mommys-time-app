import SwiftUI
import CoreData

struct GoalsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Goal.createdAt, ascending: true)],
        animation: .default
    )
    private var goals: FetchedResults<Goal>

    @State private var showingAddGoal = false
    @State private var editingGoal: Goal?

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(goals, id: \.objectID) { goal in
                            GoalRow(goal: goal) { editingGoal = goal }
                        }
                        .onDelete(perform: deleteGoals)
                    }
                }
            }
            .navigationTitle("My Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalSheet()
            }
            .sheet(item: $editingGoal) { goal in
                EditGoalSheet(goal: goal)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("💛")
                .font(.system(size: 56))
            Text("What are you working on, mama?")
                .font(.title3.bold())
            Text("Learning to stitch? A new language? Coding? Add a goal and the app will help you find time for it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add your first goal") {
                showingAddGoal = true
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
    }

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            context.delete(goals[index])
        }
        try? context.save()
    }
}

struct GoalRow: View {
    @ObservedObject var goal: Goal
    var onTap: (() -> Void)?

    /// Fetching completed sessions directly (rather than reading goal.sessions)
    /// makes the row update live when a session is ticked, because @FetchRequest
    /// observes Core Data saves — toggling a session doesn't change the Goal.
    @FetchRequest private var completedSessions: FetchedResults<MeTimeSession>

    init(goal: Goal, onTap: (() -> Void)? = nil) {
        self.goal = goal
        self.onTap = onTap
        let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        let start = (week?.start ?? .distantPast) as NSDate
        let end = (week?.end ?? .distantFuture) as NSDate
        _completedSessions = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(
                format: "goal == %@ AND completed == YES AND date >= %@ AND date < %@",
                goal, start, end
            ),
            animation: .default
        )
    }

    private var completed: Int { completedSessions.count }
    private var target: Int { max(Int(goal.targetSessionsPerWeek), 1) }
    private var isMet: Bool { completed >= target }
    private var bonus: Int { max(0, completed - target) }

    private var progressText: String {
        if !isMet {
            return "\(completed) of \(target) \(sessionsWord(target)) this week"
        } else if bonus == 0 {
            return "Goal reached — \(target) of \(target) 🎉"
        } else {
            return "Goal reached — \(target) of \(target), +\(bonus) bonus 🎉"
        }
    }

    private func sessionsWord(_ count: Int) -> String {
        count == 1 ? "session" : "sessions"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(goal.icon ?? "🌸")
                .font(.title)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(goal.name ?? "")
                        .font(.body)
                    if isMet {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                }
                ProgressView(
                    value: Double(min(completed, target)),
                    total: Double(target)
                )
                .tint(.pink)
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

struct AddGoalSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "🌸"
    @State private var targetPerWeek = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Your goal") {
                    TextField("e.g. Learn to stitch", text: $name)
                    Stepper("Target: \(targetPerWeek)x a week", value: $targetPerWeek, in: 1...14)
                }
                Section("Pick an icon") {
                    GoalIconPicker(selection: $icon)
                }
            }
            .navigationTitle("New Goal")
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
        }
    }

    private func save() {
        let goal = Goal(context: context)
        goal.id = UUID()
        goal.name = name.trimmingCharacters(in: .whitespaces)
        goal.icon = icon
        goal.targetSessionsPerWeek = Int16(targetPerWeek)
        goal.createdAt = Date()
        try? context.save()
        dismiss()
    }
}

struct EditGoalSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var goal: Goal

    @State private var name: String
    @State private var icon: String
    @State private var targetPerWeek: Int
    @State private var showingDeleteConfirmation = false

    @FetchRequest private var completedSessions: FetchedResults<MeTimeSession>

    init(goal: Goal) {
        self.goal = goal
        _name = State(initialValue: goal.name ?? "")
        _icon = State(initialValue: goal.icon ?? "🌸")
        _targetPerWeek = State(initialValue: max(Int(goal.targetSessionsPerWeek), 1))
        let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        let start = (week?.start ?? .distantPast) as NSDate
        let end = (week?.end ?? .distantFuture) as NSDate
        _completedSessions = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(
                format: "goal == %@ AND completed == YES AND date >= %@ AND date < %@",
                goal, start, end
            ),
            animation: .default
        )
    }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func count(on day: Date) -> Int {
        let calendar = Calendar.current
        return completedSessions.filter { session in
            guard let date = session.date else { return false }
            return calendar.isDate(date, inSameDayAs: day)
        }.count
    }

    private var totalThisWeek: Int { completedSessions.count }

    var body: some View {
        NavigationStack {
            Form {
                Section("This week") {
                    WeekBreakdownStrip(days: weekDates.map { ($0, count(on: $0)) })
                    Text(totalThisWeek == 0
                         ? "No sessions completed yet this week."
                         : "\(totalThisWeek) \(totalThisWeek == 1 ? "session" : "sessions") completed this week — they add up here from every day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Your goal") {
                    TextField("e.g. Learn to stitch", text: $name)
                    Stepper("Target: \(targetPerWeek)x a week", value: $targetPerWeek, in: 1...14)
                }
                Section("Pick an icon") {
                    GoalIconPicker(selection: $icon)
                }
                Section {
                    Button("Delete goal", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit goal")
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
                "Delete this goal?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteGoal() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your booked me-time stays on your schedule, but it won't count towards a goal any more.")
            }
        }
    }

    private func save() {
        goal.name = name.trimmingCharacters(in: .whitespaces)
        goal.icon = icon
        goal.targetSessionsPerWeek = Int16(targetPerWeek)
        try? context.save()
        dismiss()
    }

    private func deleteGoal() {
        context.delete(goal)
        try? context.save()
        dismiss()
    }
}

private struct WeekBreakdownStrip: View {
    let days: [(date: Date, count: Int)]

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.date) { day in
                VStack(spacing: 6) {
                    Text(day.date.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ZStack {
                        Circle()
                            .fill(day.count > 0 ? Color.pink : Color(.systemGray5))
                            .frame(width: 34, height: 34)
                        if calendar.isDateInToday(day.date) {
                            Circle()
                                .strokeBorder(Color.pink, lineWidth: 2)
                                .frame(width: 34, height: 34)
                        }
                        if day.count > 0 {
                            Text("\(day.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct GoalIconPicker: View {
    @Binding var selection: String

    private let icons = ["🧵", "💻", "📚", "🎨", "🍰", "🏃‍♀️", "🌱", "✍️", "🎹", "🌸"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(icons, id: \.self) { emoji in
                    Button {
                        selection = emoji
                    } label: {
                        Text(emoji)
                            .font(.title)
                            .padding(6)
                            .background(selection == emoji ? Color.pink.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

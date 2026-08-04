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

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(goals, id: \.objectID) { goal in
                            GoalRow(goal: goal)
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

    private var completedThisWeek: Int {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        let sessions = (goal.sessions as? Set<MeTimeSession>) ?? []
        return sessions.filter { session in
            guard let date = session.date else { return false }
            return session.completed && week.contains(date)
        }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(goal.icon ?? "🌸")
                .font(.title)
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name ?? "")
                    .font(.body)
                ProgressView(value: Double(min(completedThisWeek, Int(goal.targetSessionsPerWeek))), total: Double(max(Int(goal.targetSessionsPerWeek), 1)))
                    .tint(.pink)
                Text("\(completedThisWeek) of \(goal.targetSessionsPerWeek) sessions this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddGoalSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "🌸"
    @State private var targetPerWeek = 3

    private let icons = ["🧵", "💻", "📚", "🎨", "🍰", "🏃‍♀️", "🌱", "✍️", "🎹", "🌸"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Your goal") {
                    TextField("e.g. Learn to stitch", text: $name)
                    Stepper("Target: \(targetPerWeek)x a week", value: $targetPerWeek, in: 1...14)
                }
                Section("Pick an icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(icons, id: \.self) { emoji in
                                Button {
                                    icon = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title)
                                        .padding(6)
                                        .background(icon == emoji ? Color.pink.opacity(0.2) : Color.clear)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
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

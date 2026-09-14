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
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            if goals.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(goals, id: \.objectID) { goal in
                            GoalRow(goal: goal, onTap: { editingGoal = goal }, onDelete: { delete(goal) })
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 120)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GO.screenBg.ignoresSafeArea())
        .sheet(isPresented: $showingAddGoal) { AddGoalSheet { showToast($0) } }
        .sheet(item: $editingGoal) { goal in EditGoalSheet(goal: goal) }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }

    private var header: some View {
        HStack {
            Text("My Goals")
                .font(.baloo(30, heavy: true))
                .foregroundStyle(GO.textPrimary)
            Spacer()
            Button { showingAddGoal = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(GO.roseCTA, in: Circle())
                    .shadow(color: GO.roseCTA.opacity(0.4), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(GO.roseCTA)
                    .frame(width: 96, height: 96)
                    .background(GO.roseFill, in: Circle())
                    .padding(.bottom, 16)

                Text("What are you working on, mama?")
                    .font(.baloo(21, heavy: true))
                    .foregroundStyle(GO.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Learning to stitch? A new language? Coding? Add a goal and the app will help you find time for it.")
                    .font(.nunito(14))
                    .lineSpacing(5)
                    .foregroundStyle(GO.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Button { showingAddGoal = true } label: {
                    Text("Add your first goal")
                        .font(.nunito(13.5, .heavy))
                        .foregroundStyle(GO.roseAccent)
                        .padding(.vertical, 12).padding(.horizontal, 22)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.11), radius: 14, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.top, 18)
            }
            .padding(.top, 70)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    private func delete(_ goal: Goal) {
        withAnimation { context.delete(goal) }
        try? context.save()
    }
}

struct GoalRow: View {
    @ObservedObject var goal: Goal
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    /// Fetching completed sessions directly (rather than reading goal.sessions)
    /// makes the row update live when a session is ticked, because @FetchRequest
    /// observes Core Data saves — toggling a session doesn't change the Goal.
    @FetchRequest private var completedSessions: FetchedResults<MeTimeSession>

    init(goal: Goal, onTap: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.goal = goal
        self.onTap = onTap
        self.onDelete = onDelete
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

    /// Goals created via New Goal store a swatch colour hex ("#RRGGBB");
    /// onboarding goals store an emoji. Render whichever applies.
    private var swatchColor: Color? {
        guard let icon = goal.icon, icon.hasPrefix("#"),
              let hex = UInt(icon.dropFirst(), radix: 16) else { return nil }
        return Color(hex: hex)
    }

    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 16)
                .fill(swatchColor ?? GO.roseFill)
                .frame(width: 44, height: 44)
                .overlay {
                    if swatchColor == nil { Text(goal.icon ?? "🌸").font(.system(size: 20)) }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name ?? "")
                    .font(.nunito(15.5, .heavy))
                    .foregroundStyle(GO.textPrimary)
                Text("\(target)× a week · \(completed) done")
                    .font(.nunito(12, .bold))
                    .foregroundStyle(GO.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }

            Button { onDelete?() } label: {
                Text("×")
                    .font(.nunito(13, .heavy))
                    .foregroundStyle(GO.removeIcon)
                    .frame(width: 26, height: 26)
                    .background(GO.removeBg, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }
}

// MARK: - Goals palette

private enum GO {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let roseCTA = Color(hex: 0xD98FA0)
    static let roseAccent = Color(hex: 0xC97B8C)
    static let removeBg = Color(hex: 0xF4EDE4)
    static let removeIcon = Color(hex: 0xB7AA9B)
}

struct AddGoalSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    var onSaved: (String) -> Void = { _ in }

    @State private var name = ""
    @State private var targetPerWeek = 3
    @State private var iconIndex = 0
    @State private var nameToast = false

    /// Flat swatch placeholders — stored as the goal's icon hex on save.
    private let swatches: [UInt] = [
        0xF6E6E9, 0xE2EDF3, 0xDFEDE5, 0xF3E7CF,
        0xE7E5F4, 0xFBEBD8, 0xF0E7DC, 0xE6F2ED,
    ]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                sectionLabel("YOUR GOAL").padding(.top, 20).padding(.bottom, 8)
                goalCard
                sectionLabel("PICK AN ICON").padding(.top, 20).padding(.bottom, 8)
                iconGrid
                footerNote.padding(.top, 12)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(NG.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(NG.sheetBg)
        .presentationDragIndicator(.hidden)
        .overlay(alignment: .bottom) {
            if nameToast {
                Toast(text: "Name your goal first")
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("New Goal")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(NG.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(NG.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : NG.disabledText)
                        .padding(.vertical, 8).padding(.horizontal, 18)
                        .background(canSave ? NG.accentRose : NG.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(NG.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Goal card

    private var goalCard: some View {
        VStack(spacing: 0) {
            TextField("e.g. Learn to stitch", text: $name)
                .font(.nunito(15, .bold)).foregroundStyle(NG.textPrimary).tint(NG.accentRose)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)

            Rectangle().fill(Color(hex: 0x7A6248).opacity(0.1)).frame(height: 1)

            HStack {
                Text("Target: \(targetPerWeek)× a week")
                    .font(.nunito(15, .bold)).foregroundStyle(NG.textPrimary)
                Spacer()
                HStack(spacing: 0) {
                    Button { targetPerWeek = max(1, targetPerWeek - 1) } label: {
                        Text("−").font(.nunito(16, .heavy)).foregroundStyle(NG.textSecondary).frame(width: 38, height: 34)
                    }
                    .buttonStyle(.plain)
                    Rectangle().fill(Color(hex: 0x7A6248).opacity(0.18)).frame(width: 1, height: 18)
                    Button { targetPerWeek = min(7, targetPerWeek + 1) } label: {
                        Text("+").font(.nunito(16, .heavy)).foregroundStyle(NG.accentPlus).frame(width: 38, height: 34)
                    }
                    .buttonStyle(.plain)
                }
                .background(NG.fieldFill, in: Capsule())
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 18).padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    // MARK: Icon grid

    private var iconGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(swatches.indices, id: \.self) { i in
                Button { iconIndex = i } label: {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: swatches[i]))
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(i == iconIndex ? NG.accentRose : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private var footerNote: some View {
        Text("Icon set to be drawn in the illustrated style — flat swatches shown as placeholders.")
            .font(.nunito(11.5, .semibold)).lineSpacing(4)
            .foregroundStyle(NG.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: Save

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            withAnimation { nameToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { nameToast = false }
            }
            return
        }
        let goal = Goal(context: context)
        goal.id = UUID()
        goal.name = trimmed
        goal.icon = String(format: "#%06X", swatches[iconIndex])
        goal.targetSessionsPerWeek = Int16(targetPerWeek)
        goal.createdAt = Date()
        try? context.save()
        onSaved("Goal added")
        dismiss()
    }
}

// MARK: - New Goal palette

private enum NG {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let accentRose = Color(hex: 0xD98FA0)
    static let accentPlus = Color(hex: 0xC97B8C)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
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
                            .fill(day.count > 0 ? Theme.rose : Color(.systemGray5))
                            .frame(width: 34, height: 34)
                        if calendar.isDateInToday(day.date) {
                            Circle()
                                .strokeBorder(Theme.rose, lineWidth: 2)
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
                            .background(selection == emoji ? Theme.rose.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

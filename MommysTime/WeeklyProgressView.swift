import SwiftUI
import CoreData

struct WeeklyProgressView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeTimeSession.date, ascending: false)],
        animation: .default
    )
    private var allSessions: FetchedResults<MeTimeSession>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Goal.createdAt, ascending: true)],
        animation: .default
    )
    private var goals: FetchedResults<Goal>

    private var thisWeeksSessions: [MeTimeSession] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return allSessions.filter { session in
            guard let date = session.date else { return false }
            return week.contains(date)
        }
    }

    private var completedMinutes: Int {
        thisWeeksSessions.filter(\.completed).reduce(0) { $0 + Int($1.durationMinutes) }
    }

    private var headline: String {
        switch completedMinutes {
        case 0:
            return "This week is still young. Your time will come, mama 🌱"
        case ..<60:
            return "You gave yourself \(completedMinutes) minutes this week. Every minute counts 💛"
        case ..<180:
            return "You gave yourself \(timeLabel) this week — lovely 💛"
        default:
            return "Amazing! \(timeLabel) of me-time this week 🌟"
        }
    }

    private var timeLabel: String {
        let hours = completedMinutes / 60
        let minutes = completedMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(timeLabel)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.pink)
                        Text(headline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Me-time this week")
                }

                if !goals.isEmpty {
                    Section("By goal") {
                        ForEach(goals, id: \.objectID) { goal in
                            GoalRow(goal: goal)
                        }
                    }
                }

                Section {
                    Text("No streaks, no guilt. Some weeks belong entirely to the kids — and that's okay. The app will keep finding pockets of time for you. 🤍")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Progress")
        }
    }
}

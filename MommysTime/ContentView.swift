import SwiftUI

enum SettingsKeys {
    static let dayStartHour = "dayStartHour"
    static let dayEndHour = "dayEndHour"
    static let bedtimeHour = "bedtimeHour"
    static let minGapMinutes = "minGapMinutes"
    static let maxSlotMinutes = "maxSlotMinutes"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let alwaysShowGuide = "alwaysShowGuide"
    static let hasSeenTodayGuide = "hasSeenTodayGuide"
}

struct ContentView: View {
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            GoalsView()
                .tabItem { Label("Goals", systemImage: "heart.fill") }
            WeeklyProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

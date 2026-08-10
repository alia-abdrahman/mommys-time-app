import SwiftUI

enum SettingsKeys {
    static let dayStartHour = "dayStartHour"
    static let dayEndHour = "dayEndHour"
    static let bedtimeHour = "bedtimeHour"
    static let minGapMinutes = "minGapMinutes"
    static let maxSlotMinutes = "maxSlotMinutes"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let showGuide = "showGuide"
    static let pumpIntervalHours = "pumpIntervalHours"
}

struct ContentView: View {
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var selectedTab = AppTab.home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)
            TodayView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(AppTab.schedule)
            GoalsView()
                .tabItem { Label("Goals", systemImage: "heart.fill") }
                .tag(AppTab.goals)
            WeeklyProgressView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(AppTab.progress)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
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

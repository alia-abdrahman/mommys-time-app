import SwiftUI
import CoreData

enum SettingsKeys {
    static let dayStartHour = "dayStartHour"
    static let dayEndHour = "dayEndHour"
    static let bedtimeHour = "bedtimeHour"
    static let minGapMinutes = "minGapMinutes"
    static let maxSlotMinutes = "maxSlotMinutes"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let pumpIntervalHours = "pumpIntervalHours"
    static let feedIntervalHours = "feedIntervalHours"
    static let isPremium = "isPremium"
    /// An `AppLanguage` raw value — "system" unless she picked one herself.
    static let appLanguage = "appLanguage"

    // Wake Window: which state the baby is in, and when it started.
    static let babyAsleep = "babyAsleep"
    static let babyStateSince = "babyStateSince"

    // Collected during onboarding
    static let babyName = "babyName"
    static let babyAgeBand = "babyAgeBand"
    static let goalTitle = "goalTitle"
    static let goalTarget = "goalTarget"
    static let caregiverName = "caregiverName"
    static let caregiverRelation = "caregiverRelation"

    // Profile
    static let userName = "userName"
    static let userEmail = "userEmail"
}

/// The three destinations in the floating tab bar. Everything else in the app
/// is reached by pushing from Home.
enum AppTab: Hashable {
    case home, village, settings
}

struct ContentView: View {
    /// Owned by `RootView` so it outlives a language switch, which rebuilds
    /// everything from here down.
    @Binding var selectedTab: AppTab

    @EnvironmentObject private var language: LanguageStore

    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @State private var toast: String?

    init(selectedTab: Binding<AppTab>) {
        _selectedTab = selectedTab
        AppFont.register()
        // Warm "Avocation" skin behind SwiftUI Lists/Forms.
        UICollectionView.appearance().backgroundColor = UIColor(Theme.canvas)
    }

    var body: some View {
        // All three tabs stay alive so each keeps its own navigation stack and
        // scroll position; the glass bar floats over whichever one is showing.
        ZStack {
            HomeView(onToast: showToast).tabShown(selectedTab == .home)
            VillageView(onToast: showToast).tabShown(selectedTab == .village)
            SettingsView(onToast: showToast).tabShown(selectedTab == .settings)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            // 18pt off the bezel, as in the design. An overlay is laid out
            // inside the safe area, so the home-indicator inset is cancelled
            // out — otherwise the bar floats ~52pt up and wastes the strip
            // underneath it.
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 18 - Self.bottomSafeInset)
        }
        .tint(Theme.rose)
        .font(.nunito(16))
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            // Covers don't reliably inherit environment objects — the language
            // step needs the store, so hand it over explicitly.
            OnboardingView(onExit: showToast)
                .environmentObject(language)
        }
    }

    /// Height of the home-indicator inset, so the floating bar can be pinned
    /// relative to the physical bottom edge rather than the safe area.
    static var bottomSafeInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { if toast == message { toast = nil } }
        }
    }
}

private extension View {
    /// Keeps a tab in the hierarchy (preserving its state) while only the
    /// selected one is visible and interactive.
    func tabShown(_ shown: Bool) -> some View {
        opacity(shown ? 1 : 0)
            .allowsHitTesting(shown)
            .zIndex(shown ? 1 : 0)
    }
}

// MARK: - Floating tab bar

/// Translucent "liquid glass" pill holding Home / Community / Settings. It floats
/// clear of the screen edges and content scrolls underneath it.
struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    private struct Item: Identifiable {
        let tab: AppTab
        let symbol: String
        let label: String
        var id: AppTab { tab }
    }

    private let items = [
        Item(tab: .home, symbol: "house", label: L.Tabs.home),
        Item(tab: .village, symbol: "person.2", label: L.Tabs.community),
        Item(tab: .settings, symbol: "gearshape", label: L.Tabs.settings),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items) { pill($0) }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Theme.tabBarGlass)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(Theme.tabBarStroke, lineWidth: 1)
                }
                .shadow(color: Color(hex: 0x7A6248).opacity(0.22), radius: 17, y: 14)
                .shadow(color: Color(hex: 0x7A6248).opacity(0.10), radius: 3, y: 2)
        }
    }

    private func pill(_ item: Item) -> some View {
        let selected = selectedTab == item.tab
        let tint = selected ? Theme.tabIconOn : Theme.tabIconOff
        return Button {
            selectedTab = item.tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: 19, weight: .regular))
                    .frame(height: 22)
                Text(item.label)
                    .font(.nunito(11, .heavy))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.top, 9)
            .padding(.bottom, 7)
            .background(
                selected ? Theme.tabPillOn : .clear,
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: selected)
    }
}

#Preview {
    ContentView(selectedTab: .constant(.home))
        .environmentObject(LanguageStore.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

import SwiftUI

struct OnboardingView: View {
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 23
    @AppStorage(SettingsKeys.bedtimeHour) private var bedtimeHour = 21

    @State private var page = 0

    private let lastPage = 4

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(page == lastPage ? 0 : 1)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            TabView(selection: $page) {
                InfoPage(
                    emoji: "🌸",
                    tint: .pink,
                    title: "This one's for you, mama",
                    message: "You spend your days holding everyone together. This little app helps you find the pockets of time that belong to you — and actually use them."
                )
                .tag(0)

                InfoPage(
                    emoji: "🗓️",
                    tint: .blue,
                    title: "Map out your day",
                    message: "Add the things that fill your day — kids' routines, chores, appointments, and quiet windows like naps or school hours.",
                    accessory: { CategoryPreview() }
                )
                .tag(1)

                InfoPage(
                    emoji: "✨",
                    tint: .pink,
                    title: "Let the app find your time",
                    message: "Tap \u{201C}Find my time\u{201D} and it spots the free gaps in your day — favouring the calm ones when the little ones are settled.",
                    accessory: { SampleSlotCard() }
                )
                .tag(2)

                InfoPage(
                    emoji: "💛",
                    tint: .orange,
                    title: "Grow what matters to you",
                    message: "Set a goal — a language, stitching, a book, whatever lights you up. Book your me-time towards it and watch your week add up."
                )
                .tag(3)

                setupPage
                    .tag(lastPage)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            PageDots(count: lastPage + 1, current: page)
                .padding(.bottom, 8)

            Button(action: primaryAction) {
                Text(page == lastPage ? "Start finding my time" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
    }

    private var setupPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                HeroEmoji(emoji: "🌙", tint: .indigo)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    Text("When does your day run?")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("This helps the app search the right hours. You can always change it later in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 0) {
                    SetupRow(label: "My day starts") {
                        Picker("My day starts", selection: $dayStartHour) {
                            ForEach(4..<12, id: \.self) { Text(hourLabel($0)).tag($0) }
                        }
                    }
                    Divider().padding(.leading)
                    SetupRow(label: "My day ends") {
                        Picker("My day ends", selection: $dayEndHour) {
                            ForEach(19..<24, id: \.self) { Text(hourLabel($0)).tag($0) }
                        }
                    }
                    Divider().padding(.leading)
                    SetupRow(label: "Kids' bedtime") {
                        Picker("Kids' bedtime", selection: $bedtimeHour) {
                            ForEach(18..<23, id: \.self) { Text(hourLabel($0)).tag($0) }
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

                Text("All your data stays on this phone. Nothing is uploaded, ever. 🤍")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 24)
        }
    }

    private func primaryAction() {
        if page == lastPage {
            finish()
        } else {
            withAnimation { page += 1 }
        }
    }

    private func finish() {
        hasCompletedOnboarding = true
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

// MARK: - Info page

private struct InfoPage<Accessory: View>: View {
    let emoji: String
    let tint: Color
    let title: String
    let message: String
    @ViewBuilder var accessory: () -> Accessory

    init(
        emoji: String,
        tint: Color,
        title: String,
        message: String,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.emoji = emoji
        self.tint = tint
        self.title = title
        self.message = message
        self.accessory = accessory
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            HeroEmoji(emoji: emoji, tint: tint)
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            accessory()
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct HeroEmoji: View {
    let emoji: String
    let tint: Color

    var body: some View {
        Text(emoji)
            .font(.system(size: 72))
            .frame(width: 140, height: 140)
            .background(tint.opacity(0.15), in: Circle())
    }
}

// MARK: - Accessories

private struct CategoryPreview: View {
    private let rows: [[BlockCategory]] = [[.kids, .chores], [.appointment, .quiet]]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(rows[row]) { cat in
                        Label(cat.label, systemImage: cat.systemImage)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(cat.color.opacity(0.15), in: Capsule())
                            .foregroundStyle(cat.color)
                    }
                }
            }
        }
    }
}

private struct SampleSlotCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("✨ 1:00 PM – 2:30 PM")
                    .font(.subheadline.bold())
                Spacer()
                Text("90 min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("• The kids are settled — quiet time 🌙")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("• A lovely long stretch — 90 minutes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pink.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Small building blocks

private struct SetupRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            content()
                .labelsHidden()
                .tint(.pink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.pink : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: current)
            }
        }
    }
}

#Preview {
    OnboardingView()
}

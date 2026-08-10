import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 23
    @AppStorage(SettingsKeys.bedtimeHour) private var bedtimeHour = 21
    @AppStorage(SettingsKeys.minGapMinutes) private var minGapMinutes = 30
    @AppStorage(SettingsKeys.maxSlotMinutes) private var maxSlotMinutes = 120
    @AppStorage(SettingsKeys.showGuide) private var showGuide = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("My day starts", selection: $dayStartHour) {
                        ForEach(4..<12, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }
                    Picker("My day ends", selection: $dayEndHour) {
                        ForEach(19..<24, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }
                } header: {
                    Text("Your day")
                } footer: {
                    Text("The app only looks for me-time between these hours.")
                }

                Section {
                    Picker("Kids' bedtime", selection: $bedtimeHour) {
                        ForEach(18..<23, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }
                } footer: {
                    Text("Free time after bedtime gets a bonus — the house is quiet. 🌙")
                }

                Section {
                    Picker("Minimum gap", selection: $minGapMinutes) {
                        ForEach([15, 20, 30, 45, 60], id: \.self) { minutes in
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }
                } footer: {
                    Text("Gaps shorter than this won't be suggested — you deserve more than a rushed five minutes.")
                }

                Section {
                    Picker("Longest suggestion", selection: $maxSlotMinutes) {
                        ForEach([60, 90, 120, 180], id: \.self) { minutes in
                            Text(durationLabel(minutes)).tag(minutes)
                        }
                    }
                } footer: {
                    Text("A long free stretch is trimmed to a session this size, so each me-time is something you can actually take — and tick off.")
                }

                Section {
                    Toggle("Show getting-started guide", isOn: $showGuide)
                } header: {
                    Text("Getting started")
                } footer: {
                    Text("Little tips that point out where to tap. They show once on the blank starting screen for a new day with nothing scheduled, then this turns off. Switch it back on to see them again.")
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                } footer: {
                    Text("All your data stays on this phone. Nothing is uploaded, ever. 🤍")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes >= 60 && minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        if minutes > 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes) minutes"
    }

    private func hourLabel(_ hour: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

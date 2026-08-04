import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 23
    @AppStorage(SettingsKeys.bedtimeHour) private var bedtimeHour = 21
    @AppStorage(SettingsKeys.minGapMinutes) private var minGapMinutes = 30

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
                    LabeledContent("Version", value: "1.0")
                } footer: {
                    Text("All your data stays on this phone. Nothing is uploaded, ever. 🤍")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.dayStartHour) private var dayStartHour = 6
    @AppStorage(SettingsKeys.dayEndHour) private var dayEndHour = 23
    @AppStorage(SettingsKeys.bedtimeHour) private var bedtimeHour = 21
    @AppStorage(SettingsKeys.minGapMinutes) private var minGapMinutes = 30
    @AppStorage(SettingsKeys.showGuide) private var showGuide = true
    @AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.baloo(30, heavy: true))
                    .foregroundStyle(ST.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("YOUR DAY").padding(.bottom, 8)

                // Day hours card (two read-out rows)
                VStack(spacing: 0) {
                    row("My day starts", value: hourLabel(dayStartHour), vpad: 15)
                    Rectangle().fill(ST.divider).frame(height: 1)
                    row("My day ends", value: hourLabel(dayEndHour), vpad: 15)
                }
                .padding(.horizontal, 18).padding(.vertical, 2)
                .background(.white, in: RoundedRectangle(cornerRadius: 26))
                .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)

                hint("The app only looks for me-time between these hours.")

                card {
                    HStack {
                        Text("Kids' bedtime").font(.nunito(15, .bold)).foregroundStyle(ST.textPrimary)
                        Spacer()
                        Text(hourLabel(bedtimeHour)).font(.nunito(14, .heavy)).foregroundStyle(ST.valueText)
                    }
                    .padding(.vertical, 15)
                }
                .padding(.top, 14)
                hint("Free time after bedtime gets a bonus — the house is quiet.")

                card {
                    HStack {
                        Text("Minimum gap").font(.nunito(15, .bold)).foregroundStyle(ST.textPrimary)
                        Spacer()
                        gapStepper
                    }
                    .padding(.vertical, 15)
                }
                .padding(.top, 14)
                hint("Gaps shorter than this won't be suggested — you deserve more than a rushed five minutes.")

                card {
                    HStack {
                        Text("Show getting-started guide").font(.nunito(15, .bold)).foregroundStyle(ST.textPrimary)
                        Spacer()
                        guideToggle
                    }
                    .padding(.vertical, 13)
                }
                .padding(.top, 14)

                Button { hasCompletedOnboarding = false } label: {
                    card {
                        HStack {
                            Text("Run setup again").font(.nunito(15, .bold)).foregroundStyle(ST.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(ST.chevron)
                        }
                        .padding(.vertical, 15)
                    }
                }
                .buttonStyle(LiftCardStyle())
                .padding(.top, 10)
            }
            .padding(.top, 14)
            .padding(.horizontal, 18)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ST.screenBg.ignoresSafeArea())
    }

    // MARK: Building blocks

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(ST.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ label: String, value: String, vpad: CGFloat) -> some View {
        HStack {
            Text(label).font(.nunito(15, .bold)).foregroundStyle(ST.textPrimary)
            Spacer()
            Text(value).font(.nunito(14, .heavy)).foregroundStyle(ST.valueText)
        }
        .padding(.vertical, vpad)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 26))
            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.nunito(11.5, .semibold)).lineSpacing(4)
            .foregroundStyle(ST.hintText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8).padding(.horizontal, 4)
    }

    private var gapStepper: some View {
        HStack(spacing: 0) {
            Button { minGapMinutes = max(15, minGapMinutes - 15) } label: {
                Text("−").font(.nunito(16, .heavy)).foregroundStyle(Color(hex: 0x8A7E72)).frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
            Text(gapLabel(minGapMinutes))
                .font(.nunito(13, .heavy)).foregroundStyle(Color(hex: 0x6E6358)).frame(minWidth: 70)
            Button { minGapMinutes = min(120, minGapMinutes + 15) } label: {
                Text("+").font(.nunito(16, .heavy)).foregroundStyle(ST.accentPlus).frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(ST.fieldFill, in: Capsule())
    }

    private var guideToggle: some View {
        Button { showGuide.toggle() } label: {
            ZStack(alignment: showGuide ? .trailing : .leading) {
                Capsule().fill(showGuide ? ST.toggleOn : ST.toggleOff).frame(width: 50, height: 30)
                Circle().fill(.white).frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2.5, y: 2).padding(3)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: showGuide)
    }

    private func gapLabel(_ m: Int) -> String {
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }

    private func hourLabel(_ hour: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

/// Lifts a settings card slightly while pressed.
private struct LiftCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -1 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Settings palette

private enum ST {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let valueText = Color(hex: 0x9A8D80)
    static let hintText = Color(hex: 0xA99B8C)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let divider = Color(hex: 0x7A6248).opacity(0.1)
    static let accentPlus = Color(hex: 0xC97B8C)
    static let chevron = Color(hex: 0xC6B9AA)
    static let toggleOff = Color(hex: 0xE7DFD4)
    static let toggleOn = Color(hex: 0x7FBFAE)
}

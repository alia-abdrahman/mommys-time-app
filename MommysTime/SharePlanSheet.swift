import SwiftUI
import CoreData

/// Which day's plan is being shared. View state only.
enum PlanDay: CaseIterable {
    case today, tomorrow

    var label: String {
        self == .today ? L.Common.today : L.Common.tomorrow
    }

    /// Possessive form for the "sent" toast — "Today's plan sent to …".
    var possessive: String {
        self == .today ? L.SharePlan.daySentToday : L.SharePlan.daySentTomorrow
    }
}

struct SharePlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.caregiverRelation) private var caregiverRelation = CaregiverRelation.husband

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleBlock.startTime, ascending: true)],
        animation: .default
    )
    private var allBlocks: FetchedResults<ScheduleBlock>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.date, ascending: true)],
        animation: .default
    )
    private var appointments: FetchedResults<Appointment>

    var onSent: (String) -> Void = { _ in }

    @State private var day = PlanDay.today
    @State private var caregiver = CaregiverRelation.husband
    @State private var showingShare = false

    private let caregivers = [
        CaregiverRelation.husband, CaregiverRelation.grandma, CaregiverRelation.sitter,
    ]

    private var chosenDate: Date {
        if day == .today { return Date() }
        return Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    private struct Item: Identifiable {
        let id = UUID()
        let start: Date
        let end: Date
        let title: String
        let category: BlockCategory
    }

    private var items: [Item] {
        allBlocks
            .compactMap { block -> Item? in
                guard let t = block.resolvedTimes(on: chosenDate) else { return nil }
                return Item(start: t.start, end: t.end, title: block.title ?? "", category: block.blockCategory)
            }
            .sorted { $0.start < $1.start }
    }

    private var meTime: Item? { items.first { $0.category == .meTime } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                daySegments.padding(.top, 16)
                previewCard.padding(.top, 14)
                sectionLabel(L.SharePlan.sendTo).padding(.top, 16).padding(.bottom, 8)
                caregiverChips
                sendButton.padding(.top, 16)
                finePrint.padding(.top, 10)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(SH.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(SH.sheetBg)
        .presentationDragIndicator(.hidden)
        .onAppear {
            if caregivers.contains(caregiverRelation) { caregiver = caregiverRelation }
        }
        .sheet(isPresented: $showingShare, onDismiss: finishSend) {
            SharePlanActivitySheet(text: planText(chosenDate))
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(L.SharePlan.title)
                .font(.baloo(17, heavy: true))
                .foregroundStyle(SH.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text(L.Common.cancel)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(SH.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Color.clear.frame(width: 64, height: 1)
            }
        }
    }

    // MARK: Day segments

    private var daySegments: some View {
        HStack(spacing: 4) {
            ForEach(PlanDay.allCases, id: \.self) { d in
                let sel = d == day
                Button { withAnimation(.easeInOut(duration: 0.2)) { day = d } } label: {
                    Text(d.label)
                        .font(.nunito(13.5, .heavy))
                        .foregroundStyle(sel ? SH.textPrimary : SH.segIdleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if sel {
                                Capsule().fill(.white)
                                    .shadow(color: Color(hex: 0x7A6248).opacity(0.14), radius: 9, y: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(SH.segTrack, in: Capsule())
    }

    // MARK: Preview card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(chosenDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                    .font(.baloo(17, heavy: true))
                    .foregroundStyle(SH.textPrimary)
                Spacer()
                Text(countLabel)
                    .font(.nunito(11, .heavy))
                    .foregroundStyle(SH.textMuted)
            }

            if items.isEmpty {
                Text(L.SharePlan.emptyPreview)
                    .font(.nunito(13, .semibold)).lineSpacing(6)
                    .foregroundStyle(SH.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 11) {
                            Text(item.start, format: .dateTime.hour().minute())
                                .font(.nunito(11.5, .heavy))
                                .foregroundStyle(SH.textMuted)
                                .frame(width: 64, alignment: .leading)
                                .padding(.top, 2)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.category.color)
                                .frame(width: 3)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title)
                                    .font(.nunito(14, .heavy))
                                    .foregroundStyle(SH.textPrimary)
                                Text(L.SharePlan.itemMeta(durationLabel(item), item.category.label))
                                    .font(.nunito(11.5, .semibold))
                                    .foregroundStyle(SH.textMuted)
                            }
                            Spacer(minLength: 0)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 12)
            }

            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(SH.hairline).frame(height: 1)
                Text(askText)
                    .font(.nunito(12, .bold)).lineSpacing(5)
                    .foregroundStyle(SH.askText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            .padding(.top, 14)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 16, y: 6)
    }

    private var countLabel: String {
        items.isEmpty ? L.SharePlan.countEmpty : L.SharePlan.count(items.count)
    }

    private var askText: String {
        guard let m = meTime else { return L.SharePlan.askEmpty }
        return L.SharePlan.ask(
            start: m.start.formatted(.dateTime.hour().minute()),
            end: m.end.formatted(.dateTime.hour().minute()),
            duration: durationLabel(m)
        )
    }

    /// The plain-language summary handed to the OS share sheet — readable by a
    /// caregiver who doesn't have the app.
    private func planText(_ day: Date) -> String {
        let calendar = Calendar.current
        let dayLabel = day.formatted(.dateTime.weekday(.wide).day().month())
        var lines = [L.SharePlan.exportHeading(dayLabel), ""]

        if !items.isEmpty {
            lines.append(L.SharePlan.exportSchedule)
            for item in items {
                let s = item.start.formatted(.dateTime.hour().minute())
                let e = item.end.formatted(.dateTime.hour().minute())
                lines.append(L.SharePlan.exportBlock(start: s, end: e, title: item.title))
            }
            lines.append("")
        }

        let dayAppointments = appointments
            .filter { calendar.isDate($0.date ?? .distantPast, inSameDayAs: day) }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        if !dayAppointments.isEmpty {
            lines.append(L.SharePlan.exportAppointments)
            for appt in dayAppointments {
                let time = appt.date?.formatted(.dateTime.hour().minute()) ?? ""
                var line = L.SharePlan.exportAppointment(time: time, title: appt.title ?? "")
                if let location = appt.location, !location.isEmpty {
                    line += L.SharePlan.exportAppointmentLocation(location)
                }
                lines.append(line)
            }
            lines.append("")
        }

        if items.isEmpty && dayAppointments.isEmpty {
            lines.append(L.SharePlan.exportNothing)
            lines.append("")
        }

        lines.append(L.SharePlan.exportFooter)
        return lines.joined(separator: "\n")
    }

    private func durationLabel(_ item: Item) -> String {
        L.Duration.compact(max(0, Int(item.end.timeIntervalSince(item.start) / 60)))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(SH.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Caregiver chips

    private var caregiverChips: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(caregivers, id: \.self) { name in
                let sel = name == caregiver
                Button { caregiver = name } label: {
                    Text(CaregiverRelation.label(name))
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(sel ? .white : SH.textSecondary)
                        .padding(.vertical, 10).padding(.horizontal, 16)
                        .background(sel ? SH.roseCTA : .white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(sel ? 0 : 0.08), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: CTA / footer

    private var sendButton: some View {
        Button { showingShare = true } label: {
            HStack(spacing: 9) {
                Image(systemName: "paperplane")
                    .font(.system(size: 16, weight: .semibold))
                Text(L.SharePlan.sendButton(CaregiverRelation.label(caregiver)))
                    .font(.baloo(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(SH.roseCTA, in: Capsule())
            .shadow(color: Color(hex: 0xBE5F78).opacity(0.4), radius: 20, y: 9)
        }
        .buttonStyle(.plain)
    }

    private var finePrint: some View {
        Text(L.SharePlan.finePrint)
            .font(.nunito(11.5, .semibold)).lineSpacing(4)
            .foregroundStyle(SH.hintText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func finishSend() {
        let message = L.SharePlan.sentToast(
            day: day.possessive,
            caregiver: CaregiverRelation.label(caregiver)
        )
        dismiss()
        onSent(message)
    }
}

/// OS share sheet wrapper for the composed plan text.
private struct SharePlanActivitySheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Share plan palette

private enum SH {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let segTrack = Color(hex: 0xF4EDE4)
    static let segIdleText = Color(hex: 0xA99B8C)
    static let roseCTA = Color(hex: 0xD9758C)
    static let askText = Color(hex: 0x8A6A44)
    static let hintText = Color(hex: 0xA99B8C)
    static let hairline = Color(hex: 0x7A6248).opacity(0.12)
}

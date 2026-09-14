import SwiftUI
import CoreData

struct AppointmentsView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.date, ascending: true)],
        animation: .default
    )
    private var appointments: FetchedResults<Appointment>

    @State private var showingAdd = false
    @State private var editing: Appointment?
    @State private var selectedDate = Date()
    @State private var calendarMode = CalendarMode.week
    @State private var toast: String?

    private let calendar = Calendar.current

    /// The chosen day's appointments, earliest first.
    private var dayAppointments: [Appointment] {
        appointments
            .filter { calendar.isDate($0.date ?? .distantPast, inSameDayAs: selectedDate) }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScheduleCalendarCard(date: $selectedDate, mode: $calendarMode, hasEntries: hasAppointments)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                if dayAppointments.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 9) {
                        ForEach(dayAppointments, id: \.objectID) { appt in
                            AppointmentCard(appointment: appt) { delete(appt) }
                                .contentShape(Rectangle())
                                .onTapGesture { editing = appt }
                                .contextMenu {
                                    Button("Edit") { editing = appt }
                                    Button("Delete", role: .destructive) { delete(appt) }
                                }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) {
            AppointmentSheet(day: selectedDate)
        }
        .sheet(item: $editing) { appt in
            AppointmentSheet(appointment: appt)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        DetailHeader(title: "Appointment", onBack: { dismiss() }) {
            CircleAddButton { showingAdd = true }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Nothing booked this day")
                .font(.baloo(21, heavy: true))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Clinic visits, jabs, check-ups — add them here and they'll ride along in the plan you share.")
                .font(.nunito(14, .semibold))
                .lineSpacing(6)
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 34)
        .padding(.top, 22)
    }

    private func hasAppointments(_ day: Date) -> Bool {
        appointments.contains { calendar.isDate($0.date ?? .distantPast, inSameDayAs: day) }
    }

    private func delete(_ appointment: Appointment) {
        let label = appointment.title ?? "Appointment"
        withAnimation { context.delete(appointment) }
        try? context.save()
        showToast("\(label) removed")
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }
}

private struct AppointmentCard: View {
    @ObservedObject var appointment: Appointment
    var onRemove: () -> Void

    private var weekday: String {
        (appointment.date ?? Date()).formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }
    private var day: String {
        (appointment.date ?? Date()).formatted(.dateTime.day())
    }
    private var subtitle: String {
        let time = (appointment.date ?? Date()).formatted(.dateTime.hour().minute())
        if let location = appointment.location, !location.isEmpty {
            return "\(time) · \(location)"
        }
        return time
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(weekday)
                    .font(.nunito(9, .heavy))
                    .tracking(0.6)
                    .foregroundStyle(Theme.tileGlyph)
                Text(day)
                    .font(.nunito(18, .heavy))
                    .foregroundStyle(Theme.roseInk)
            }
            .frame(width: 44, height: 44)
            .background(Theme.peach, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title ?? "")
                    .font(.nunito(15, .heavy))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.nunito(12, .bold))
                    .foregroundStyle(Theme.inkFaint)
            }
            Spacer(minLength: 0)

            Button(action: onRemove) {
                Text("×")
                    .font(.nunito(13, .heavy))
                    .foregroundStyle(Color(hex: 0xB7AA9B))
                    .frame(width: 26, height: 26)
                    .background(.white, in: Circle())
                    .overlay(Circle().stroke(Color(hex: 0x7A6248).opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }
}

struct AppointmentSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let appointment: Appointment?
    /// Day the calendar is showing, so a new appointment lands there.
    var day: Date = Date()

    @State private var title: String
    @State private var date: Date
    @State private var location: String
    @State private var notes: String
    @State private var showingDeleteConfirmation = false
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @FocusState private var focused: Bool

    init(appointment: Appointment? = nil, day: Date = Date()) {
        self.appointment = appointment
        self.day = day
        _title = State(initialValue: appointment?.title ?? "")
        _date = State(initialValue: appointment?.date ?? Self.defaultTime(on: day))
        _location = State(initialValue: appointment?.location ?? "")
        _notes = State(initialValue: appointment?.notes ?? "")
    }

    /// 10:00 on the shown day — the design's default for a new appointment.
    private static func defaultTime(on day: Date) -> Date {
        Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? day
    }

    private var isEditing: Bool { appointment != nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header

                sectionLabel("APPOINTMENT").padding(.top, 20).padding(.bottom, 8)
                detailsCard

                sectionLabel("NOTES").padding(.top, 20).padding(.bottom, 8)
                notesCard

                if isEditing {
                    Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                        Text("Delete appointment")
                            .font(.nunito(15, .bold))
                            .foregroundStyle(Color(hex: 0xC85C5C))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 22))
                            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 12, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                }
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(AP.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(AP.sheetBg)
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showingDatePicker) {
            pickerSheet(title: "Date", components: .date, style: .graphical)
        }
        .sheet(isPresented: $showingTimePicker) {
            pickerSheet(title: "Time", components: .hourAndMinute, style: .wheel)
        }
        .confirmationDialog(
            "Delete this appointment?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteAppointment() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit Appointment" : "New Appointment")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(AP.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(AP.textSecondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : AP.disabledText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 18)
                        .background(canSave ? AP.accentRose : AP.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy))
            .tracking(0.8)
            .foregroundStyle(AP.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Details card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            TextField("Title (e.g. Baby checkup)", text: $title)
                .font(.nunito(15, .bold))
                .foregroundStyle(AP.textPrimary)
                .tint(AP.accentRose)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)

            rowDivider

            HStack {
                Text("Date & time").font(.nunito(15, .bold)).foregroundStyle(AP.textPrimary)
                Spacer()
                pill(date.formatted(.dateTime.day().month(.abbreviated).year())) { showingDatePicker = true }
                pill(date.formatted(.dateTime.hour().minute())) { showingTimePicker = true }
            }
            .padding(.vertical, 12)

            rowDivider

            TextField("Location (optional)", text: $location)
                .font(.nunito(15, .bold))
                .foregroundStyle(AP.textPrimary)
                .tint(AP.accentRose)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private var notesCard: some View {
        TextField("Anything to remember…", text: $notes, axis: .vertical)
            .font(.nunito(15, .semibold))
            .foregroundStyle(AP.textPrimary)
            .tint(AP.accentRose)
            .lineLimit(3, reservesSpace: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func pill(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.nunito(14, .heavy))
                .foregroundStyle(AP.valueText)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(AP.fieldFill, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color(hex: 0x7A6248).opacity(0.1)).frame(height: 1)
    }

    private func pickerSheet(title: String, components: DatePickerComponents, style: some DatePickerStyle) -> some View {
        NavigationStack {
            DatePicker("", selection: $date, displayedComponents: components)
                .datePickerStyle(style)
                .labelsHidden()
                .tint(AP.accentRose)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(AP.sheetBg)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingDatePicker = false; showingTimePicker = false }
                            .tint(AP.accentRose)
                    }
                }
        }
        .presentationDetents(components == .date ? [.medium] : [.height(300)])
        .presentationBackground(AP.sheetBg)
    }

    private func save() {
        let appt = appointment ?? Appointment(context: context)
        if appointment == nil {
            appt.id = UUID()
            appt.createdAt = Date()
        }
        appt.title = title.trimmingCharacters(in: .whitespaces)
        appt.date = date
        appt.location = location.trimmingCharacters(in: .whitespaces)
        appt.notes = notes
        try? context.save()
        dismiss()
    }

    private func deleteAppointment() {
        if let appointment {
            context.delete(appointment)
            try? context.save()
        }
        dismiss()
    }
}

// MARK: - Appointment sheet palette

private enum AP {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let accentRose = Color(hex: 0xD98FA0)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let valueText = Color(hex: 0x6E6358)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
}

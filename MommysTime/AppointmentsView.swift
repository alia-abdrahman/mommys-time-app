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

    /// Upcoming first (soonest first), then past (most recent first).
    private var orderedAppointments: [Appointment] {
        let now = Date()
        let upcoming = appointments.filter { ($0.date ?? .distantPast) >= now }
        let past = appointments.filter { ($0.date ?? .distantPast) < now }.reversed()
        return upcoming + Array(past)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(orderedAppointments, id: \.objectID) { appt in
                        AppointmentCard(appointment: appt)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = appt }
                            .contextMenu {
                                Button("Edit") { editing = appt }
                                Button("Delete", role: .destructive) { delete(appt) }
                            }
                    }
                    addButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
            }
        }
        .background(Theme.canvas)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) {
            AppointmentSheet()
        }
        .sheet(item: $editing) { appt in
            AppointmentSheet(appointment: appt)
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0x8B7F72))
                    .frame(width: 38, height: 38)
                    .background(Color.white, in: Circle())
                    .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 6, y: 3)
            }
            Spacer()
            Text("Appointment")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Theme.rose, in: Circle())
                    .shadow(color: Theme.rose.opacity(0.4), radius: 7, y: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var addButton: some View {
        Button { showingAdd = true } label: {
            Text("+ Add appointment")
                .font(.nunito(13, .heavy))
                .foregroundStyle(Color(hex: 0xA182AD))
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color(hex: 0xA182AD).opacity(0.45),
                                      style: StrokeStyle(lineWidth: 2, dash: [6]))
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private func delete(_ appointment: Appointment) {
        context.delete(appointment)
        try? context.save()
    }
}

private struct AppointmentCard: View {
    @ObservedObject var appointment: Appointment

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
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(weekday)
                    .font(.nunito(9, .heavy))
                    .tracking(0.6)
                    .foregroundStyle(Color(hex: 0xA182AD))
                Text(day)
                    .font(.nunito(18, .heavy))
                    .foregroundStyle(Color(hex: 0x6B5A75))
            }
            .frame(width: 48, height: 48)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title ?? "")
                    .font(.nunito(16, .heavy))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.nunito(12.5, .semibold))
                    .foregroundStyle(Color(hex: 0x9A8D80))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color(hex: 0xF2E7F3), in: RoundedRectangle(cornerRadius: 24))
    }
}

struct AppointmentSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let appointment: Appointment?

    @State private var title: String
    @State private var date: Date
    @State private var location: String
    @State private var notes: String
    @State private var showingDeleteConfirmation = false
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @FocusState private var focused: Bool

    init(appointment: Appointment? = nil) {
        self.appointment = appointment
        _title = State(initialValue: appointment?.title ?? "")
        _date = State(initialValue: appointment?.date ?? Date())
        _location = State(initialValue: appointment?.location ?? "")
        _notes = State(initialValue: appointment?.notes ?? "")
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

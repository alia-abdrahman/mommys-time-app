import SwiftUI
import CoreData

struct AppointmentsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.date, ascending: true)],
        animation: .default
    )
    private var appointments: FetchedResults<Appointment>

    @State private var showingAdd = false
    @State private var editing: Appointment?

    private var upcoming: [Appointment] {
        let now = Date()
        return appointments.filter { ($0.date ?? .distantPast) >= now }
    }

    private var past: [Appointment] {
        let now = Date()
        return appointments.filter { ($0.date ?? .distantPast) < now }.reversed()
    }

    var body: some View {
        Group {
            if appointments.isEmpty {
                emptyState
            } else {
                List {
                    if !upcoming.isEmpty {
                        Section("Upcoming") {
                            ForEach(upcoming, id: \.objectID) { appt in
                                AppointmentRow(appointment: appt)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editing = appt }
                            }
                            .onDelete { delete(upcoming, at: $0) }
                        }
                    }
                    if !past.isEmpty {
                        Section("Past") {
                            ForEach(past, id: \.objectID) { appt in
                                AppointmentRow(appointment: appt)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editing = appt }
                            }
                            .onDelete { delete(past, at: $0) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AppointmentSheet()
        }
        .sheet(item: $editing) { appt in
            AppointmentSheet(appointment: appt)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🗓️")
                .font(.system(size: 56))
            Text("No appointments yet")
                .font(.title3.bold())
            Text("Add your little one's checkups, your own visits and anything else you don't want to forget.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add an appointment") { showingAdd = true }
                .buttonStyle(.bordered)
        }
        .padding(32)
    }

    private func delete(_ list: [Appointment], at offsets: IndexSet) {
        for index in offsets {
            context.delete(list[index])
        }
        try? context.save()
    }
}

private struct AppointmentRow: View {
    @ObservedObject var appointment: Appointment

    private var isPast: Bool { (appointment.date ?? .distantPast) < Date() }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(isPast ? Color.secondary : Color.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.title ?? "")
                    .font(.body)
                if let date = appointment.date {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let location = appointment.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(isPast ? 0.6 : 1)
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

    init(appointment: Appointment? = nil) {
        self.appointment = appointment
        _title = State(initialValue: appointment?.title ?? "")
        _date = State(initialValue: appointment?.date ?? Date())
        _location = State(initialValue: appointment?.location ?? "")
        _notes = State(initialValue: appointment?.notes ?? "")
    }

    private var isEditing: Bool { appointment != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appointment") {
                    TextField("Title (e.g. Pediatrician checkup)", text: $title)
                    DatePicker("Date & time", selection: $date)
                    TextField("Location (optional)", text: $location)
                }
                Section("Notes") {
                    TextField("Anything to remember…", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                if isEditing {
                    Section {
                        Button("Delete appointment", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Appointment" : "New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
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

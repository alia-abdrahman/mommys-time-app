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

    /// Upcoming first (soonest first), then past (most recent first).
    private var orderedAppointments: [Appointment] {
        let now = Date()
        let upcoming = appointments.filter { ($0.date ?? .distantPast) >= now }
        let past = appointments.filter { ($0.date ?? .distantPast) < now }.reversed()
        return upcoming + Array(past)
    }

    var body: some View {
        Group {
            if appointments.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(orderedAppointments, id: \.objectID) { appt in
                            AppointmentCard(appointment: appt)
                                .contentShape(Rectangle())
                                .onTapGesture { editing = appt }
                                .contextMenu {
                                    Button("Edit") { editing = appt }
                                    Button("Delete", role: .destructive) { delete(appt) }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Appointment")
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

    private func delete(_ appointment: Appointment) {
        context.delete(appointment)
        try? context.save()
    }
}

private struct AppointmentCard: View {
    @ObservedObject var appointment: Appointment

    private var isPast: Bool { (appointment.date ?? .distantPast) < Date() }

    var body: some View {
        VStack(spacing: 6) {
            Text(appointment.title ?? "")
                .font(.headline)
                .multilineTextAlignment(.center)
            if let date = appointment.date {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let location = appointment.location, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.purple.opacity(isPast ? 0.06 : 0.12), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.purple.opacity(isPast ? 0.15 : 0.3), lineWidth: 1)
        )
        .opacity(isPast ? 0.65 : 1)
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
                    TextField("Title (e.g. Baby checkup)", text: $title)
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

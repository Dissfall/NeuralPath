//
//  AddUserMedicationView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct AddUserMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var dosage: String
    @State private var category: MedicationCategory?
    @State private var frequency: MedicationFrequency
    @State private var notes: String
    @State private var startDate: Date
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date

    private let medication: UserMedication?
    private var isEditing: Bool { medication != nil }

    init(medication: UserMedication? = nil) {
        self.medication = medication
        _name = State(initialValue: medication?.name ?? "")
        _dosage = State(initialValue: medication?.dosage ?? "")
        _category = State(initialValue: medication?.category)
        _frequency = State(initialValue: medication?.frequency ?? .onceDaily)
        _notes = State(initialValue: medication?.notes ?? "")
        _startDate = State(initialValue: medication?.startDate ?? Date())
        _reminderEnabled = State(initialValue: medication?.reminderEnabled ?? false)

        // Default reminder time to 8 AM if not set
        if let existingTime = medication?.reminderTime {
            _reminderTime = State(initialValue: existingTime)
        } else {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Medication Name", text: $name)
                        .autocorrectionDisabled()

                    TextField("Dosage (e.g., 20mg, 1 tablet)", text: $dosage)
                        .autocorrectionDisabled()
                } header: {
                    Text("Basic Information")
                }

                Section {
                    Picker("Category", selection: $category) {
                        Text("None").tag(nil as MedicationCategory?)
                        ForEach(MedicationCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat as MedicationCategory?)
                        }
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(MedicationFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                } header: {
                    Text("Schedule")
                }

                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                } header: {
                    Text("Timeline")
                }

                Section {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Label("Reminder", systemImage: "bell.fill")
                } footer: {
                    Text("Get a daily notification to take this medication at your chosen time")
                }

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add any instructions, side effects, or other notes")
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveMedication()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveMedication() {
        if let medication = medication {
            medication.name = name
            medication.dosage = dosage
            medication.category = category
            medication.frequency = frequency
            medication.notes = notes
            medication.startDate = startDate
            medication.reminderEnabled = reminderEnabled
            medication.reminderTime = reminderTime
        } else {
            let newMedication = UserMedication(
                name: name,
                dosage: dosage,
                category: category,
                frequency: frequency,
                notes: notes,
                startDate: startDate,
                reminderTime: reminderEnabled ? reminderTime : nil,
                reminderEnabled: reminderEnabled
            )
            modelContext.insert(newMedication)
        }

        // Reschedule all medication reminders
        MedicationReminderService.shared.scheduleMedicationRemindersFromContext()

        dismiss()
    }
}

#Preview {
    AddUserMedicationView()
        .modelContainer(for: UserMedication.self)
}

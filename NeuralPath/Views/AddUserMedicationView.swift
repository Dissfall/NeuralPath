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

    init(medication: UserMedication? = nil, prefilledMedication: MedicationInfo? = nil) {
        self.medication = medication

        // Priority: editing existing > prefilled from database > empty
        if let existingMed = medication {
            _name = State(initialValue: existingMed.name ?? "")
            _dosage = State(initialValue: existingMed.dosage ?? "")
            _category = State(initialValue: existingMed.category)
            _frequency = State(initialValue: existingMed.frequency ?? .onceDaily)
            _notes = State(initialValue: existingMed.notes ?? "")
            _startDate = State(initialValue: existingMed.startDate ?? Date())
            _reminderEnabled = State(initialValue: existingMed.reminderEnabled ?? false)

            if let existingTime = existingMed.reminderTime {
                _reminderTime = State(initialValue: existingTime)
            } else {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = 8
                components.minute = 0
                _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
            }
        } else if let prefilled = prefilledMedication {
            _name = State(initialValue: prefilled.name)
            _dosage = State(initialValue: "")
            _category = State(initialValue: prefilled.category)
            _frequency = State(initialValue: .onceDaily)
            _notes = State(initialValue: "")
            _startDate = State(initialValue: Date())
            _reminderEnabled = State(initialValue: false)

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
        } else {
            _name = State(initialValue: "")
            _dosage = State(initialValue: "")
            _category = State(initialValue: nil)
            _frequency = State(initialValue: .onceDaily)
            _notes = State(initialValue: "")
            _startDate = State(initialValue: Date())
            _reminderEnabled = State(initialValue: false)

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

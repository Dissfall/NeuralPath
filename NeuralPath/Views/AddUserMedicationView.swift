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
    @State private var timeOfDay: MedicationTimeOfDay
    @State private var customReminderTime: Date

    private let medication: UserMedication?
    private var isEditing: Bool { medication != nil }

    init(medication: UserMedication? = nil, prefilledMedication: MedicationInfo? = nil) {
        self.medication = medication

        let defaultCustomTime: Date = {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()

        // Priority: editing existing > prefilled from database > empty
        if let existingMed = medication {
            _name = State(initialValue: existingMed.name ?? "")
            _dosage = State(initialValue: existingMed.dosage ?? "")
            _category = State(initialValue: existingMed.category)
            _frequency = State(initialValue: existingMed.frequency ?? .onceDaily)
            _notes = State(initialValue: existingMed.notes ?? "")
            _startDate = State(initialValue: existingMed.startDate ?? Date())
            _reminderEnabled = State(initialValue: existingMed.reminderEnabled ?? false)
            _timeOfDay = State(initialValue: existingMed.timeOfDay ?? .morning)
            _customReminderTime = State(initialValue: existingMed.customReminderTime ?? defaultCustomTime)
        } else if let prefilled = prefilledMedication {
            _name = State(initialValue: prefilled.name)
            _dosage = State(initialValue: "")
            _category = State(initialValue: prefilled.category)
            _frequency = State(initialValue: .onceDaily)
            _notes = State(initialValue: "")
            _startDate = State(initialValue: Date())
            _reminderEnabled = State(initialValue: false)
            _timeOfDay = State(initialValue: .morning)
            _customReminderTime = State(initialValue: defaultCustomTime)
        } else {
            _name = State(initialValue: "")
            _dosage = State(initialValue: "")
            _category = State(initialValue: nil)
            _frequency = State(initialValue: .onceDaily)
            _notes = State(initialValue: "")
            _startDate = State(initialValue: Date())
            _reminderEnabled = State(initialValue: false)
            _timeOfDay = State(initialValue: .morning)
            _customReminderTime = State(initialValue: defaultCustomTime)
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
                        Picker("Time of Day", selection: $timeOfDay) {
                            ForEach(MedicationTimeOfDay.allCases) { tod in
                                Label(tod.displayName, systemImage: tod.icon)
                                    .tag(tod)
                            }
                        }

                        if timeOfDay == .custom {
                            DatePicker("Custom Time", selection: $customReminderTime, displayedComponents: .hourAndMinute)
                        } else {
                            HStack {
                                Text("Default Time")
                                Spacer()
                                Text(defaultTimeString(for: timeOfDay))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Label("Reminder", systemImage: "bell.fill")
                } footer: {
                    if reminderEnabled && timeOfDay != .custom {
                        Text("You can change default \(timeOfDay.displayName.lowercased()) time in Settings")
                    } else if reminderEnabled && timeOfDay == .custom {
                        Text("This medication will have its own reminder at the specified time")
                    } else {
                        Text("Get a daily notification to take this medication")
                    }
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
            medication.timeOfDay = reminderEnabled ? timeOfDay : nil
            medication.customReminderTime = (timeOfDay == .custom) ? customReminderTime : nil
        } else {
            let newMedication = UserMedication(
                name: name,
                dosage: dosage,
                category: category,
                frequency: frequency,
                notes: notes,
                startDate: startDate,
                reminderEnabled: reminderEnabled,
                timeOfDay: reminderEnabled ? timeOfDay : .morning,
                customReminderTime: (timeOfDay == .custom) ? customReminderTime : nil
            )
            modelContext.insert(newMedication)
        }

        // Reschedule all medication reminders
        MedicationReminderService.shared.scheduleMedicationRemindersFromContext()

        dismiss()
    }

    private func defaultTimeString(for timeOfDay: MedicationTimeOfDay) -> String {
        let time = MedicationReminderService.getReminderTime(for: timeOfDay)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

#Preview {
    AddUserMedicationView()
        .modelContainer(for: UserMedication.self)
}

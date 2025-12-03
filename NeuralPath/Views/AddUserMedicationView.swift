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
    @State private var weeklyReminderDay: Int

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
            _weeklyReminderDay = State(initialValue: existingMed.weeklyReminderDay ?? 2)
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
            _weeklyReminderDay = State(initialValue: 2)
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
            _weeklyReminderDay = State(initialValue: 2)
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

                // Reminder section - hidden for PRN medications
                if frequency != .asNeeded {
                    Section {
                        Toggle(reminderToggleLabel, isOn: $reminderEnabled)

                        if reminderEnabled {
                            reminderOptionsView
                        }
                    } header: {
                        Label("Reminder", systemImage: "bell.fill")
                    } footer: {
                        reminderFooterText
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

    // MARK: - Reminder UI Components

    private var reminderToggleLabel: String {
        switch frequency {
        case .weekly:
            return "Weekly Reminder"
        case .everyOtherDay:
            return "Every Other Day Reminder"
        default:
            return "Daily Reminder"
        }
    }

    @ViewBuilder
    private var reminderOptionsView: some View {
        switch frequency {
        case .onceDaily:
            // User picks time-of-day
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

        case .twiceDaily, .threeTimesDaily, .fourTimesDaily:
            // Auto-assigned times (read-only)
            HStack {
                Text("Times")
                Spacer()
                Text(autoAssignedTimesDescription)
                    .foregroundStyle(.secondary)
            }

        case .weekly:
            // Day of week picker
            Picker("Day", selection: $weeklyReminderDay) {
                Text("Sunday").tag(1)
                Text("Monday").tag(2)
                Text("Tuesday").tag(3)
                Text("Wednesday").tag(4)
                Text("Thursday").tag(5)
                Text("Friday").tag(6)
                Text("Saturday").tag(7)
            }

            // Time of day picker
            Picker("Time", selection: $timeOfDay) {
                ForEach(MedicationTimeOfDay.scheduledCases, id: \.self) { tod in
                    Label(tod.displayName, systemImage: tod.icon)
                        .tag(tod)
                }
                Label("Custom Time", systemImage: "clock.fill")
                    .tag(MedicationTimeOfDay.custom)
            }

            if timeOfDay == .custom {
                DatePicker("Custom Time", selection: $customReminderTime, displayedComponents: .hourAndMinute)
            }

        case .everyOtherDay:
            // Time of day picker
            Picker("Time", selection: $timeOfDay) {
                ForEach(MedicationTimeOfDay.scheduledCases, id: \.self) { tod in
                    Label(tod.displayName, systemImage: tod.icon)
                        .tag(tod)
                }
                Label("Custom Time", systemImage: "clock.fill")
                    .tag(MedicationTimeOfDay.custom)
            }

            if timeOfDay == .custom {
                DatePicker("Custom Time", selection: $customReminderTime, displayedComponents: .hourAndMinute)
            }

        case .asNeeded:
            EmptyView()
        }
    }

    private var autoAssignedTimesDescription: String {
        let slots = MedicationReminderService.getTimeSlotsForFrequency(frequency, userSelected: nil)
        return slots.map { $0.displayName }.joined(separator: ", ")
    }

    private var reminderFooterText: Text {
        if !reminderEnabled {
            return Text("Get notified when it's time to take this medication")
        }

        switch frequency {
        case .onceDaily:
            if timeOfDay == .custom {
                return Text("This medication will have its own reminder at the specified time")
            } else {
                return Text("You can change default \(timeOfDay.displayName.lowercased()) time in Settings")
            }

        case .twiceDaily, .threeTimesDaily, .fourTimesDaily:
            return Text("Reminders are automatically scheduled based on frequency. Change default times in Settings.")

        case .weekly:
            return Text("You'll be reminded once per week on the selected day")

        case .everyOtherDay:
            return Text("You'll be reminded every 48 hours starting from when this is set up")

        case .asNeeded:
            return Text("")
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
            medication.weeklyReminderDay = (frequency == .weekly) ? weeklyReminderDay : nil
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
                customReminderTime: (timeOfDay == .custom) ? customReminderTime : nil,
                weeklyReminderDay: (frequency == .weekly) ? weeklyReminderDay : 2
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

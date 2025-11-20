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
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add any instructions, side effects, or reminders")
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
        } else {
            let newMedication = UserMedication(
                name: name,
                dosage: dosage,
                category: category,
                frequency: frequency,
                notes: notes,
                startDate: startDate
            )
            modelContext.insert(newMedication)
        }

        dismiss()
    }
}

#Preview {
    AddUserMedicationView()
        .modelContainer(for: UserMedication.self)
}

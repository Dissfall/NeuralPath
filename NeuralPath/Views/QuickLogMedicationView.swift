//
//  QuickLogMedicationView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct QuickLogMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<UserMedication> { $0.isActive == true }, sort: \UserMedication.name) private var userMedications: [UserMedication]

    @State private var selectedMedications: Set<UUID> = []
    @State private var logTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time Taken", selection: $logTime, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("When")
                }

                Section {
                    if userMedications.isEmpty {
                        ContentUnavailableView(
                            "No Medications",
                            systemImage: "pills",
                            description: Text("Add medications in Settings to log them")
                        )
                    } else {
                        ForEach(userMedications) { medication in
                            Toggle(isOn: Binding(
                                get: {
                                    guard let medId = medication.id else { return false }
                                    return selectedMedications.contains(medId)
                                },
                                set: { newValue in
                                    guard let medId = medication.id else { return }
                                    if newValue {
                                        selectedMedications.insert(medId)
                                    } else {
                                        selectedMedications.remove(medId)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(medication.name ?? "")
                                        .font(.headline)

                                    if let dosage = medication.dosage, !dosage.isEmpty {
                                        Text(dosage)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Medications")
                } footer: {
                    if !selectedMedications.isEmpty {
                        Text("\(selectedMedications.count) medication(s) selected")
                    }
                }
            }
            .navigationTitle("Log Medications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        logMedications()
                    }
                    .disabled(selectedMedications.isEmpty)
                }
            }
        }
    }

    private func logMedications() {
        for medicationId in selectedMedications {
            guard let medication = userMedications.first(where: { $0.id == medicationId }) else { continue }

            let log = MedicationLog(
                userMedication: medication,
                medicationName: medication.name ?? "",
                timestamp: logTime
            )
            modelContext.insert(log)
        }

        dismiss()
    }
}

#Preview {
    QuickLogMedicationView()
        .modelContainer(for: UserMedication.self)
}

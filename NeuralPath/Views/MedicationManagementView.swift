//
//  MedicationManagementView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import HealthKit

struct MedicationManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserMedication> { $0.isActive == true }, sort: \UserMedication.name) private var medications: [UserMedication]

    @State private var showingAddMedication = false
    @State private var showingImportSheet = false
    @State private var healthKitMedications: [HKUserAnnotatedMedication] = []
    @State private var isImporting = false
    @State private var selectedMedication: UserMedication?

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        List {
            if medications.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Medications",
                        systemImage: "pills",
                        description: Text("Add medications to track your adherence and effectiveness")
                    )
                }

                if healthKitManager.isAuthorized {
                    Section {
                        Button {
                            showingImportSheet = true
                        } label: {
                            Label("Import from HealthKit", systemImage: "heart.text.square")
                        }
                    } footer: {
                        Text("Import medications from the Health app as a one-time setup")
                    }
                }
            } else {
                Section {
                    ForEach(medications) { medication in
                        NavigationLink {
                            AddUserMedicationView(medication: medication)
                        } label: {
                            MedicationRow(medication: medication)
                        }
                    }
                    .onDelete(perform: deleteMedications)
                } header: {
                    Text("Active Medications")
                } footer: {
                    if medications.count == 1 {
                        Text("1 active medication")
                    } else {
                        Text("\(medications.count) active medications")
                    }
                }
            }
        }
        .navigationTitle("Manage Medications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddMedication = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddUserMedicationView()
        }
        .sheet(isPresented: $showingImportSheet) {
            HealthKitImportView(onImport: importFromHealthKit)
        }
    }

    private func deleteMedications(at offsets: IndexSet) {
        for index in offsets {
            let medication = medications[index]
            medication.isActive = false
            medication.endDate = Date()
        }
    }

    private func importFromHealthKit(selectedMedications: [HKUserAnnotatedMedication]) {
        isImporting = true

        for hkMed in selectedMedications {
            let userMed = UserMedication(
                name: hkMed.medication.displayText,
                dosage: "",
                category: nil,
                frequency: .onceDaily,
                notes: "Imported from HealthKit"
            )
            modelContext.insert(userMed)
        }

        isImporting = false
        showingImportSheet = false
    }
}

struct MedicationRow: View {
    let medication: UserMedication

    private var reminderTimeString: String? {
        guard medication.reminderEnabled == true,
              let time = medication.reminderTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: medication.category?.icon ?? "pills.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name ?? "")
                    .font(.headline)

                HStack(spacing: 8) {
                    if let dosage = medication.dosage, !dosage.isEmpty {
                        Text(dosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let frequency = medication.frequency {
                        Text(frequency.shortName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let category = medication.category {
                        Text(category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }

                    if let timeStr = reminderTimeString {
                        HStack(spacing: 2) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                            Text(timeStr)
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct HealthKitImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var medications: [HKUserAnnotatedMedication] = []
    @State private var selectedMedications: Set<String> = []
    @State private var isLoading = true

    let onImport: ([HKUserAnnotatedMedication]) -> Void
    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading medications...")
                } else if medications.isEmpty {
                    ContentUnavailableView(
                        "No Medications Found",
                        systemImage: "pills",
                        description: Text("No medications found in the Health app")
                    )
                } else {
                    List {
                        ForEach(medications, id: \.medication.displayText) { medication in
                            let medName = medication.medication.displayText
                            HStack {
                                Image(systemName: selectedMedications.contains(medName) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedMedications.contains(medName) ? .blue : .secondary)

                                Text(medName)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedMedications.contains(medName) {
                                    selectedMedications.remove(medName)
                                } else {
                                    selectedMedications.insert(medName)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Import from HealthKit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        let selected = medications.filter { selectedMedications.contains($0.medication.displayText) }
                        onImport(selected)
                        dismiss()
                    }
                    .disabled(selectedMedications.isEmpty)
                }
            }
            .task {
                await loadMedications()
            }
        }
    }

    private func loadMedications() async {
        do {
            if #available(iOS 16.0, *) {
                medications = try await healthKitManager.fetchMedications()
                isLoading = false
            }
        } catch {
            print("Failed to load medications: \(error)")
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        MedicationManagementView()
            .modelContainer(for: UserMedication.self)
    }
}

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

    @State private var showingMedicationPicker = false
    @State private var showingImportSheet = false
    @State private var healthKitMedications: [HKUserAnnotatedMedication] = []
    @State private var isImporting = false
    @State private var selectedMedication: UserMedication?
    @State private var addMedicationState: AddMedicationState?

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
                    showingMedicationPicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingMedicationPicker) {
            MedicationPickerView(
                onSelect: { medication in
                    showingMedicationPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        addMedicationState = AddMedicationState(prefilled: medication)
                    }
                },
                onCustom: {
                    showingMedicationPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        addMedicationState = AddMedicationState(prefilled: nil)
                    }
                }
            )
        }
        .sheet(item: $addMedicationState) { state in
            AddUserMedicationView(prefilledMedication: state.prefilled)
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

    private var reminderBadges: [(icon: String, text: String, color: Color)] {
        guard medication.reminderEnabled == true else { return [] }

        let frequency = medication.frequency ?? .onceDaily

        // Custom time - single badge with specific time
        if medication.timeOfDay == .custom, let customTime = medication.customReminderTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return [("clock.fill", formatter.string(from: customTime), .blue)]
        }

        // Weekly - show day of week
        if frequency == .weekly {
            let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let day = medication.weeklyReminderDay ?? 2
            let timeOfDay = medication.timeOfDay ?? .morning
            return [(timeOfDay.icon, dayNames[day], timeOfDay.color)]
        }

        // Every other day - show QOD badge
        if frequency == .everyOtherDay {
            let timeOfDay = medication.timeOfDay ?? .morning
            return [(timeOfDay.icon, "QOD", timeOfDay.color)]
        }

        // Daily frequencies - show time slot badges based on frequency
        let timeSlots = MedicationReminderService.getTimeSlotsForFrequency(frequency, userSelected: medication.timeOfDay)
        return timeSlots.map { slot in
            (slot.icon, slot.displayName, slot.color)
        }
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
                }

                // Reminder badges on separate row if multiple
                if !reminderBadges.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(reminderBadges.indices, id: \.self) { index in
                            let badge = reminderBadges[index]
                            HStack(spacing: 2) {
                                Image(systemName: badge.icon)
                                    .font(.caption2)
                                Text(badge.text)
                                    .font(.caption)
                            }
                            .foregroundStyle(badge.color)
                        }
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

// MARK: - Add Medication State

struct AddMedicationState: Identifiable {
    let id = UUID()
    let prefilled: MedicationInfo?
}

#Preview {
    NavigationStack {
        MedicationManagementView()
            .modelContainer(for: UserMedication.self)
    }
}

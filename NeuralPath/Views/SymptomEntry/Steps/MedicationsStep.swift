import SwiftUI

struct MedicationsStep: View {
    @Bindable var viewModel: StepperEntryViewModel

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Medications Section
                medicationsSection

                // Substances Section
                substancesSection
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Medications Section

    @ViewBuilder
    private var medicationsSection: some View {
        StepSectionCard(
            title: "Medications",
            icon: "pills.fill",
            color: .blue
        ) {
            if viewModel.userMedications.isEmpty {
                emptyMedicationsView
            } else {
                VStack(spacing: 0) {
                    // Scheduled Medications
                    if !viewModel.scheduledMedications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scheduled")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 4)

                            ForEach(viewModel.scheduledMedications) { medication in
                                medicationRow(medication)
                                if medication.id != viewModel.scheduledMedications.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    // PRN Medications (taken ones)
                    let takenPrnMeds = viewModel.prnMedications.filter { med in
                        guard let medId = med.id else { return false }
                        return viewModel.takenMedications[medId] != nil
                    }

                    if !takenPrnMeds.isEmpty {
                        if !viewModel.scheduledMedications.isEmpty {
                            Divider()
                                .padding(.vertical, 8)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("As-Needed (PRN)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 4)

                            ForEach(takenPrnMeds) { medication in
                                prnRow(medication)
                                if medication.id != takenPrnMeds.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    // Add PRN Menu
                    if !viewModel.prnMedications.isEmpty {
                        Divider()
                            .padding(.top, 8)

                        Menu {
                            ForEach(viewModel.prnMedications) { medication in
                                Button {
                                    viewModel.toggleMedication(medication)
                                } label: {
                                    Label(
                                        medication.name ?? "Unknown",
                                        systemImage: viewModel.takenMedications[medication.id ?? UUID()] != nil
                                            ? "checkmark.circle.fill"
                                            : "circle"
                                    )
                                }
                            }
                        } label: {
                            Label("Take As-Needed", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        } footer: {
            Text("\(viewModel.medicationsSummary)")
        }
    }

    @ViewBuilder
    private func medicationRow(_ medication: UserMedication) -> some View {
        let medId = medication.id ?? UUID()
        let isTaken = viewModel.takenMedications[medId] != nil
        let time = viewModel.takenMedications[medId]

        HStack(spacing: 12) {
            Button {
                viewModel.toggleMedication(medication)
            } label: {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isTaken ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name ?? "Unknown")
                    .font(.subheadline)
                if let dosage = medication.dosage, !dosage.isEmpty {
                    Text(dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let time {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            if isTaken {
                Button {
                    viewModel.removeMedication(medication)
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .tint(.orange)

                Button {
                    viewModel.medicationToEditTime = medication
                    viewModel.editMedicationTime = time ?? Date()
                } label: {
                    Label("Edit Time", systemImage: "clock")
                }
                .tint(.blue)
            }
        }
    }

    @ViewBuilder
    private func prnRow(_ medication: UserMedication) -> some View {
        let medId = medication.id ?? UUID()
        let time = viewModel.takenMedications[medId]

        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            HStack(spacing: 6) {
                Text(medication.name ?? "Unknown")
                    .font(.subheadline)
                Text("PRN")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            Spacer()

            if let time {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeMedication(medication)
            } label: {
                Label("Remove", systemImage: "trash")
            }

            Button {
                viewModel.medicationToEditTime = medication
                viewModel.editMedicationTime = time ?? Date()
            } label: {
                Label("Edit Time", systemImage: "clock")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    private var emptyMedicationsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No medications in your library")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if healthKitManager.isAuthorized {
                Button {
                    viewModel.showingHealthKitImport = true
                } label: {
                    Label("Import from HealthKit", systemImage: "heart.text.square")
                }
            }

            NavigationLink {
                MedicationManagementView()
            } label: {
                Label("Add Medications in Settings", systemImage: "gear")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Substances Section

    @ViewBuilder
    private var substancesSection: some View {
        StepSectionCard(
            title: "Substances",
            icon: "cup.and.saucer.fill",
            color: .brown
        ) {
            if viewModel.userSubstances.isEmpty {
                emptySubstancesView
            } else {
                VStack(spacing: 0) {
                    // Logged substances
                    ForEach(viewModel.takenSubstances) { entry in
                        substanceRow(entry)
                        if entry.id != viewModel.takenSubstances.last?.id {
                            Divider()
                        }
                    }

                    // Add substance menu
                    if !viewModel.takenSubstances.isEmpty {
                        Divider()
                            .padding(.top, 8)
                    }

                    Menu {
                        ForEach(viewModel.userSubstances) { substance in
                            Button {
                                viewModel.substanceToAdd = substance
                                viewModel.newSubstanceAmount = "1"
                            } label: {
                                Text(substance.name ?? "Unknown")
                            }
                        }
                    } label: {
                        Label("Log Substance", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    .padding(.top, viewModel.takenSubstances.isEmpty ? 0 : 8)
                }
            }
        } footer: {
            Text("\(viewModel.substancesSummary)")
        }
    }

    @ViewBuilder
    private func substanceRow(_ entry: SubstanceEntry) -> some View {
        let substanceName = viewModel.userSubstances.first { $0.id == entry.userSubstanceId }?.name ?? "Unknown"
        let formattedAmount = formatAmount(entry.amount, unit: entry.unit)

        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            Text(substanceName)
                .font(.subheadline)

            Spacer()

            if !formattedAmount.isEmpty {
                Text(formattedAmount)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(timeFormatter.string(from: entry.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeSubstance(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                viewModel.substanceToEditTime = entry
                viewModel.editSubstanceTime = entry.timestamp
            } label: {
                Label("Edit Time", systemImage: "clock")
            }
            .tint(.blue)

            Button {
                viewModel.substanceToEditAmount = entry
                viewModel.editSubstanceAmount = entry.amount
            } label: {
                Label("Edit Amount", systemImage: "number")
            }
            .tint(.purple)
        }
    }

    @ViewBuilder
    private var emptySubstancesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No substances in your library")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NavigationLink {
                SubstanceManagementView()
            } label: {
                Label("Add Substances in Settings", systemImage: "gear")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    private func formatAmount(_ amount: String, unit: SubstanceUnit) -> String {
        guard let value = Double(amount), value > 0 else { return "" }
        let formattedAmount = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return "\(formattedAmount) \(unit.abbreviation)"
    }
}

#Preview {
    NavigationStack {
        MedicationsStep(viewModel: StepperEntryViewModel())
    }
}

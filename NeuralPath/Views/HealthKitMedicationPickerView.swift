import HealthKit
import SwiftUI

@available(iOS 16.0, *)
struct HealthKitMedicationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let healthKitMedications: [HKUserAnnotatedMedication]
    let onSelect: (HKUserAnnotatedMedication) -> Void

    var body: some View {
        NavigationStack {
            List {
                if healthKitMedications.isEmpty {
                    ContentUnavailableView(
                        "No Medications",
                        systemImage: "pills",
                        description: Text(
                            "Add medications in the Health app first"
                        )
                    )
                } else {
                    ForEach(
                        Array(healthKitMedications.enumerated()),
                        id: \.offset
                    ) { _, medication in
                        Button {
                            onSelect(medication)
                        } label: {
                            HStack {
                                Image(systemName: "pills.fill")
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    let nickname = medication.medication
                                        .displayText
                                    Text(nickname)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 8) {
                                        if medication.hasSchedule {
                                            Label(
                                                "Scheduled",
                                                systemImage: "clock"
                                            )
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        }

                                        if medication.isArchived {
                                            Text("Archived")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Import Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        HealthKitMedicationPickerView(
            healthKitMedications: [],
            onSelect: { _ in }
        )
    }
}

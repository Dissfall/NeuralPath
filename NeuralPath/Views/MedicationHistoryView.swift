import SwiftUI
import HealthKit

@available(iOS 16.0, *)
struct MedicationHistoryView: View {
    @State private var medications: [HKUserAnnotatedMedication] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var needsAuthorization = false

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            VStack {
                if !healthKitManager.isAuthorized {
                    ContentUnavailableView(
                        "HealthKit Not Connected",
                        systemImage: "heart.slash",
                        description: Text("Connect to HealthKit in Settings first")
                    )
                } else if needsAuthorization {
                    VStack(spacing: 20) {
                        Image(systemName: "pills.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("Medication Access Required")
                            .font(.title2)
                            .bold()

                        Text("To view your medications from the Health app, please grant access.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        Button {
                            Task {
                                await requestMedicationAccess()
                            }
                        } label: {
                            Label("Grant Access", systemImage: "lock.open")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                    .padding()
                } else {
                    if isLoading {
                        ProgressView("Loading medications...")
                            .padding()
                    } else if let error = errorMessage {
                        ContentUnavailableView(
                            "Unable to Load Data",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error)
                        )
                    } else if medications.isEmpty {
                        ContentUnavailableView(
                            "No Medications",
                            systemImage: "pills",
                            description: Text("Add medications in the Health app to see them here")
                        )
                    } else {
                        medicationListView
                    }
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                if !medications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                await loadMedications()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .task {
                needsAuthorization = true
            }
        }
    }

    private var medicationListView: some View {
        List {
            Section {
                Text("\(medications.count) medication(s) from Health app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(medications.enumerated()), id: \.offset) { _, medication in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            let nickname = medication.medication.displayText
                            
                            Text(nickname)
                                .font(.headline)

                            if medication.hasSchedule {
                                Label("Has schedule", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }

                        Spacer()

                        if medication.isArchived {
                            Text("Archived")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .foregroundStyle(.gray)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func requestMedicationAccess() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await healthKitManager.requestMedicationAuthorization()
            needsAuthorization = false
            await loadMedications()
        } catch {
            errorMessage = "Failed to request authorization: \(error.localizedDescription)"
        }
    }

    private func loadMedications() async {
        guard healthKitManager.isAuthorized, !needsAuthorization else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            medications = try await healthKitManager.fetchMedications()
        } catch {
            errorMessage = "Failed to load medications: \(error.localizedDescription)"
        }
    }
}


#Preview {
    if #available(iOS 16.0, *) {
        MedicationHistoryView()
    }
}

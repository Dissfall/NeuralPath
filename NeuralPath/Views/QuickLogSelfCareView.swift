//
//  QuickLogSelfCareView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct QuickLogSelfCareView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<UserSelfCare> { $0.isActive == true }, sort: \UserSelfCare.name) private var practices: [UserSelfCare]

    @State private var selectedPractices: Set<UUID> = []
    @State private var logTime: Date = Date()

    private var morningPractices: [UserSelfCare] {
        practices.filter { $0.timeOfDay == .morning }
    }

    private var afternoonPractices: [UserSelfCare] {
        practices.filter { $0.timeOfDay == .afternoon }
    }

    private var eveningPractices: [UserSelfCare] {
        practices.filter { $0.timeOfDay == .evening }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time Completed", selection: $logTime, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("When")
                }

                if practices.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Self-Care Practices",
                            systemImage: "sparkles",
                            description: Text("Add self-care practices in Settings")
                        )
                    }
                } else {
                    // Morning practices
                    if !morningPractices.isEmpty {
                        Section {
                            ForEach(morningPractices) { practice in
                                practiceToggle(practice)
                            }
                        } header: {
                            Label("Morning", systemImage: SelfCareTimeOfDay.morning.icon)
                        }
                    }

                    // Afternoon practices
                    if !afternoonPractices.isEmpty {
                        Section {
                            ForEach(afternoonPractices) { practice in
                                practiceToggle(practice)
                            }
                        } header: {
                            Label("Afternoon", systemImage: SelfCareTimeOfDay.afternoon.icon)
                        }
                    }

                    // Evening practices
                    if !eveningPractices.isEmpty {
                        Section {
                            ForEach(eveningPractices) { practice in
                                practiceToggle(practice)
                            }
                        } header: {
                            Label("Evening", systemImage: SelfCareTimeOfDay.evening.icon)
                        }
                    }
                }

                if !selectedPractices.isEmpty {
                    Section {
                        Text("\(selectedPractices.count) practice(s) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Log Self-Care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        logPractices()
                    }
                    .disabled(selectedPractices.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func practiceToggle(_ practice: UserSelfCare) -> some View {
        Toggle(isOn: Binding(
            get: {
                guard let practiceId = practice.id else { return false }
                return selectedPractices.contains(practiceId)
            },
            set: { newValue in
                guard let practiceId = practice.id else { return }
                if newValue {
                    selectedPractices.insert(practiceId)
                } else {
                    selectedPractices.remove(practiceId)
                }
            }
        )) {
            HStack(spacing: 12) {
                Image(systemName: practice.timeOfDay.icon)
                    .foregroundStyle(practice.timeOfDay.color)

                Text(practice.name ?? "")
                    .font(.headline)
            }
        }
    }

    private func logPractices() {
        for practiceId in selectedPractices {
            guard let practice = practices.first(where: { $0.id == practiceId }) else { continue }

            let log = SelfCareLog(
                userSelfCare: practice,
                practiceName: practice.name ?? "",
                timeOfDay: practice.timeOfDay,
                timestamp: logTime
            )
            modelContext.insert(log)
        }

        dismiss()
    }
}

#Preview {
    QuickLogSelfCareView()
        .modelContainer(for: UserSelfCare.self)
}

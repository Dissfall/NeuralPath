//
//  QuickLogMindfulnessView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct QuickLogMindfulnessView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<UserMindfulness> { $0.isActive == true }, sort: \UserMindfulness.name) private var practices: [UserMindfulness]

    @State private var selectedPractices: Set<UUID> = []
    @State private var logTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time Completed", selection: $logTime, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("When")
                }

                Section {
                    if practices.isEmpty {
                        ContentUnavailableView(
                            "No Practices",
                            systemImage: "brain.head.profile",
                            description: Text("Add mindfulness practices in Settings")
                        )
                    } else {
                        ForEach(practices) { practice in
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
                                    Image(systemName: practice.category?.icon ?? "brain.head.profile")
                                        .foregroundStyle(.purple)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(practice.name ?? "")
                                            .font(.headline)

                                        if let duration = practice.durationMinutes, duration > 0 {
                                            Text("\(duration) min")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Practices")
                } footer: {
                    if !selectedPractices.isEmpty {
                        Text("\(selectedPractices.count) practice(s) selected")
                    }
                }
            }
            .navigationTitle("Log Mindfulness")
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

    private func logPractices() {
        for practiceId in selectedPractices {
            guard let practice = practices.first(where: { $0.id == practiceId }) else { continue }

            let log = MindfulnessLog(
                userMindfulness: practice,
                practiceName: practice.name ?? "",
                timestamp: logTime
            )
            modelContext.insert(log)
        }

        dismiss()
    }
}

#Preview {
    QuickLogMindfulnessView()
        .modelContainer(for: UserMindfulness.self)
}

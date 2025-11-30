//
//  AddUserSelfCareView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct AddUserSelfCareView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var timeOfDay: SelfCareTimeOfDay
    @State private var notes: String

    private let practice: UserSelfCare?
    private var isEditing: Bool { practice != nil }

    init(practice: UserSelfCare? = nil, prefilledTimeOfDay: SelfCareTimeOfDay? = nil, prefilledName: String? = nil) {
        self.practice = practice

        if let existingPractice = practice {
            _name = State(initialValue: existingPractice.name ?? "")
            _timeOfDay = State(initialValue: existingPractice.timeOfDay)
            _notes = State(initialValue: existingPractice.notes ?? "")
        } else {
            _name = State(initialValue: prefilledName ?? "")
            _timeOfDay = State(initialValue: prefilledTimeOfDay ?? .morning)
            _notes = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Practice Name", text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Basic Information")
                } footer: {
                    Text("e.g., Brush Teeth, Shower, Take Vitamins")
                }

                Section {
                    Picker("Time of Day", selection: $timeOfDay) {
                        ForEach(SelfCareTimeOfDay.allCases) { tod in
                            Label(tod.displayName, systemImage: tod.icon)
                                .tag(tod)
                        }
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("When during the day do you typically do this practice?")
                }

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add any instructions or notes about this practice")
                }
            }
            .navigationTitle(isEditing ? "Edit Practice" : "Add Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        savePractice()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func savePractice() {
        if let practice = practice {
            practice.name = name
            practice.timeOfDay = timeOfDay
            practice.notes = notes
        } else {
            let newPractice = UserSelfCare(
                name: name,
                timeOfDay: timeOfDay,
                notes: notes
            )
            modelContext.insert(newPractice)
        }

        dismiss()
    }
}

#Preview {
    AddUserSelfCareView()
        .modelContainer(for: UserSelfCare.self)
}

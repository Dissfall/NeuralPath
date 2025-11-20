//
//  AddUserSubstanceView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct AddUserSubstanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var defaultUnit: SubstanceUnit?
    @State private var notes: String

    private let substance: UserSubstance?
    private var isEditing: Bool { substance != nil }

    init(substance: UserSubstance? = nil) {
        self.substance = substance
        _name = State(initialValue: substance?.name ?? "")
        _defaultUnit = State(initialValue: substance?.defaultUnit)
        _notes = State(initialValue: substance?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Substance Name (e.g., Coffee, Alcohol)", text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                }

                Section {
                    Picker("Default Unit", selection: $defaultUnit) {
                        Text("None").tag(nil as SubstanceUnit?)
                        ForEach(SubstanceUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit as SubstanceUnit?)
                        }
                    }
                } header: {
                    Text("Measurement")
                } footer: {
                    Text("Optional default unit for quick entry")
                }

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add any relevant information or reminders")
                }
            }
            .navigationTitle(isEditing ? "Edit Substance" : "Add Substance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveSubstance()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveSubstance() {
        if let substance = substance {
            substance.name = name
            substance.defaultUnit = defaultUnit
            substance.notes = notes
        } else {
            let newSubstance = UserSubstance(
                name: name,
                defaultUnit: defaultUnit,
                notes: notes
            )
            modelContext.insert(newSubstance)
        }

        dismiss()
    }
}

#Preview {
    AddUserSubstanceView()
        .modelContainer(for: UserSubstance.self)
}

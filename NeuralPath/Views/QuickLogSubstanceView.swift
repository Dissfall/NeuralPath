//
//  QuickLogSubstanceView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct QuickLogSubstanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<UserSubstance> { $0.isActive }, sort: \UserSubstance.name) private var userSubstances: [UserSubstance]

    @State private var selectedSubstances: [UUID: SubstanceAmount] = [:]
    @State private var logTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time Consumed", selection: $logTime, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("When")
                }

                Section {
                    if userSubstances.isEmpty {
                        ContentUnavailableView(
                            "No Substances",
                            systemImage: "drop.triangle",
                            description: Text("Add substances in Settings to log them")
                        )
                    } else {
                        ForEach(userSubstances) { substance in
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: Binding(
                                    get: { selectedSubstances[substance.id] != nil },
                                    set: { newValue in
                                        if newValue {
                                            selectedSubstances[substance.id] = SubstanceAmount(
                                                amount: "",
                                                unit: substance.defaultUnit ?? .cups,
                                                timestamp: Date()
                                            )
                                        } else {
                                            selectedSubstances[substance.id] = nil
                                        }
                                    }
                                )) {
                                    Text(substance.name)
                                        .font(.headline)
                                }

                                if selectedSubstances[substance.id] != nil {
                                    HStack {
                                        TextField(
                                            "Amount",
                                            text: Binding(
                                                get: { selectedSubstances[substance.id]?.amount ?? "" },
                                                set: { newValue in
                                                    if var amount = selectedSubstances[substance.id] {
                                                        amount.amount = newValue
                                                        selectedSubstances[substance.id] = amount
                                                    }
                                                }
                                            )
                                        )
                                        .keyboardType(.decimalPad)
                                        .frame(maxWidth: 100)

                                        Picker(
                                            "Unit",
                                            selection: Binding(
                                                get: { selectedSubstances[substance.id]?.unit ?? .cups },
                                                set: { newValue in
                                                    if var amount = selectedSubstances[substance.id] {
                                                        amount.unit = newValue
                                                        selectedSubstances[substance.id] = amount
                                                    }
                                                }
                                            )
                                        ) {
                                            ForEach(SubstanceUnit.allCases, id: \.self) { unit in
                                                Text(unit.displayName).tag(unit)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    .padding(.leading)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Select Substances")
                } footer: {
                    if !selectedSubstances.isEmpty {
                        Text("\(selectedSubstances.count) substance(s) selected")
                    }
                }
            }
            .navigationTitle("Log Substances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        logSubstances()
                    }
                    .disabled(selectedSubstances.isEmpty)
                }
            }
        }
    }

    private func logSubstances() {
        for (substanceId, substanceAmount) in selectedSubstances {
            guard let substance = userSubstances.first(where: { $0.id == substanceId }),
                  let amount = Double(substanceAmount.amount), amount > 0 else { continue }

            let log = SubstanceLog(
                userSubstance: substance,
                substanceName: substance.name,
                amount: amount,
                unit: substanceAmount.unit,
                timestamp: logTime
            )
            modelContext.insert(log)
        }

        dismiss()
    }
}

#Preview {
    QuickLogSubstanceView()
        .modelContainer(for: UserSubstance.self)
}

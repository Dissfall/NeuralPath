//
//  AddUserMindfulnessView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct AddUserMindfulnessView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: MindfulnessCategory?
    @State private var durationMinutes: Int
    @State private var notes: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date

    private let practice: UserMindfulness?
    private var isEditing: Bool { practice != nil }

    init(practice: UserMindfulness? = nil, prefilledCategory: MindfulnessCategory? = nil, prefilledName: String? = nil) {
        self.practice = practice

        if let existingPractice = practice {
            _name = State(initialValue: existingPractice.name ?? "")
            _category = State(initialValue: existingPractice.category)
            _durationMinutes = State(initialValue: existingPractice.durationMinutes ?? 10)
            _notes = State(initialValue: existingPractice.notes ?? "")
            _reminderEnabled = State(initialValue: existingPractice.reminderEnabled ?? false)

            if let existingTime = existingPractice.reminderTime {
                _reminderTime = State(initialValue: existingTime)
            } else {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = 8
                components.minute = 0
                _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
            }
        } else {
            _name = State(initialValue: prefilledName ?? "")
            _category = State(initialValue: prefilledCategory)
            _durationMinutes = State(initialValue: 10)
            _notes = State(initialValue: "")
            _reminderEnabled = State(initialValue: false)

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
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
                }

                Section {
                    Picker("Category", selection: $category) {
                        Text("None").tag(nil as MindfulnessCategory?)
                        ForEach(MindfulnessCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat as MindfulnessCategory?)
                        }
                    }

                    Stepper(value: $durationMinutes, in: 1...120, step: 5) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(durationMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Details")
                }

                Section {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Label("Reminder", systemImage: "bell.fill")
                } footer: {
                    Text("Get a daily notification to practice mindfulness at your chosen time")
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
            practice.category = category
            practice.durationMinutes = durationMinutes
            practice.notes = notes
            practice.reminderEnabled = reminderEnabled
            practice.reminderTime = reminderTime
        } else {
            let newPractice = UserMindfulness(
                name: name,
                category: category,
                durationMinutes: durationMinutes,
                notes: notes,
                reminderTime: reminderEnabled ? reminderTime : nil,
                reminderEnabled: reminderEnabled
            )
            modelContext.insert(newPractice)
        }

        MindfulnessReminderService.shared.scheduleMindfulnessRemindersFromContext()

        dismiss()
    }
}

#Preview {
    AddUserMindfulnessView()
        .modelContainer(for: UserMindfulness.self)
}

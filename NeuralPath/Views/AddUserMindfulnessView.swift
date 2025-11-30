//
//  AddUserMindfulnessView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

// MARK: - Suggested Mindfulness Practices

enum MindfulnessSuggestions {
    struct SuggestedPractice: Identifiable {
        let id = UUID()
        let name: String
        let category: MindfulnessCategory
        let defaultDuration: Int
    }

    static let practices: [SuggestedPractice] = [
        // Meditation
        SuggestedPractice(name: "Morning Meditation", category: .meditation, defaultDuration: 10),
        SuggestedPractice(name: "Guided Meditation", category: .meditation, defaultDuration: 15),
        SuggestedPractice(name: "Loving-Kindness Meditation", category: .meditation, defaultDuration: 10),
        SuggestedPractice(name: "Mindfulness Meditation", category: .meditation, defaultDuration: 10),
        SuggestedPractice(name: "Sleep Meditation", category: .meditation, defaultDuration: 20),

        // Breathing
        SuggestedPractice(name: "Deep Breathing", category: .breathing, defaultDuration: 5),
        SuggestedPractice(name: "Box Breathing", category: .breathing, defaultDuration: 5),
        SuggestedPractice(name: "4-7-8 Breathing", category: .breathing, defaultDuration: 5),
        SuggestedPractice(name: "Belly Breathing", category: .breathing, defaultDuration: 5),

        // Yoga
        SuggestedPractice(name: "Morning Yoga", category: .yoga, defaultDuration: 20),
        SuggestedPractice(name: "Gentle Yoga", category: .yoga, defaultDuration: 15),
        SuggestedPractice(name: "Yoga Stretches", category: .yoga, defaultDuration: 10),
        SuggestedPractice(name: "Evening Yoga", category: .yoga, defaultDuration: 15),

        // Journaling
        SuggestedPractice(name: "Morning Pages", category: .journaling, defaultDuration: 15),
        SuggestedPractice(name: "Gratitude Journal", category: .journaling, defaultDuration: 5),
        SuggestedPractice(name: "Reflection Journal", category: .journaling, defaultDuration: 10),
        SuggestedPractice(name: "Mood Journal", category: .journaling, defaultDuration: 5),

        // Body Scan
        SuggestedPractice(name: "Full Body Scan", category: .bodyScan, defaultDuration: 15),
        SuggestedPractice(name: "Quick Body Check-In", category: .bodyScan, defaultDuration: 5),

        // Relaxation
        SuggestedPractice(name: "Progressive Muscle Relaxation", category: .relaxation, defaultDuration: 15),
        SuggestedPractice(name: "Visualization", category: .relaxation, defaultDuration: 10),
        SuggestedPractice(name: "Nature Sounds", category: .relaxation, defaultDuration: 15),

        // Walking
        SuggestedPractice(name: "Mindful Walking", category: .walking, defaultDuration: 15),
        SuggestedPractice(name: "Nature Walk", category: .walking, defaultDuration: 30),
        SuggestedPractice(name: "Walking Meditation", category: .walking, defaultDuration: 10),

        // Gratitude
        SuggestedPractice(name: "Gratitude Practice", category: .gratitude, defaultDuration: 5),
        SuggestedPractice(name: "Three Good Things", category: .gratitude, defaultDuration: 5),
        SuggestedPractice(name: "Appreciation Moment", category: .gratitude, defaultDuration: 3)
    ]

    static func practices(for category: MindfulnessCategory?) -> [SuggestedPractice] {
        guard let category = category else { return practices }
        return practices.filter { $0.category == category }
    }
}

struct AddUserMindfulnessView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<UserMindfulness> { $0.isActive == true }) private var existingPractices: [UserMindfulness]

    @State private var name: String
    @State private var category: MindfulnessCategory?
    @State private var durationMinutes: Int
    @State private var notes: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var showSuggestions: Bool = true

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
            _showSuggestions = State(initialValue: false)

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
            _showSuggestions = State(initialValue: prefilledName == nil)

            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
        }
    }

    private var filteredSuggestions: [MindfulnessSuggestions.SuggestedPractice] {
        let existingNames = Set(existingPractices.compactMap { $0.name?.lowercased() })
        return MindfulnessSuggestions.practices(for: category)
            .filter { !existingNames.contains($0.name.lowercased()) }
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

                // Suggestions section (only when adding new practice)
                if !isEditing && showSuggestions && !filteredSuggestions.isEmpty {
                    Section {
                        ForEach(filteredSuggestions.prefix(8)) { suggestion in
                            Button {
                                name = suggestion.name
                                category = suggestion.category
                                durationMinutes = suggestion.defaultDuration
                                showSuggestions = false
                            } label: {
                                HStack {
                                    Image(systemName: suggestion.category.icon)
                                        .foregroundStyle(suggestion.category.color)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.name)
                                            .foregroundStyle(.primary)
                                        Text("\(suggestion.category.displayName) • \(suggestion.defaultDuration) min")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Suggestions")
                            Spacer()
                            Button("Hide") {
                                showSuggestions = false
                            }
                            .font(.caption)
                        }
                    } footer: {
                        Text("Tap to add a suggested practice")
                    }
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

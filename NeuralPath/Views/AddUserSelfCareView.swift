//
//  AddUserSelfCareView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

// MARK: - Suggested Self-Care Practices

enum SelfCareSuggestions {
    struct SuggestedPractice: Identifiable {
        let id = UUID()
        let name: String
        let timeOfDay: SelfCareTimeOfDay
    }

    static let practices: [SuggestedPractice] = [
        // Morning
        SuggestedPractice(name: "Brush Teeth", timeOfDay: .morning),
        SuggestedPractice(name: "Shower", timeOfDay: .morning),
        SuggestedPractice(name: "Skincare Routine", timeOfDay: .morning),
        SuggestedPractice(name: "Breakfast", timeOfDay: .morning),
        SuggestedPractice(name: "Make Bed", timeOfDay: .morning),
        SuggestedPractice(name: "Get Dressed", timeOfDay: .morning),
        SuggestedPractice(name: "Morning Stretch", timeOfDay: .morning),
        SuggestedPractice(name: "Take Morning Meds", timeOfDay: .morning),

        // Afternoon
        SuggestedPractice(name: "Hydrate", timeOfDay: .afternoon),
        SuggestedPractice(name: "Take Vitamins", timeOfDay: .afternoon),
        SuggestedPractice(name: "Stretch Break", timeOfDay: .afternoon),
        SuggestedPractice(name: "Healthy Snack", timeOfDay: .afternoon),
        SuggestedPractice(name: "Lunch", timeOfDay: .afternoon),
        SuggestedPractice(name: "Walk Outside", timeOfDay: .afternoon),
        SuggestedPractice(name: "Take Afternoon Meds", timeOfDay: .afternoon),

        // Evening
        SuggestedPractice(name: "Dinner", timeOfDay: .evening),
        SuggestedPractice(name: "Evening Skincare", timeOfDay: .evening),
        SuggestedPractice(name: "Brush Teeth (Evening)", timeOfDay: .evening),
        SuggestedPractice(name: "Sleep Preparation", timeOfDay: .evening),
        SuggestedPractice(name: "Floss", timeOfDay: .evening),
        SuggestedPractice(name: "Tidy Up", timeOfDay: .evening),
        SuggestedPractice(name: "Prepare Clothes", timeOfDay: .evening),
        SuggestedPractice(name: "Take Evening Meds", timeOfDay: .evening),
        SuggestedPractice(name: "Wind Down", timeOfDay: .evening)
    ]

    static func practices(for timeOfDay: SelfCareTimeOfDay) -> [SuggestedPractice] {
        practices.filter { $0.timeOfDay == timeOfDay }
    }
}

struct AddUserSelfCareView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<UserSelfCare> { $0.isActive == true }) private var existingPractices: [UserSelfCare]

    @State private var name: String
    @State private var timeOfDay: SelfCareTimeOfDay
    @State private var notes: String
    @State private var showSuggestions: Bool = true

    private let practice: UserSelfCare?
    private var isEditing: Bool { practice != nil }

    init(practice: UserSelfCare? = nil, prefilledTimeOfDay: SelfCareTimeOfDay? = nil, prefilledName: String? = nil) {
        self.practice = practice

        if let existingPractice = practice {
            _name = State(initialValue: existingPractice.name ?? "")
            _timeOfDay = State(initialValue: existingPractice.timeOfDay)
            _notes = State(initialValue: existingPractice.notes ?? "")
            _showSuggestions = State(initialValue: false)
        } else {
            _name = State(initialValue: prefilledName ?? "")
            _timeOfDay = State(initialValue: prefilledTimeOfDay ?? .morning)
            _notes = State(initialValue: "")
            _showSuggestions = State(initialValue: prefilledName == nil)
        }
    }

    private var filteredSuggestions: [SelfCareSuggestions.SuggestedPractice] {
        let existingNames = Set(existingPractices.compactMap { $0.name?.lowercased() })
        return SelfCareSuggestions.practices(for: timeOfDay)
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
                } footer: {
                    Text("e.g., Brush Teeth, Shower, Take Vitamins")
                }

                // Suggestions section (only when adding new practice)
                if !isEditing && showSuggestions && !filteredSuggestions.isEmpty {
                    Section {
                        ForEach(filteredSuggestions) { suggestion in
                            Button {
                                name = suggestion.name
                                showSuggestions = false
                            } label: {
                                HStack {
                                    Image(systemName: timeOfDay.icon)
                                        .foregroundStyle(timeOfDay.color)
                                        .frame(width: 24)
                                    Text(suggestion.name)
                                        .foregroundStyle(.primary)
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

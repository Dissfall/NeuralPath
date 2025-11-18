import HealthKit
import SwiftData
import SwiftUI

struct AddSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var moodLevel: MoodLevel?
    @State private var anxietyLevel: AnxietyLevel?
    @State private var anhedoniaLevel: AnhedoniaLevel?
    @State private var sleepQualityRating: Int?
    @State private var sleepHours: String = ""
    @State private var notes: String = ""
    @State private var medications: [MedicationInput] = []
    @State private var isLoadingSleepData = false
    @State private var healthKitMedications: [HKUserAnnotatedMedication] = []
    @State private var showingHealthKitMedications = false

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("Entry Date", selection: $selectedDate)
                }

                Section("Mood") {
                    Picker("Mood Level", selection: $moodLevel) {
                        Text("Not Set").tag(nil as MoodLevel?)
                        ForEach(MoodLevel.allCases, id: \.self) { level in
                            Text("\(level.emoji) \(level.displayName)").tag(
                                level as MoodLevel?
                            )
                        }
                    }
                }

                Section("Anxiety") {
                    Picker("Anxiety Level", selection: $anxietyLevel) {
                        Text("Not Set").tag(nil as AnxietyLevel?)
                        ForEach(AnxietyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as AnxietyLevel?)
                        }
                    }
                }

                Section("Anhedonia") {
                    Picker("Anhedonia Level", selection: $anhedoniaLevel) {
                        Text("Not Set").tag(nil as AnhedoniaLevel?)
                        ForEach(AnhedoniaLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(
                                level as AnhedoniaLevel?
                            )
                        }
                    }

                    if let anhedonia = anhedoniaLevel {
                        Text(anhedonia.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack {
                        TextField("Hours", text: $sleepHours)
                            .keyboardType(.decimalPad)
                    }

                    if let rating = sleepQualityRating {
                        HStack {
                            Text("Quality")
                            Spacer()
                            ForEach(1...5, id: \.self) { star in
                                Image(
                                    systemName: star <= rating
                                        ? "star.fill" : "star"
                                )
                                .foregroundStyle(
                                    star <= rating ? .yellow : .gray
                                )
                                .onTapGesture {
                                    sleepQualityRating = star
                                }
                            }
                        }
                    } else {
                        Button("Add Quality Rating") {
                            sleepQualityRating = 3
                        }
                    }
                } header: {
                    Text("Sleep")
                }

                Section("Medications") {
                    if healthKitManager.isAuthorized
                        && !healthKitMedications.isEmpty
                    {
                        Button {
                            showingHealthKitMedications = true
                        } label: {
                            Label(
                                "Import from Health App",
                                systemImage: "arrow.down.circle"
                            )
                        }
                    }

                    ForEach(medications) { med in
                        HStack {
                            TextField(
                                "Medication Name",
                                text: Binding(
                                    get: { med.name },
                                    set: { newValue in
                                        if let index = medications.firstIndex(
                                            where: { $0.id == med.id })
                                        {
                                            medications[index].name = newValue
                                        }
                                    }
                                )
                            )
                            .font(.headline)
                            Spacer()
                            Toggle(
                                "Taken",
                                isOn: Binding(
                                    get: { med.taken },
                                    set: { newValue in
                                        if let index = medications.firstIndex(
                                            where: { $0.id == med.id })
                                        {
                                            medications[index].taken = newValue
                                        }
                                    }
                                )
                            )
                        }
                    }
                    .onDelete { indexSet in
                        medications.remove(atOffsets: indexSet)
                    }

                    Button {
                        medications.append(MedicationInput())
                    } label: {
                        Label("Add Medication", systemImage: "plus.circle.fill")
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                }
            }
            .sheet(isPresented: $showingHealthKitMedications) {
                HealthKitMedicationPickerView(
                    healthKitMedications: healthKitMedications,
                    onSelect: { medication in
                        importHealthKitMedication(medication)
                    }
                )
            }
            .task {
                await loadHealthKitMedications()
                await loadSleepData()
            }
        }
    }

    private func loadSleepData() async {
        isLoadingSleepData = true
        defer { isLoadingSleepData = false }

        do {
            if let sleepData = try await healthKitManager.fetchSleepData(
                for: selectedDate
            ) {
                sleepHours = String(format: "%.1f", sleepData.hours)
                sleepQualityRating = sleepData.quality
            }
        } catch {
            print("Error loading sleep data: \(error)")
        }
    }

    private func loadHealthKitMedications() async {
        do {
            healthKitMedications = try await healthKitManager.fetchMedications()

            medications = healthKitMedications.map { medication in
                MedicationInput.init(
                    name: medication.medication.displayText,
                    dosage: "",
                    taken: false
                )
            }
        } catch {
            print("Failed to load HealthKit medications: \(error)")
        }
    }

    private func importHealthKitMedication(
        _ medication: HKUserAnnotatedMedication
    ) {
        let medicationName = medication.medication.displayText

        let medInput = MedicationInput(
            name: medicationName,
            dosage: "",
            taken: false
        )
        medications.append(medInput)
        showingHealthKitMedications = false
    }

    private func saveEntry() {
        let entry = SymptomEntry(
            timestamp: selectedDate,
            moodLevel: moodLevel,
            anxietyLevel: anxietyLevel,
            anhedoniaLevel: anhedoniaLevel,
            sleepQualityRating: sleepQualityRating,
            sleepHours: Double(sleepHours),
            notes: notes
        )

        let meds = medications.map { input in
            Medication(
                name: input.name,
                dosage: input.dosage,
                timestamp: selectedDate,
                taken: input.taken,
                notes: input.notes
            )
        }

        entry.medications = meds
        meds.forEach { $0.symptomEntry = entry }

        modelContext.insert(entry)

        if healthKitManager.isAuthorized, let mood = moodLevel {
            Task {
                if #available(iOS 18.0, *) {
                    try? await healthKitManager.saveStateOfMind(
                        valence: mood.stateOfMindValence,
                        kind: .dailyMood,
                        labels: mood.stateOfMindLabels,
                        date: selectedDate
                    )
                }
            }
        }

        dismiss()
    }
}

struct MedicationInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var dosage: String = ""
    var taken: Bool = false
    var notes: String = ""
}

#Preview {
    AddSymptomView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

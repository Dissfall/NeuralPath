import HealthKit
import SwiftData
import SwiftUI

struct AddSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allEntries: [SymptomEntry]
    @Query(filter: #Predicate<UserMedication> { $0.isActive }, sort: \UserMedication.name) private var userMedications: [UserMedication]

    let entryToEdit: SymptomEntry?

    @State private var selectedDate: Date
    @State private var showingDuplicateAlert = false
    @State private var moodLevel: MoodLevel?
    @State private var anxietyLevel: AnxietyLevel?
    @State private var anhedoniaLevel: AnhedoniaLevel?
    @State private var sleepQualityRating: Int?
    @State private var sleepHours: String = ""
    @State private var timeInDaylightMinutes: String = ""
    @State private var exerciseMinutes: String = ""
    @State private var notes: String = ""
    @State private var takenMedications: Set<UUID> = []
    @State private var substances: [SubstanceInput] = []
    @State private var isLoadingSleepData = false
    @State private var showingHealthKitImport = false

    private let healthKitManager = HealthKitManager.shared

    init(entryToEdit: SymptomEntry? = nil) {
        self.entryToEdit = entryToEdit
        _selectedDate = State(initialValue: entryToEdit?.timestamp ?? Date())
    }

    private var isEditMode: Bool {
        entryToEdit != nil
    }

    private var hasEntryForSelectedDate: Bool {
        allEntries.contains { entry in
            entry.id != entryToEdit?.id &&
            Calendar.current.isDate(entry.timestamp, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Entry Date", selection: $selectedDate, in: ...Date(), displayedComponents: [.date])

                    if hasEntryForSelectedDate {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Entry already exists for this date")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
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

                Section("Activity") {
                    HStack {
                        Text("Daylight")
                        Spacer()
                        TextField("Minutes", text: $timeInDaylightMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Exercise")
                        Spacer()
                        TextField("Minutes", text: $exerciseMinutes)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Medications") {
                    if userMedications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No medications in your library")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if healthKitManager.isAuthorized {
                                Button {
                                    showingHealthKitImport = true
                                } label: {
                                    Label("Import from HealthKit", systemImage: "heart.text.square")
                                }
                            }

                            NavigationLink {
                                MedicationManagementView()
                            } label: {
                                Label("Add Medications in Settings", systemImage: "gear")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(userMedications) { medication in
                            Toggle(isOn: Binding(
                                get: { takenMedications.contains(medication.id) },
                                set: { newValue in
                                    if newValue {
                                        takenMedications.insert(medication.id)
                                    } else {
                                        takenMedications.remove(medication.id)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(medication.name)
                                        .font(.headline)

                                    HStack(spacing: 8) {
                                        if !medication.dosage.isEmpty {
                                            Text(medication.dosage)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Text(medication.frequency.shortName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Substances") {
                    ForEach(substances) { substance in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(
                                "Substance Name",
                                text: Binding(
                                    get: { substance.name },
                                    set: { newValue in
                                        if let index = substances.firstIndex(
                                            where: { $0.id == substance.id })
                                        {
                                            substances[index].name = newValue
                                        }
                                    }
                                )
                            )
                            .font(.headline)

                            HStack {
                                TextField(
                                    "Amount",
                                    text: Binding(
                                        get: { substance.amount },
                                        set: { newValue in
                                            if let index = substances.firstIndex(
                                                where: { $0.id == substance.id })
                                            {
                                                substances[index].amount = newValue
                                            }
                                        }
                                    )
                                )
                                .keyboardType(.decimalPad)
                                .frame(maxWidth: 100)

                                Picker(
                                    "Unit",
                                    selection: Binding(
                                        get: { substance.unit },
                                        set: { newValue in
                                            if let index = substances.firstIndex(
                                                where: { $0.id == substance.id })
                                            {
                                                substances[index].unit = newValue
                                            }
                                        }
                                    )
                                ) {
                                    ForEach(SubstanceUnit.allCases, id: \.self) {
                                        unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            TextField(
                                "Notes (optional)",
                                text: Binding(
                                    get: { substance.notes },
                                    set: { newValue in
                                        if let index = substances.firstIndex(
                                            where: { $0.id == substance.id })
                                        {
                                            substances[index].notes = newValue
                                        }
                                    }
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        substances.remove(atOffsets: indexSet)
                    }

                    Button {
                        substances.append(SubstanceInput())
                    } label: {
                        Label("Add Substance", systemImage: "plus.circle.fill")
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditMode ? "Edit Entry" : "New Entry")
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
            .task {
                if let entry = entryToEdit {
                    loadEntryData(entry)
                } else {
                    await loadSleepData()
                    await loadActivityData()
                }
            }
            .sheet(isPresented: $showingHealthKitImport) {
                HealthKitImportView(onImport: importMedicationsFromHealthKit)
            }
            .onChange(of: selectedDate) { _, _ in
                if !isEditMode {
                    Task {
                        await loadSleepData()
                        await loadActivityData()
                    }
                }
            }
            .alert("Entry Already Exists", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("An entry for this date already exists. Please choose a different date or delete the existing entry first.")
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

    private func loadActivityData() async {
        do {
            if #available(iOS 17.0, *) {
                if let daylight = try await healthKitManager.fetchTimeInDaylight(for: selectedDate) {
                    timeInDaylightMinutes = String(format: "%.0f", daylight)
                }
            }

            if let exercise = try await healthKitManager.fetchExerciseMinutes(for: selectedDate) {
                exerciseMinutes = String(format: "%.0f", exercise)
            }
        } catch {
            print("Error loading activity data: \(error)")
        }
    }

    private func loadEntryData(_ entry: SymptomEntry) {
        selectedDate = entry.timestamp
        moodLevel = entry.moodLevel
        anxietyLevel = entry.anxietyLevel
        anhedoniaLevel = entry.anhedoniaLevel
        sleepQualityRating = entry.sleepQualityRating
        sleepHours = entry.sleepHours.map { String(format: "%.1f", $0) } ?? ""
        timeInDaylightMinutes = entry.timeInDaylightMinutes.map { String(format: "%.0f", $0) } ?? ""
        exerciseMinutes = entry.exerciseMinutes.map { String(format: "%.0f", $0) } ?? ""
        notes = entry.notes

        takenMedications = Set(
            entry.medications?
                .filter { $0.taken }
                .compactMap { med in
                    userMedications.first(where: { $0.name == med.name })?.id
                } ?? []
        )

        substances = entry.substances?.map { sub in
            SubstanceInput(
                name: sub.name,
                amount: String(format: "%.1f", sub.amount),
                unit: sub.unit,
                notes: sub.notes
            )
        } ?? []
    }

    private func importMedicationsFromHealthKit(_ selectedMedications: [HKUserAnnotatedMedication]) {
        for hkMed in selectedMedications {
            let userMed = UserMedication(
                name: hkMed.medication.displayText,
                dosage: "",
                category: nil,
                frequency: .onceDaily,
                notes: "Imported from HealthKit"
            )
            modelContext.insert(userMed)
        }
        showingHealthKitImport = false
    }

    private func saveEntry() {
        if hasEntryForSelectedDate {
            showingDuplicateAlert = true
            return
        }

        if let existingEntry = entryToEdit {
            updateEntry(existingEntry)
        } else {
            createEntry()
        }
    }

    private func createEntry() {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) ?? selectedDate

        let entry = SymptomEntry(
            timestamp: endOfDay,
            moodLevel: moodLevel,
            anxietyLevel: anxietyLevel,
            anhedoniaLevel: anhedoniaLevel,
            sleepQualityRating: sleepQualityRating,
            sleepHours: Double(sleepHours),
            timeInDaylightMinutes: Double(timeInDaylightMinutes),
            exerciseMinutes: Double(exerciseMinutes),
            notes: notes
        )

        let meds = userMedications.compactMap { userMed -> Medication? in
            guard takenMedications.contains(userMed.id) else { return nil }
            return Medication(
                name: userMed.name,
                dosage: userMed.dosage,
                timestamp: endOfDay,
                taken: true,
                notes: ""
            )
        }

        let subs = substances.compactMap { input -> Substance? in
            guard !input.name.isEmpty, let amount = Double(input.amount) else {
                return nil
            }
            return Substance(
                name: input.name,
                amount: amount,
                unit: input.unit,
                timestamp: endOfDay,
                notes: input.notes
            )
        }

        entry.medications = meds
        entry.substances = subs
        meds.forEach { $0.symptomEntry = entry }
        subs.forEach { $0.symptomEntry = entry }

        modelContext.insert(entry)
        meds.forEach { modelContext.insert($0) }
        subs.forEach { modelContext.insert($0) }

        if healthKitManager.isAuthorized, let mood = moodLevel {
            Task {
                if #available(iOS 18.0, *) {
                    try? await healthKitManager.saveStateOfMind(
                        valence: mood.stateOfMindValence,
                        kind: .dailyMood,
                        labels: mood.stateOfMindLabels,
                        date: endOfDay
                    )
                }
            }
        }

        dismiss()
    }

    private func updateEntry(_ entry: SymptomEntry) {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate) ?? selectedDate

        entry.timestamp = endOfDay
        entry.moodLevel = moodLevel
        entry.anxietyLevel = anxietyLevel
        entry.anhedoniaLevel = anhedoniaLevel
        entry.sleepQualityRating = sleepQualityRating
        entry.sleepHours = Double(sleepHours)
        entry.timeInDaylightMinutes = Double(timeInDaylightMinutes)
        entry.exerciseMinutes = Double(exerciseMinutes)
        entry.notes = notes

        // Delete old medications
        if let oldMeds = entry.medications {
            oldMeds.forEach { modelContext.delete($0) }
        }
        entry.medications = nil

        let meds = userMedications.compactMap { userMed -> Medication? in
            guard takenMedications.contains(userMed.id) else { return nil }
            return Medication(
                name: userMed.name,
                dosage: userMed.dosage,
                timestamp: endOfDay,
                taken: true,
                notes: ""
            )
        }

        entry.medications = meds
        meds.forEach { $0.symptomEntry = entry }
        meds.forEach { modelContext.insert($0) }

        // Delete old substances
        if let oldSubs = entry.substances {
            oldSubs.forEach { modelContext.delete($0) }
        }
        entry.substances = nil

        let subs = substances.compactMap { input -> Substance? in
            guard !input.name.isEmpty, let amount = Double(input.amount) else {
                print("⚠️ Skipping substance: name='\(input.name)', amount='\(input.amount)'")
                return nil
            }
            print("✅ Creating substance: \(input.name) - \(amount) \(input.unit.abbreviation)")
            return Substance(
                name: input.name,
                amount: amount,
                unit: input.unit,
                timestamp: endOfDay,
                notes: input.notes
            )
        }

        print("📊 Total substances to save: \(subs.count)")
        entry.substances = subs
        subs.forEach { $0.symptomEntry = entry }
        subs.forEach { modelContext.insert($0) }

        if healthKitManager.isAuthorized, let mood = moodLevel {
            Task {
                if #available(iOS 18.0, *) {
                    try? await healthKitManager.saveStateOfMind(
                        valence: mood.stateOfMindValence,
                        kind: .dailyMood,
                        labels: mood.stateOfMindLabels,
                        date: endOfDay
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

struct SubstanceInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var amount: String = ""
    var unit: SubstanceUnit = .milliliters
    var notes: String = ""
}

#Preview {
    AddSymptomView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

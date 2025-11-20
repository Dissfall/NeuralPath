import HealthKit
import SwiftData
import SwiftUI

struct AddSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allEntries: [SymptomEntry]
    @Query(
        filter: #Predicate<UserMedication> { $0.isActive },
        sort: \UserMedication.name
    ) private var userMedications: [UserMedication]
    @Query(
        filter: #Predicate<UserSubstance> { $0.isActive },
        sort: \UserSubstance.name
    ) private var userSubstances: [UserSubstance]
    @Query(sort: \MedicationLog.timestamp, order: .forward) private
        var allMedicationLogs: [MedicationLog]
    @Query(sort: \SubstanceLog.timestamp, order: .forward) private
        var allSubstanceLogs: [SubstanceLog]

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
    @State private var takenMedications: [UUID: Date] = [:]
    @State private var takenSubstances: [SubstanceEntry] = []
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
            entry.id != entryToEdit?.id
                && Calendar.current.isDate(
                    entry.timestamp,
                    inSameDayAs: selectedDate
                )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker(
                        "Entry Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )

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
                                    Label(
                                        "Import from HealthKit",
                                        systemImage: "heart.text.square"
                                    )
                                }
                            }

                            NavigationLink {
                                MedicationManagementView()
                            } label: {
                                Label(
                                    "Add Medications in Settings",
                                    systemImage: "gear"
                                )
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(userMedications) { medication in
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(
                                    isOn: Binding(
                                        get: {
                                            takenMedications[medication.id]
                                                != nil
                                        },
                                        set: { newValue in
                                            if newValue {
                                                takenMedications[
                                                    medication.id
                                                ] = Date()
                                            } else {
                                                takenMedications[
                                                    medication.id
                                                ] = nil
                                            }
                                        }
                                    )
                                ) {
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

                                if takenMedications[medication.id] != nil {
                                    DatePicker(
                                        "Time Taken",
                                        selection: Binding(
                                            get: {
                                                takenMedications[medication.id]
                                                    ?? Date()
                                            },
                                            set: { newValue in
                                                takenMedications[
                                                    medication.id
                                                ] = newValue
                                            }
                                        ),
                                        displayedComponents: [.hourAndMinute]
                                    )
                                    .padding(.leading)
                                    .accessibilityLabel("Time taken for \(medication.name)")
                                    .accessibilityHint("Select when you took this medication")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Substances") {
                    // Get unique substance IDs that have instances, sorted for stability
                    let uniqueSubstanceIds = Array(Set(takenSubstances.map { $0.userSubstanceId })).sorted(by: { id1, id2 in
                        let name1 = userSubstances.first(where: { $0.id == id1 })?.name ?? ""
                        let name2 = userSubstances.first(where: { $0.id == id2 })?.name ?? ""
                        return name1 < name2
                    })

                    ForEach(uniqueSubstanceIds, id: \.self) { substanceId in
                        if let substance = userSubstances.first(where: { $0.id == substanceId }) {
                            SubstanceInstancesView(
                                substance: substance,
                                takenSubstances: $takenSubstances
                            )
                        }
                    }

                    // Add instance picker
                    Menu {
                        ForEach(userSubstances) { substance in
                            Button(substance.name) {
                                withAnimation {
                                    takenSubstances.append(
                                        SubstanceEntry(
                                            userSubstanceId: substance.id,
                                            amount: "",
                                            unit: substance.defaultUnit
                                                ?? .cups,
                                            timestamp: Date()
                                        )
                                    )
                                }
                            }
                        }
                    } label: {
                        Label("Add Substance", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    .disabled(userSubstances.isEmpty)

                    if userSubstances.isEmpty {
                        NavigationLink {
                            SubstanceManagementView()
                        } label: {
                            Label(
                                "Add Substances in Settings",
                                systemImage: "gear"
                            )
                            .font(.caption)
                        }
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
                    loadLogsForDate()
                    await loadSleepData()
                    await loadActivityData()
                }
            }
            .sheet(isPresented: $showingHealthKitImport) {
                HealthKitImportView(onImport: importMedicationsFromHealthKit)
            }
            .onChange(of: selectedDate) { _, _ in
                if !isEditMode {
                    loadLogsForDate()
                    Task {
                        await loadSleepData()
                        await loadActivityData()
                    }
                }
            }
            .alert("Entry Already Exists", isPresented: $showingDuplicateAlert)
            {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "An entry for this date already exists. Please choose a different date or delete the existing entry first."
                )
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
                if let daylight =
                    try await healthKitManager.fetchTimeInDaylight(
                        for: selectedDate
                    )
                {
                    timeInDaylightMinutes = String(format: "%.0f", daylight)
                }
            }

            if let exercise = try await healthKitManager.fetchExerciseMinutes(
                for: selectedDate
            ) {
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
        timeInDaylightMinutes =
            entry.timeInDaylightMinutes.map { String(format: "%.0f", $0) } ?? ""
        exerciseMinutes =
            entry.exerciseMinutes.map { String(format: "%.0f", $0) } ?? ""
        notes = entry.notes

        var takenMeds: [UUID: Date] = [:]
        entry.medications?
            .filter { $0.taken }
            .forEach { med in
                if let userMed = userMedications.first(where: {
                    $0.name == med.name
                }) {
                    takenMeds[userMed.id] = med.timestamp
                }
            }
        takenMedications = takenMeds

        var substanceEntries: [SubstanceEntry] = []
        entry.substances?.forEach { sub in
            if let userSubstance = userSubstances.first(where: {
                $0.name == sub.name
            }) {
                substanceEntries.append(
                    SubstanceEntry(
                        userSubstanceId: userSubstance.id,
                        amount: String(format: "%.1f", sub.amount),
                        unit: sub.unit,
                        timestamp: sub.timestamp
                    )
                )
            }
        }
        takenSubstances = substanceEntries
    }

    private func loadLogsForDate() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay =
            calendar.date(byAdding: .day, value: 1, to: startOfDay)
            ?? selectedDate

        // Load medication logs for the selected date
        let medicationLogsForDate = allMedicationLogs.filter { log in
            log.timestamp >= startOfDay && log.timestamp < endOfDay
        }

        var takenMeds: [UUID: Date] = [:]
        for log in medicationLogsForDate {
            if let userMed = userMedications.first(where: {
                $0.name == log.medicationName
            }) {
                // If multiple logs for same medication, use the most recent timestamp
                if let existingTimestamp = takenMeds[userMed.id] {
                    if log.timestamp > existingTimestamp {
                        takenMeds[userMed.id] = log.timestamp
                    }
                } else {
                    takenMeds[userMed.id] = log.timestamp
                }
            }
        }
        takenMedications = takenMeds

        // Load substance logs for the selected date
        let substanceLogsForDate = allSubstanceLogs.filter { log in
            log.timestamp >= startOfDay && log.timestamp < endOfDay
        }

        var substanceEntries: [SubstanceEntry] = []
        for log in substanceLogsForDate {
            if let userSub = userSubstances.first(where: {
                $0.name == log.substanceName
            }) {
                substanceEntries.append(
                    SubstanceEntry(
                        userSubstanceId: userSub.id,
                        amount: String(format: "%.1f", log.amount),
                        unit: log.unit,
                        timestamp: log.timestamp
                    )
                )
            }
        }
        takenSubstances = substanceEntries
    }

    private func importMedicationsFromHealthKit(
        _ selectedMedications: [HKUserAnnotatedMedication]
    ) {
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
        let endOfDay =
            calendar.date(
                bySettingHour: 23,
                minute: 59,
                second: 59,
                of: selectedDate
            ) ?? selectedDate

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

        let meds = takenMedications.compactMap {
            (id, timestamp) -> Medication? in
            guard let userMed = userMedications.first(where: { $0.id == id })
            else { return nil }
            return Medication(
                name: userMed.name,
                dosage: userMed.dosage,
                timestamp: timestamp,
                taken: true,
                notes: ""
            )
        }

        let subs = takenSubstances.compactMap { substanceEntry -> Substance? in
            guard
                let userSubstance = userSubstances.first(where: {
                    $0.id == substanceEntry.userSubstanceId
                }),
                let amount = Double(substanceEntry.amount), amount > 0
            else {
                return nil
            }
            return Substance(
                name: userSubstance.name,
                amount: amount,
                unit: substanceEntry.unit,
                timestamp: substanceEntry.timestamp,
                notes: ""
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
        let endOfDay =
            calendar.date(
                bySettingHour: 23,
                minute: 59,
                second: 59,
                of: selectedDate
            ) ?? selectedDate

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

        let meds = takenMedications.compactMap {
            (id, timestamp) -> Medication? in
            guard let userMed = userMedications.first(where: { $0.id == id })
            else { return nil }
            return Medication(
                name: userMed.name,
                dosage: userMed.dosage,
                timestamp: timestamp,
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

        let subs = takenSubstances.compactMap { substanceEntry -> Substance? in
            guard
                let userSubstance = userSubstances.first(where: {
                    $0.id == substanceEntry.userSubstanceId
                }),
                let amount = Double(substanceEntry.amount), amount > 0
            else {
                return nil
            }
            return Substance(
                name: userSubstance.name,
                amount: amount,
                unit: substanceEntry.unit,
                timestamp: substanceEntry.timestamp,
                notes: ""
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

struct SubstanceAmount {
    var amount: String
    var unit: SubstanceUnit
    var timestamp: Date
}

struct SubstanceEntry: Identifiable {
    var id: UUID
    var userSubstanceId: UUID
    var amount: String
    var unit: SubstanceUnit
    var timestamp: Date

    init(id: UUID = UUID(), userSubstanceId: UUID, amount: String, unit: SubstanceUnit, timestamp: Date) {
        self.id = id
        self.userSubstanceId = userSubstanceId
        self.amount = amount
        self.unit = unit
        self.timestamp = timestamp
    }
}

struct SubstanceInstancesView: View {
    let substance: UserSubstance
    @Binding var takenSubstances: [SubstanceEntry]

    @State private var editingInstanceId: UUID?

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    private func deleteInstance(_ instanceId: UUID) {
        if let index = takenSubstances.firstIndex(where: { $0.id == instanceId }) {
            withAnimation(.easeOut(duration: 0.2)) {
                _ = takenSubstances.remove(at: index)
            }
        }
    }

    private func addInstance() {
        let filteredInstances = takenSubstances.filter { $0.userSubstanceId == substance.id }
        let lastUnit = filteredInstances.last?.unit ?? substance.defaultUnit ?? .cups

        let newEntry = SubstanceEntry(
            userSubstanceId: substance.id,
            amount: "",
            unit: lastUnit,
            timestamp: Date()
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            takenSubstances.append(newEntry)
            editingInstanceId = newEntry.id
        }
    }

    var body: some View {
        let filteredInstances = takenSubstances
            .filter { $0.userSubstanceId == substance.id }
            .sorted { $0.timestamp < $1.timestamp }

        VStack(alignment: .leading, spacing: 8) {
            // Header with count
            HStack {
                Text(substance.name)
                    .font(.headline)

                if !filteredInstances.isEmpty {
                    Text("(\(filteredInstances.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if filteredInstances.isEmpty {
                VStack(spacing: 12) {
                    Text("No instances logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)

                    Button(action: addInstance) {
                        Label("Log First Instance", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityLabel("Log first \(substance.name) instance")
                    .accessibilityHint("Tap to add the first instance of \(substance.name) for today")
                }
                .padding(.vertical, 8)
            } else {
                // Instance list
                ForEach(filteredInstances) { instance in
                    SubstanceInstanceRow(
                        instance: instance,
                        isEditing: editingInstanceId == instance.id,
                        timeFormatter: timeFormatter,
                        onUpdateAmount: { newValue in
                            if let index = takenSubstances.firstIndex(where: { $0.id == instance.id }) {
                                takenSubstances[index].amount = newValue
                            }
                        },
                        onUpdateUnit: { newValue in
                            if let index = takenSubstances.firstIndex(where: { $0.id == instance.id }) {
                                takenSubstances[index].unit = newValue
                            }
                        },
                        onUpdateTime: { newValue in
                            if let index = takenSubstances.firstIndex(where: { $0.id == instance.id }) {
                                takenSubstances[index].timestamp = newValue
                            }
                        },
                        onDelete: { deleteInstance(instance.id) },
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                editingInstanceId = editingInstanceId == instance.id ? nil : instance.id
                            }
                        }
                    )
                }

                Button(action: addInstance) {
                    Label("Add Another", systemImage: "plus.circle")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
                .accessibilityLabel("Add another \(substance.name) instance")
                .accessibilityHint("Tap to log another instance of \(substance.name)")
            }
        }
        .padding(.vertical, 8)
    }
}

struct SubstanceInstanceRow: View {
    let instance: SubstanceEntry
    let isEditing: Bool
    let timeFormatter: DateFormatter
    let onUpdateAmount: (String) -> Void
    let onUpdateUnit: (SubstanceUnit) -> Void
    let onUpdateTime: (Date) -> Void
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // Time label
                Text(timeFormatter.string(from: instance.timestamp))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.blue)
                    .frame(minWidth: 60, alignment: .leading)
                    .accessibilityLabel("Time: \(timeFormatter.string(from: instance.timestamp))")

                // Amount and unit
                HStack(spacing: 4) {
                    TextField("0", text: Binding(
                        get: { instance.amount },
                        set: onUpdateAmount
                    ))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .disabled(!isEditing)
                    .accessibilityLabel("Amount")
                    .accessibilityValue(instance.amount.isEmpty ? "Not set" : instance.amount)
                    .accessibilityHint(isEditing ? "Enter the amount" : "Tap edit to change")

                    Picker("Unit", selection: Binding(
                        get: { instance.unit },
                        set: onUpdateUnit
                    )) {
                        ForEach(SubstanceUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!isEditing)
                    .frame(minWidth: 50)
                    .accessibilityLabel("Unit")
                    .accessibilityValue(instance.unit.displayName)
                    .accessibilityHint(isEditing ? "Select a unit of measurement" : "Tap edit to change")
                }

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    Button(action: onTap) {
                        Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                            .foregroundStyle(isEditing ? .green : .blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isEditing ? "Save changes" : "Edit instance")
                    .accessibilityHint(isEditing ? "Tap to save your changes" : "Tap to edit this instance")

                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete instance")
                    .accessibilityHint("Tap to remove this instance")
                }
            }

            // Expanded time picker when editing
            if isEditing {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { instance.timestamp },
                        set: onUpdateTime
                    ),
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding(.top, 4)
                .accessibilityLabel("Instance time")
                .accessibilityHint("Select when this instance was taken")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isEditing ? Color.blue.opacity(0.08) : Color.gray.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEditing ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    AddSymptomView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

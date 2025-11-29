import HealthKit
import SwiftData
import SwiftUI

struct AddSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allEntries: [SymptomEntry]
    @Query(
        filter: #Predicate<UserMedication> { $0.isActive == true },
        sort: \UserMedication.name
    ) private var userMedications: [UserMedication]
    @Query(
        filter: #Predicate<UserSubstance> { $0.isActive == true },
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

    // Edit states for medications
    @State private var medicationToEditTime: UserMedication?
    @State private var editMedicationTime: Date = Date()

    // Edit states for substances
    @State private var substanceToEditTime: SubstanceEntry?
    @State private var substanceToEditAmount: SubstanceEntry?
    @State private var editSubstanceTime: Date = Date()
    @State private var editSubstanceAmount: String = ""

    // Add substance state
    @State private var substanceToAdd: UserSubstance?
    @State private var newSubstanceAmount: String = "1"

    private let healthKitManager = HealthKitManager.shared

    init(entryToEdit: SymptomEntry? = nil) {
        self.entryToEdit = entryToEdit
        _selectedDate = State(initialValue: entryToEdit?.timestamp ?? Date())
    }

    private var isEditMode: Bool {
        entryToEdit != nil
    }

    private var scheduledMedications: [UserMedication] {
        userMedications.filter { $0.frequency != .asNeeded }
    }

    private var prnMedications: [UserMedication] {
        userMedications.filter { $0.frequency == .asNeeded }
    }

    private var medicationsTakenCount: Int {
        scheduledMedications.filter { med in
            guard let medId = med.id else { return false }
            return takenMedications[medId] != nil
        }.count
    }

    private var medicationsSummary: String {
        if scheduledMedications.isEmpty {
            let prnCount = takenMedications.filter { id, _ in
                prnMedications.contains { $0.id == id }
            }.count
            return prnCount == 0 ? "None" : "\(prnCount) dose\(prnCount == 1 ? "" : "s")"
        } else {
            let prnCount = takenMedications.filter { id, _ in
                prnMedications.contains { $0.id == id }
            }.count
            let prnSuffix = prnCount > 0 ? " + \(prnCount) PRN" : ""
            return "\(medicationsTakenCount)/\(scheduledMedications.count)\(prnSuffix)"
        }
    }

    private var substancesSummary: String {
        if takenSubstances.isEmpty {
            return "None"
        }
        return "\(takenSubstances.count) log\(takenSubstances.count == 1 ? "" : "s")"
    }

    private var hasEntryForSelectedDate: Bool {
        allEntries.contains { entry in
            entry.id != entryToEdit?.id
                && Calendar.current.isDate(
                    entry.timestamp ?? Date(),
                    inSameDayAs: selectedDate
                )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                DateSelectionSection(
                    selectedDate: $selectedDate,
                    hasEntryForSelectedDate: hasEntryForSelectedDate
                )

                MoodSection(moodLevel: $moodLevel)
                AnxietySection(anxietyLevel: $anxietyLevel)
                AnhedoniaSection(anhedoniaLevel: $anhedoniaLevel)
                SleepSection(sleepHours: $sleepHours, sleepQualityRating: $sleepQualityRating)
                ActivitySection(
                    timeInDaylightMinutes: $timeInDaylightMinutes,
                    exerciseMinutes: $exerciseMinutes
                )

                // Medications Section
                if !userMedications.isEmpty {
                    Section {
                        // Scheduled medications
                        ForEach(scheduledMedications) { medication in
                            let isTaken = medication.id.flatMap { takenMedications[$0] } != nil
                            let takenTime = medication.id.flatMap { takenMedications[$0] }

                            EntryMedicationRow(
                                medication: medication,
                                taken: isTaken,
                                time: takenTime,
                                isPrn: false,
                                onToggle: {
                                    guard let medId = medication.id else { return }
                                    if takenMedications[medId] == nil {
                                        takenMedications[medId] = Date()
                                    }
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if isTaken {
                                    Button {
                                        guard let medId = medication.id else { return }
                                        takenMedications[medId] = nil
                                    } label: {
                                        Label("Undo", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.orange)

                                    Button {
                                        editMedicationTime = takenTime ?? Date()
                                        medicationToEditTime = medication
                                    } label: {
                                        Label("Time", systemImage: "clock")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }

                        // PRN medications taken
                        ForEach(prnMedications.filter { med in
                            guard let medId = med.id else { return false }
                            return takenMedications[medId] != nil
                        }) { medication in
                            let takenTime = medication.id.flatMap { takenMedications[$0] }

                            EntryPrnRow(medication: medication, time: takenTime)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        guard let medId = medication.id else { return }
                                        takenMedications[medId] = nil
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        editMedicationTime = takenTime ?? Date()
                                        medicationToEditTime = medication
                                    } label: {
                                        Label("Time", systemImage: "clock")
                                    }
                                    .tint(.blue)
                                }
                        }

                        // Take As-Needed button
                        if !prnMedications.isEmpty {
                            Menu {
                                ForEach(prnMedications) { medication in
                                    Button {
                                        guard let medId = medication.id else { return }
                                        takenMedications[medId] = Date()
                                    } label: {
                                        Label(medication.name ?? "Unknown", systemImage: "pills")
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("Take As-Needed")
                                        .foregroundStyle(.blue)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Label("Medications", systemImage: "pills.fill")
                            Spacer()
                            Text(medicationsSummary)
                                .font(.subheadline)
                                .foregroundStyle(medicationsTakenCount == scheduledMedications.count ? .green : .secondary)
                        }
                    }
                } else {
                    Section("Medications") {
                        EmptyMedicationsView(
                            healthKitManager: healthKitManager,
                            showingHealthKitImport: $showingHealthKitImport
                        )
                    }
                }

                // Substances Section
                if !userSubstances.isEmpty || !takenSubstances.isEmpty {
                    Section {
                        ForEach(takenSubstances) { entry in
                            EntrySubstanceRow(entry: entry, userSubstances: userSubstances)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        takenSubstances.removeAll { $0.id == entry.id }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        editSubstanceTime = entry.timestamp
                                        substanceToEditTime = entry
                                    } label: {
                                        Label("Time", systemImage: "clock")
                                    }
                                    .tint(.blue)

                                    Button {
                                        editSubstanceAmount = entry.amount
                                        substanceToEditAmount = entry
                                    } label: {
                                        Label("Amount", systemImage: "number")
                                    }
                                    .tint(.purple)
                                }
                        }

                        if !userSubstances.isEmpty {
                            Menu {
                                ForEach(userSubstances) { substance in
                                    Button {
                                        newSubstanceAmount = "1"
                                        substanceToAdd = substance
                                    } label: {
                                        Label(substance.name ?? "Unknown", systemImage: "drop.triangle")
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("Log Substance")
                                        .foregroundStyle(.blue)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Label("Substances", systemImage: "drop.triangle.fill")
                            Spacer()
                            Text(substancesSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section("Substances") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No substances in your library")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            NavigationLink {
                                SubstanceManagementView()
                            } label: {
                                Label("Add Substances in Settings", systemImage: "gear")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                NotesSection(notes: $notes)
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
            // Edit medication time sheet
            .sheet(isPresented: Binding(
                get: { medicationToEditTime != nil },
                set: { if !$0 { medicationToEditTime = nil } }
            )) {
                if let medication = medicationToEditTime {
                    EntryEditTimeSheet(
                        title: "Edit Time",
                        subtitle: medication.name ?? "Medication",
                        time: $editMedicationTime,
                        onSave: {
                            if let medId = medication.id {
                                takenMedications[medId] = editMedicationTime
                            }
                            medicationToEditTime = nil
                        },
                        onCancel: { medicationToEditTime = nil }
                    )
                }
            }
            // Edit substance time sheet
            .sheet(isPresented: Binding(
                get: { substanceToEditTime != nil },
                set: { if !$0 { substanceToEditTime = nil } }
            )) {
                if let entry = substanceToEditTime {
                    EntryEditTimeSheet(
                        title: "Edit Time",
                        subtitle: userSubstances.first { $0.id == entry.userSubstanceId }?.name ?? "Substance",
                        time: $editSubstanceTime,
                        onSave: {
                            if let index = takenSubstances.firstIndex(where: { $0.id == entry.id }) {
                                takenSubstances[index].timestamp = editSubstanceTime
                            }
                            substanceToEditTime = nil
                        },
                        onCancel: { substanceToEditTime = nil }
                    )
                }
            }
            // Edit substance amount alert
            .alert("Edit Amount", isPresented: Binding(
                get: { substanceToEditAmount != nil },
                set: { if !$0 { substanceToEditAmount = nil } }
            )) {
                TextField("Amount", text: $editSubstanceAmount)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) {
                    substanceToEditAmount = nil
                }
                Button("Save") {
                    if let entry = substanceToEditAmount,
                       let index = takenSubstances.firstIndex(where: { $0.id == entry.id }) {
                        takenSubstances[index].amount = editSubstanceAmount
                    }
                    substanceToEditAmount = nil
                }
            } message: {
                if let entry = substanceToEditAmount {
                    Text(userSubstances.first { $0.id == entry.userSubstanceId }?.name ?? "Substance")
                }
            }
            // Add substance alert
            .alert("Log Substance", isPresented: Binding(
                get: { substanceToAdd != nil },
                set: { if !$0 { substanceToAdd = nil } }
            )) {
                TextField("Amount", text: $newSubstanceAmount)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) {
                    substanceToAdd = nil
                }
                Button("Log") {
                    if let substance = substanceToAdd,
                       let substanceId = substance.id {
                        takenSubstances.append(
                            SubstanceEntry(
                                userSubstanceId: substanceId,
                                amount: newSubstanceAmount,
                                unit: substance.defaultUnit ?? .other,
                                timestamp: Date()
                            )
                        )
                    }
                    substanceToAdd = nil
                }
            } message: {
                if let substance = substanceToAdd {
                    Text("\(substance.name ?? "Unknown") (\(substance.defaultUnit?.abbreviation ?? ""))")
                }
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
        selectedDate = entry.timestamp ?? Date()
        moodLevel = entry.moodLevel
        anxietyLevel = entry.anxietyLevel
        anhedoniaLevel = entry.anhedoniaLevel
        sleepQualityRating = entry.sleepQualityRating
        sleepHours = entry.sleepHours.map { String(format: "%.1f", $0) } ?? ""
        timeInDaylightMinutes =
            entry.timeInDaylightMinutes.map { String(format: "%.0f", $0) } ?? ""
        exerciseMinutes =
            entry.exerciseMinutes.map { String(format: "%.0f", $0) } ?? ""
        notes = entry.notes ?? ""

        var takenMeds: [UUID: Date] = [:]
        entry.medications?
            .filter { $0.taken == true }
            .forEach { med in
                if let userMed = userMedications.first(where: {
                    $0.name == med.name
                }) {
                    if let userMedId = userMed.id {
                        takenMeds[userMedId] = med.timestamp ?? Date()
                    }
                }
            }
        takenMedications = takenMeds

        var substanceEntries: [SubstanceEntry] = []
        entry.substances?.forEach { sub in
            if let userSubstance = userSubstances.first(where: {
                $0.name == sub.name
            }), let userSubId = userSubstance.id {
                substanceEntries.append(
                    SubstanceEntry(
                        userSubstanceId: userSubId,
                        amount: String(format: "%.1f", sub.amount ?? 0.0),
                        unit: sub.unit ?? .other,
                        timestamp: sub.timestamp ?? Date()
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
            (log.timestamp ?? Date.distantPast) >= startOfDay && (log.timestamp ?? Date.distantFuture) < endOfDay
        }

        var takenMeds: [UUID: Date] = [:]
        for log in medicationLogsForDate {
            if let userMed = userMedications.first(where: {
                $0.name == log.medicationName
            }),
            let userMedId = userMed.id,
            let logTimestamp = log.timestamp {
                // If multiple logs for same medication, use the most recent timestamp
                if let existingTimestamp = takenMeds[userMedId] {
                    if logTimestamp > existingTimestamp {
                        takenMeds[userMedId] = logTimestamp
                    }
                } else {
                    takenMeds[userMedId] = logTimestamp
                }
            }
        }
        takenMedications = takenMeds

        // Load substance logs for the selected date
        let substanceLogsForDate = allSubstanceLogs.filter { log in
            (log.timestamp ?? Date.distantPast) >= startOfDay && (log.timestamp ?? Date.distantFuture) < endOfDay
        }

        var substanceEntries: [SubstanceEntry] = []
        for log in substanceLogsForDate {
            if let userSub = userSubstances.first(where: {
                $0.name == log.substanceName
            }),
            let userSubId = userSub.id {
                substanceEntries.append(
                    SubstanceEntry(
                        userSubstanceId: userSubId,
                        amount: String(format: "%.1f", log.amount ?? 0),
                        unit: log.unit ?? .milligrams,
                        timestamp: log.timestamp ?? Date()
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

// MARK: - Sub-views for AddSymptomView

struct DateSelectionSection: View {
    @Binding var selectedDate: Date
    let hasEntryForSelectedDate: Bool

    var body: some View {
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
    }
}

struct MoodSection: View {
    @Binding var moodLevel: MoodLevel?

    var body: some View {
        Section("Mood") {
            Picker("Mood Level", selection: $moodLevel) {
                Text("Not Set").tag(nil as MoodLevel?)
                ForEach(MoodLevel.allCases, id: \.self) { level in
                    Text("\(level.emoji) \(level.displayName)").tag(level as MoodLevel?)
                }
            }
        }
    }
}

struct AnxietySection: View {
    @Binding var anxietyLevel: AnxietyLevel?

    var body: some View {
        Section("Anxiety") {
            Picker("Anxiety Level", selection: $anxietyLevel) {
                Text("Not Set").tag(nil as AnxietyLevel?)
                ForEach(AnxietyLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level as AnxietyLevel?)
                }
            }
        }
    }
}

struct AnhedoniaSection: View {
    @Binding var anhedoniaLevel: AnhedoniaLevel?

    var body: some View {
        Section("Anhedonia") {
            Picker("Anhedonia Level", selection: $anhedoniaLevel) {
                Text("Not Set").tag(nil as AnhedoniaLevel?)
                ForEach(AnhedoniaLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level as AnhedoniaLevel?)
                }
            }

            if let anhedonia = anhedoniaLevel {
                Text(anhedonia.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SleepSection: View {
    @Binding var sleepHours: String
    @Binding var sleepQualityRating: Int?

    var body: some View {
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
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundStyle(star <= rating ? .yellow : .gray)
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
    }
}

struct ActivitySection: View {
    @Binding var timeInDaylightMinutes: String
    @Binding var exerciseMinutes: String

    var body: some View {
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
    }
}

struct NotesSection: View {
    @Binding var notes: String

    var body: some View {
        Section("Notes") {
            TextField("Additional notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

// MARK: - Entry Medication Row

struct EntryMedicationRow: View {
    let medication: UserMedication
    let taken: Bool
    let time: Date?
    let isPrn: Bool
    let onToggle: () -> Void

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: taken ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(taken ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(taken)

            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name ?? "Unknown")
                    .font(.subheadline)
                if let dosage = medication.dosage, !dosage.isEmpty {
                    Text(dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let time = time {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Entry PRN Row

struct EntryPrnRow: View {
    let medication: UserMedication
    let time: Date?

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            HStack(spacing: 6) {
                Text(medication.name ?? "Unknown")
                    .font(.subheadline)
                Text("PRN")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            Spacer()

            if let time = time {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Entry Substance Row

struct EntrySubstanceRow: View {
    let entry: SubstanceEntry
    let userSubstances: [UserSubstance]

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    private var substanceName: String {
        userSubstances.first { $0.id == entry.userSubstanceId }?.name ?? "Unknown"
    }

    private var formattedAmount: String {
        guard let amount = Double(entry.amount), amount > 0 else { return "" }
        let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", amount)
            : String(format: "%.1f", amount)
        return "\(formattedAmount) \(entry.unit.abbreviation)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            Text(substanceName)
                .font(.subheadline)

            Spacer()

            if !formattedAmount.isEmpty {
                Text(formattedAmount)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(timeFormatter.string(from: entry.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Entry Edit Time Sheet

struct EntryEditTimeSheet: View {
    let title: String
    let subtitle: String
    @Binding var time: Date
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct EmptyMedicationsView: View {
    let healthKitManager: HealthKitManager
    @Binding var showingHealthKitImport: Bool

    var body: some View {
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
    }
}

#Preview {
    AddSymptomView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

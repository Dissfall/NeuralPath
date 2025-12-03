import Foundation
import HealthKit
import SwiftData
import SwiftUI

// MARK: - Entry Step Enum

enum EntryStep: Int, CaseIterable, Identifiable {
    case coreFeelings = 0
    case physicalHealth = 1
    case medications = 2
    case wellness = 3
    case review = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .coreFeelings: return "Feelings"
        case .physicalHealth: return "Health"
        case .medications: return "Meds"
        case .wellness: return "Wellness"
        case .review: return "Review"
        }
    }

    var icon: String {
        switch self {
        case .coreFeelings: return "face.smiling"
        case .physicalHealth: return "heart.text.square"
        case .medications: return "pills"
        case .wellness: return "sparkles"
        case .review: return "checkmark.circle"
        }
    }
}

// MARK: - Helper Types

struct SubstanceEntry: Identifiable, Equatable {
    let id: UUID
    let userSubstanceId: UUID
    var amount: String
    var unit: SubstanceUnit
    var timestamp: Date
}

struct MindfulnessLogEntry: Identifiable, Equatable {
    let id: UUID
    let userMindfulnessId: UUID
    var timestamp: Date
}

struct SelfCareLogEntry: Identifiable, Equatable {
    let id: UUID
    let userSelfCareId: UUID
    let timeOfDay: SelfCareTimeOfDay
    var timestamp: Date
}

// MARK: - ViewModel

@Observable
@MainActor
final class StepperEntryViewModel {
    // MARK: - Navigation
    var currentStep: EntryStep = .coreFeelings

    // MARK: - Date Selection
    var selectedDate: Date
    var showingDuplicateAlert = false

    // MARK: - Step 1: Core Feelings
    var moodLevel: MoodLevel?
    var selectedEmotions: Set<Emotion> = []
    var anxietyLevel: AnxietyLevel?
    var anhedoniaLevel: AnhedoniaLevel?

    // MARK: - Step 2: Physical Health
    var sleepHours: String = ""
    var sleepQualityRating: Int?
    var exerciseMinutes: String = ""
    var timeInDaylightMinutes: String = ""
    var isLoadingHealthData = false

    // MARK: - Step 3: Medications & Substances
    var takenMedications: [UUID: Date] = [:]
    var takenSubstances: [SubstanceEntry] = []

    // MARK: - Step 4: Wellness
    var loggedMindfulness: [MindfulnessLogEntry] = []
    var loggedSelfCare: [SelfCareLogEntry] = []

    // MARK: - Step 5: Notes
    var notes: String = ""

    // MARK: - Edit State
    private(set) var entryToEdit: SymptomEntry?
    var isEditMode: Bool { entryToEdit != nil }

    // MARK: - Sheet States
    var medicationToEditTime: UserMedication?
    var editMedicationTime: Date = Date()
    var substanceToEditTime: SubstanceEntry?
    var substanceToEditAmount: SubstanceEntry?
    var editSubstanceTime: Date = Date()
    var editSubstanceAmount: String = ""
    var substanceToAdd: UserSubstance?
    var newSubstanceAmount: String = "1"
    var mindfulnessToEditTime: MindfulnessLogEntry?
    var editMindfulnessTime: Date = Date()
    var selfCareToEditTime: SelfCareLogEntry?
    var editSelfCareTime: Date = Date()
    var showingHealthKitImport = false

    // MARK: - Time Warnings
    var showEarlyMorningAlert = false
    var showNotEndOfDayBanner = false

    // MARK: - Query Data (populated by parent view)
    var userMedications: [UserMedication] = []
    var userSubstances: [UserSubstance] = []
    var userMindfulness: [UserMindfulness] = []
    var userSelfCare: [UserSelfCare] = []
    var allEntries: [SymptomEntry] = []
    var allMedicationLogs: [MedicationLog] = []
    var allSubstanceLogs: [SubstanceLog] = []
    var allMindfulnessLogs: [MindfulnessLog] = []
    var allSelfCareLogs: [SelfCareLog] = []

    // MARK: - Dependencies
    private let healthKitManager = HealthKitManager.shared
    private var modelContext: ModelContext?
    private let neverShowTimeWarningKey = "neverShowEntryTimeWarning"

    // MARK: - Init

    init(entryToEdit: SymptomEntry? = nil) {
        self.entryToEdit = entryToEdit
        self.selectedDate = entryToEdit?.timestamp ?? Date()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Computed Properties

    var scheduledMedications: [UserMedication] {
        userMedications.filter { $0.frequency != .asNeeded }
    }

    var prnMedications: [UserMedication] {
        userMedications.filter { $0.frequency == .asNeeded }
    }

    var medicationsTakenCount: Int {
        scheduledMedications.filter { med in
            guard let medId = med.id else { return false }
            return takenMedications[medId] != nil
        }.count
    }

    var medicationsSummary: String {
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

    var substancesSummary: String {
        if takenSubstances.isEmpty {
            return "None"
        }
        return "\(takenSubstances.count) log\(takenSubstances.count == 1 ? "" : "s")"
    }

    var mindfulnessSummary: String {
        if loggedMindfulness.isEmpty {
            return "None"
        }
        return "\(loggedMindfulness.count) session\(loggedMindfulness.count == 1 ? "" : "s")"
    }

    var selfCareSummary: String {
        if loggedSelfCare.isEmpty {
            return "None"
        }
        return "\(loggedSelfCare.count) practice\(loggedSelfCare.count == 1 ? "" : "s")"
    }

    var hasEntryForSelectedDate: Bool {
        allEntries.contains { entry in
            entry.id != entryToEdit?.id
                && Calendar.current.isDate(
                    entry.timestamp ?? Date(),
                    inSameDayAs: selectedDate
                )
        }
    }

    var hasCoreFeelings: Bool {
        moodLevel != nil || !selectedEmotions.isEmpty || anxietyLevel != nil || anhedoniaLevel != nil
    }

    var hasPhysicalHealth: Bool {
        !sleepHours.isEmpty || sleepQualityRating != nil || !exerciseMinutes.isEmpty || !timeInDaylightMinutes.isEmpty
    }

    var hasMedications: Bool {
        !takenMedications.isEmpty || !takenSubstances.isEmpty
    }

    var hasWellness: Bool {
        !loggedMindfulness.isEmpty || !loggedSelfCare.isEmpty
    }

    var hasNotes: Bool {
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasAnyData: Bool {
        hasCoreFeelings || hasPhysicalHealth || hasMedications || hasWellness || hasNotes
    }

    var hasUnsavedChanges: Bool {
        hasAnyData
    }

    private var neverShowTimeWarning: Bool {
        UserDefaults.standard.bool(forKey: neverShowTimeWarningKey)
    }

    // MARK: - Navigation

    func nextStep() {
        guard currentStep.rawValue < EntryStep.allCases.count - 1 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = EntryStep(rawValue: currentStep.rawValue + 1)!
        }
    }

    func previousStep() {
        guard currentStep.rawValue > 0 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = EntryStep(rawValue: currentStep.rawValue - 1)!
        }
    }

    func goToStep(_ step: EntryStep) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    // MARK: - Time Warnings

    func checkTimeAndShowWarnings() {
        guard !isEditMode else { return }

        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 0 && hour < 7 {
            showEarlyMorningAlert = true
        } else if hour >= 7 && hour < 19 && !neverShowTimeWarning {
            showNotEndOfDayBanner = true
        }
    }

    func setNeverShowTimeWarning() {
        UserDefaults.standard.set(true, forKey: neverShowTimeWarningKey)
        showNotEndOfDayBanner = false
    }

    func useYesterdayDate() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }

    // MARK: - Data Loading

    func loadHealthKitData() async {
        guard healthKitManager.isAuthorized else { return }

        isLoadingHealthData = true
        defer { isLoadingHealthData = false }

        // Load sleep data
        if let sleepData = try? await healthKitManager.fetchSleepData(for: selectedDate) {
            if sleepHours.isEmpty {
                sleepHours = String(format: "%.1f", sleepData.hours)
            }
            if sleepQualityRating == nil {
                sleepQualityRating = sleepData.quality
            }
        }
    }

    func loadLogsForDate() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Load medication logs
        takenMedications = [:]
        for log in allMedicationLogs {
            guard let timestamp = log.timestamp,
                  timestamp >= startOfDay && timestamp < endOfDay,
                  let userMed = log.userMedication,
                  let medId = userMed.id
            else { continue }
            takenMedications[medId] = timestamp
        }

        // Load substance logs
        takenSubstances = allSubstanceLogs
            .filter { log in
                guard let timestamp = log.timestamp else { return false }
                return timestamp >= startOfDay && timestamp < endOfDay
            }
            .compactMap { log -> SubstanceEntry? in
                guard let userSub = log.userSubstance,
                      let subId = userSub.id
                else { return nil }
                let amountStr = log.amount.map { String(format: "%.1f", $0) } ?? "1"
                return SubstanceEntry(
                    id: log.id ?? UUID(),
                    userSubstanceId: subId,
                    amount: amountStr,
                    unit: log.unit ?? userSub.defaultUnit ?? .other,
                    timestamp: log.timestamp ?? Date()
                )
            }

        // Load mindfulness logs
        loggedMindfulness = allMindfulnessLogs
            .filter { log in
                guard let timestamp = log.timestamp else { return false }
                return timestamp >= startOfDay && timestamp < endOfDay
            }
            .compactMap { log -> MindfulnessLogEntry? in
                guard let practice = log.userMindfulness,
                      let practiceId = practice.id
                else { return nil }
                return MindfulnessLogEntry(
                    id: log.id ?? UUID(),
                    userMindfulnessId: practiceId,
                    timestamp: log.timestamp ?? Date()
                )
            }

        // Load self-care logs
        loggedSelfCare = allSelfCareLogs
            .filter { log in
                guard let timestamp = log.timestamp else { return false }
                return timestamp >= startOfDay && timestamp < endOfDay
            }
            .compactMap { log -> SelfCareLogEntry? in
                guard let practice = log.userSelfCare,
                      let practiceId = practice.id
                else { return nil }
                return SelfCareLogEntry(
                    id: log.id ?? UUID(),
                    userSelfCareId: practiceId,
                    timeOfDay: practice.timeOfDay ?? .morning,
                    timestamp: log.timestamp ?? Date()
                )
            }
    }

    func loadEntryData(_ entry: SymptomEntry) {
        selectedDate = entry.timestamp ?? Date()
        moodLevel = entry.moodLevel
        anxietyLevel = entry.anxietyLevel
        anhedoniaLevel = entry.anhedoniaLevel
        sleepQualityRating = entry.sleepQualityRating
        notes = entry.notes ?? ""
        selectedEmotions = Set(entry.emotions)

        if let hours = entry.sleepHours {
            sleepHours = String(format: "%.1f", hours)
        }
        if let daylight = entry.timeInDaylightMinutes {
            timeInDaylightMinutes = String(Int(daylight))
        }
        if let exercise = entry.exerciseMinutes {
            exerciseMinutes = String(Int(exercise))
        }

        // Load medications from entry
        takenMedications = [:]
        entry.medications?
            .filter { $0.taken == true }
            .forEach { med in
                if let userMed = userMedications.first(where: { $0.name == med.name }),
                   let userMedId = userMed.id {
                    takenMedications[userMedId] = med.timestamp ?? Date()
                }
            }

        // Load substances from entry
        takenSubstances = entry.substances?.compactMap { sub -> SubstanceEntry? in
            guard let userSub = userSubstances.first(where: { $0.name == sub.name }),
                  let subId = userSub.id
            else { return nil }
            let amountStr = sub.amount.map { String(format: "%.1f", $0) } ?? "1"
            return SubstanceEntry(
                id: UUID(),
                userSubstanceId: subId,
                amount: amountStr,
                unit: sub.unit ?? .other,
                timestamp: sub.timestamp ?? Date()
            )
        } ?? []

        // Load logs for date (mindfulness and self-care)
        loadLogsForDate()
    }

    // MARK: - Medication Actions

    func toggleMedication(_ medication: UserMedication) {
        guard let medId = medication.id else { return }
        if takenMedications[medId] != nil {
            takenMedications.removeValue(forKey: medId)
        } else {
            takenMedications[medId] = Date()
        }
    }

    func removeMedication(_ medication: UserMedication) {
        guard let medId = medication.id else { return }
        takenMedications.removeValue(forKey: medId)
    }

    func updateMedicationTime(_ medication: UserMedication, time: Date) {
        guard let medId = medication.id else { return }
        takenMedications[medId] = time
    }

    // MARK: - Substance Actions

    func addSubstance(_ substance: UserSubstance, amount: String) {
        guard let subId = substance.id else { return }
        let entry = SubstanceEntry(
            id: UUID(),
            userSubstanceId: subId,
            amount: amount,
            unit: substance.defaultUnit ?? .other,
            timestamp: Date()
        )
        takenSubstances.append(entry)
    }

    func removeSubstance(_ entry: SubstanceEntry) {
        takenSubstances.removeAll { $0.id == entry.id }
    }

    func updateSubstanceTime(_ entry: SubstanceEntry, time: Date) {
        if let index = takenSubstances.firstIndex(where: { $0.id == entry.id }) {
            takenSubstances[index].timestamp = time
        }
    }

    func updateSubstanceAmount(_ entry: SubstanceEntry, amount: String) {
        if let index = takenSubstances.firstIndex(where: { $0.id == entry.id }) {
            takenSubstances[index].amount = amount
        }
    }

    // MARK: - Mindfulness Actions

    func addMindfulness(_ practice: UserMindfulness) {
        guard let practiceId = practice.id else { return }
        let entry = MindfulnessLogEntry(
            id: UUID(),
            userMindfulnessId: practiceId,
            timestamp: Date()
        )
        loggedMindfulness.append(entry)
    }

    func removeMindfulness(_ entry: MindfulnessLogEntry) {
        loggedMindfulness.removeAll { $0.id == entry.id }
    }

    func updateMindfulnessTime(_ entry: MindfulnessLogEntry, time: Date) {
        if let index = loggedMindfulness.firstIndex(where: { $0.id == entry.id }) {
            loggedMindfulness[index].timestamp = time
        }
    }

    // MARK: - Self-Care Actions

    func addSelfCare(_ practice: UserSelfCare) {
        guard let practiceId = practice.id else { return }
        let entry = SelfCareLogEntry(
            id: UUID(),
            userSelfCareId: practiceId,
            timeOfDay: practice.timeOfDay ?? .morning,
            timestamp: Date()
        )
        loggedSelfCare.append(entry)
    }

    func removeSelfCare(_ entry: SelfCareLogEntry) {
        loggedSelfCare.removeAll { $0.id == entry.id }
    }

    func updateSelfCareTime(_ entry: SelfCareLogEntry, time: Date) {
        if let index = loggedSelfCare.firstIndex(where: { $0.id == entry.id }) {
            loggedSelfCare[index].timestamp = time
        }
    }

    // MARK: - Save Entry

    func saveEntry() throws {
        guard let modelContext else {
            throw EntryError.noModelContext
        }

        if hasEntryForSelectedDate && entryToEdit == nil {
            showingDuplicateAlert = true
            return
        }

        if let existingEntry = entryToEdit {
            try updateEntry(existingEntry, context: modelContext)
        } else {
            try createEntry(context: modelContext)
        }
    }

    private func createEntry(context: ModelContext) throws {
        let calendar = Calendar.current
        let endOfDay = calendar.date(
            bySettingHour: 23, minute: 59, second: 59, of: selectedDate
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
            notes: notes.isEmpty ? nil : notes,
            selectedEmotions: selectedEmotions.isEmpty ? nil : selectedEmotions.map { $0.rawValue }
        )

        // Create medications
        let meds = takenMedications.compactMap { (id, timestamp) -> Medication? in
            guard let userMed = userMedications.first(where: { $0.id == id }) else { return nil }
            return Medication(
                name: userMed.name ?? "",
                dosage: userMed.dosage,
                timestamp: timestamp,
                taken: true,
                notes: ""
            )
        }

        // Create substances
        let subs = takenSubstances.compactMap { subEntry -> Substance? in
            guard let userSub = userSubstances.first(where: { $0.id == subEntry.userSubstanceId }) else { return nil }
            return Substance(
                name: userSub.name ?? "",
                amount: Double(subEntry.amount),
                unit: subEntry.unit,
                timestamp: subEntry.timestamp
            )
        }

        entry.medications = meds
        entry.substances = subs
        meds.forEach { $0.symptomEntry = entry }
        subs.forEach { $0.symptomEntry = entry }

        context.insert(entry)
        meds.forEach { context.insert($0) }
        subs.forEach { context.insert($0) }

        // Create mindfulness logs
        for mindfulnessEntry in loggedMindfulness {
            guard let practice = userMindfulness.first(where: { $0.id == mindfulnessEntry.userMindfulnessId }) else { continue }
            let log = MindfulnessLog(
                userMindfulness: practice,
                practiceName: practice.name ?? "",
                timestamp: mindfulnessEntry.timestamp
            )
            context.insert(log)
        }

        // Create self-care logs
        for selfCareEntry in loggedSelfCare {
            guard let practice = userSelfCare.first(where: { $0.id == selfCareEntry.userSelfCareId }) else { continue }
            let log = SelfCareLog(
                userSelfCare: practice,
                practiceName: practice.name ?? "",
                timestamp: selfCareEntry.timestamp
            )
            context.insert(log)
        }

        // Sync to HealthKit
        syncToHealthKit(entry: entry)
    }

    private func updateEntry(_ entry: SymptomEntry, context: ModelContext) throws {
        let calendar = Calendar.current
        let endOfDay = calendar.date(
            bySettingHour: 23, minute: 59, second: 59, of: selectedDate
        ) ?? selectedDate

        entry.timestamp = endOfDay
        entry.moodLevel = moodLevel
        entry.anxietyLevel = anxietyLevel
        entry.anhedoniaLevel = anhedoniaLevel
        entry.sleepQualityRating = sleepQualityRating
        entry.sleepHours = Double(sleepHours)
        entry.timeInDaylightMinutes = Double(timeInDaylightMinutes)
        entry.exerciseMinutes = Double(exerciseMinutes)
        entry.notes = notes.isEmpty ? nil : notes
        entry.selectedEmotions = selectedEmotions.isEmpty ? nil : selectedEmotions.map { $0.rawValue }

        // Delete old medications and substances
        entry.medications?.forEach { context.delete($0) }
        entry.substances?.forEach { context.delete($0) }

        // Create new medications
        let meds = takenMedications.compactMap { (id, timestamp) -> Medication? in
            guard let userMed = userMedications.first(where: { $0.id == id }) else { return nil }
            return Medication(
                name: userMed.name ?? "",
                dosage: userMed.dosage,
                timestamp: timestamp,
                taken: true,
                notes: ""
            )
        }

        // Create new substances
        let subs = takenSubstances.compactMap { subEntry -> Substance? in
            guard let userSub = userSubstances.first(where: { $0.id == subEntry.userSubstanceId }) else { return nil }
            return Substance(
                name: userSub.name ?? "",
                amount: Double(subEntry.amount),
                unit: subEntry.unit,
                timestamp: subEntry.timestamp
            )
        }

        entry.medications = meds
        entry.substances = subs
        meds.forEach { $0.symptomEntry = entry }
        subs.forEach { $0.symptomEntry = entry }

        meds.forEach { context.insert($0) }
        subs.forEach { context.insert($0) }

        // Delete old logs for the same day and create new ones
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Delete and recreate mindfulness logs
        for log in allMindfulnessLogs {
            guard let timestamp = log.timestamp,
                  timestamp >= startOfDay && timestamp < nextDay
            else { continue }
            context.delete(log)
        }
        for mindfulnessEntry in loggedMindfulness {
            guard let practice = userMindfulness.first(where: { $0.id == mindfulnessEntry.userMindfulnessId }) else { continue }
            let log = MindfulnessLog(
                userMindfulness: practice,
                practiceName: practice.name ?? "",
                timestamp: mindfulnessEntry.timestamp
            )
            context.insert(log)
        }

        // Delete and recreate self-care logs
        for log in allSelfCareLogs {
            guard let timestamp = log.timestamp,
                  timestamp >= startOfDay && timestamp < nextDay
            else { continue }
            context.delete(log)
        }
        for selfCareEntry in loggedSelfCare {
            guard let practice = userSelfCare.first(where: { $0.id == selfCareEntry.userSelfCareId }) else { continue }
            let log = SelfCareLog(
                userSelfCare: practice,
                practiceName: practice.name ?? "",
                timestamp: selfCareEntry.timestamp
            )
            context.insert(log)
        }

        // Sync to HealthKit
        syncToHealthKit(entry: entry)
    }

    private func syncToHealthKit(entry: SymptomEntry) {
        guard healthKitManager.isAuthorized, let mood = entry.moodLevel else { return }

        Task {
            if #available(iOS 18.0, *) {
                try? await healthKitManager.saveStateOfMind(
                    valence: mood.stateOfMindValence,
                    kind: .dailyMood,
                    labels: mood.stateOfMindLabels,
                    date: entry.timestamp ?? Date()
                )
            }
        }
    }
}

// MARK: - Errors

enum EntryError: LocalizedError {
    case noModelContext
    case duplicateEntry

    var errorDescription: String? {
        switch self {
        case .noModelContext:
            return "Unable to save entry. Please try again."
        case .duplicateEntry:
            return "An entry already exists for this date."
        }
    }
}

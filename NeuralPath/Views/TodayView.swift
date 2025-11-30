//
//  TodayView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]
    @Query(filter: #Predicate<UserMedication> { $0.isActive == true },
           sort: \UserMedication.name) private var userMedications: [UserMedication]
    @Query(filter: #Predicate<UserSubstance> { $0.isActive == true },
           sort: \UserSubstance.name) private var userSubstances: [UserSubstance]
    @Query(filter: #Predicate<UserMindfulness> { $0.isActive == true },
           sort: \UserMindfulness.name) private var userMindfulness: [UserMindfulness]
    @Query(filter: #Predicate<UserSelfCare> { $0.isActive == true },
           sort: \UserSelfCare.name) private var userSelfCare: [UserSelfCare]
    @Query(sort: \MedicationLog.timestamp) private var allMedicationLogs: [MedicationLog]
    @Query(sort: \SubstanceLog.timestamp) private var allSubstanceLogs: [SubstanceLog]
    @Query(sort: \MindfulnessLog.timestamp) private var allMindfulnessLogs: [MindfulnessLog]
    @Query(sort: \SelfCareLog.timestamp) private var allSelfCareLogs: [SelfCareLog]

    @State private var showingAddEntry = false
    @State private var showingEditEntry = false
    @State private var showingArchive = false
    @State private var showingSettings = false
    @State private var substanceToLog: UserSubstance?
    @State private var substanceAmount: String = "1"

    // Edit states
    @State private var medicationLogToEditTime: MedicationLog?
    @State private var medicationToEditTime: UserMedication?
    @State private var substanceLogToEditTime: SubstanceLog?
    @State private var substanceLogToEditAmount: SubstanceLog?
    @State private var mindfulnessLogToEditTime: MindfulnessLog?
    @State private var selfCareLogToEditTime: SelfCareLog?
    @State private var editTime: Date = Date()
    @State private var editAmount: String = ""

    // Completion celebration states
    @State private var showMorningCompletion = false
    @State private var showAfternoonCompletion = false
    @State private var showEveningCompletion = false
    @State private var completedTimeOfDay: SelfCareTimeOfDay?

    private var scheduledMedications: [UserMedication] {
        userMedications.filter { $0.frequency != .asNeeded }
    }

    private var prnMedications: [UserMedication] {
        userMedications.filter { $0.frequency == .asNeeded }
    }

    private var todayPrnLogs: [MedicationLog] {
        let prnMedicationNames = Set(prnMedications.compactMap { $0.name })
        return todayMedicationLogs.filter { log in
            guard let name = log.medicationName else { return false }
            return prnMedicationNames.contains(name)
        }.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    private var todayEntry: SymptomEntry? {
        let calendar = Calendar.current
        return entries.first { entry in
            guard let timestamp = entry.timestamp else { return false }
            return calendar.isDateInToday(timestamp)
        }
    }

    private var todayMedicationLogs: [MedicationLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return allMedicationLogs.filter { log in
            guard let timestamp = log.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay
        }
    }

    private var todaySubstanceLogs: [SubstanceLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return allSubstanceLogs.filter { log in
            guard let timestamp = log.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay
        }.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    private var todayMindfulnessLogs: [MindfulnessLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return allMindfulnessLogs.filter { log in
            guard let timestamp = log.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay
        }.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    private var todaySelfCareLogs: [SelfCareLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return allSelfCareLogs.filter { log in
            guard let timestamp = log.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay
        }.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    // Self-care practices by time of day
    private var morningSelfCare: [UserSelfCare] {
        userSelfCare.filter { $0.timeOfDay == .morning }
    }

    private var afternoonSelfCare: [UserSelfCare] {
        userSelfCare.filter { $0.timeOfDay == .afternoon }
    }

    private var eveningSelfCare: [UserSelfCare] {
        userSelfCare.filter { $0.timeOfDay == .evening }
    }

    // Today's self-care logs by time of day
    private var todayMorningSelfCareLogs: [SelfCareLog] {
        todaySelfCareLogs.filter { $0.timeOfDay == .morning }
    }

    private var todayAfternoonSelfCareLogs: [SelfCareLog] {
        todaySelfCareLogs.filter { $0.timeOfDay == .afternoon }
    }

    private var todayEveningSelfCareLogs: [SelfCareLog] {
        todaySelfCareLogs.filter { $0.timeOfDay == .evening }
    }

    private func medicationStatus(_ medication: UserMedication) -> (taken: Bool, time: Date?) {
        let log = todayMedicationLogs.first { $0.medicationName == medication.name }
        return (log != nil, log?.timestamp)
    }

    private var medicationsTakenCount: Int {
        scheduledMedications.filter { medicationStatus($0).taken }.count
    }

    private func logMedication(_ medication: UserMedication) {
        let log = MedicationLog(
            userMedication: medication,
            medicationName: medication.name ?? "",
            timestamp: Date()
        )
        modelContext.insert(log)
    }

    private func promptLogSubstance(_ substance: UserSubstance) {
        substanceAmount = "1"
        substanceToLog = substance
    }

    private func confirmLogSubstance() {
        guard let substance = substanceToLog,
              let amount = Double(substanceAmount), amount > 0 else { return }

        let log = SubstanceLog(
            userSubstance: substance,
            substanceName: substance.name ?? "",
            amount: amount,
            unit: substance.defaultUnit ?? .other,
            timestamp: Date()
        )
        modelContext.insert(log)
        substanceToLog = nil
    }

    private func deleteMedicationLog(_ log: MedicationLog) {
        modelContext.delete(log)
    }

    private func untickMedication(_ medication: UserMedication) {
        if let log = todayMedicationLogs.first(where: { $0.medicationName == medication.name }) {
            modelContext.delete(log)
        }
    }

    private func deleteSubstanceLog(_ log: SubstanceLog) {
        modelContext.delete(log)
    }

    private func startEditMedicationLogTime(_ log: MedicationLog) {
        editTime = log.timestamp ?? Date()
        medicationLogToEditTime = log
    }

    private func startEditScheduledMedicationTime(_ medication: UserMedication) {
        if let log = todayMedicationLogs.first(where: { $0.medicationName == medication.name }) {
            editTime = log.timestamp ?? Date()
            medicationToEditTime = medication
        }
    }

    private func saveMedicationLogTime() {
        if let log = medicationLogToEditTime {
            log.timestamp = editTime
        }
        medicationLogToEditTime = nil
    }

    private func saveScheduledMedicationTime() {
        if let medication = medicationToEditTime,
           let log = todayMedicationLogs.first(where: { $0.medicationName == medication.name }) {
            log.timestamp = editTime
        }
        medicationToEditTime = nil
    }

    private func startEditSubstanceTime(_ log: SubstanceLog) {
        editTime = log.timestamp ?? Date()
        substanceLogToEditTime = log
    }

    private func saveSubstanceTime() {
        if let log = substanceLogToEditTime {
            log.timestamp = editTime
        }
        substanceLogToEditTime = nil
    }

    private func startEditSubstanceAmount(_ log: SubstanceLog) {
        let amount = log.amount ?? 0
        editAmount = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", amount)
            : String(format: "%.1f", amount)
        substanceLogToEditAmount = log
    }

    private func saveSubstanceAmount() {
        if let log = substanceLogToEditAmount,
           let amount = Double(editAmount), amount > 0 {
            log.amount = amount
        }
        substanceLogToEditAmount = nil
    }

    private func logMindfulness(_ practice: UserMindfulness) {
        let log = MindfulnessLog(
            userMindfulness: practice,
            practiceName: practice.name ?? "",
            timestamp: Date()
        )
        modelContext.insert(log)
    }

    private func deleteMindfulnessLog(_ log: MindfulnessLog) {
        modelContext.delete(log)
    }

    private func startEditMindfulnessTime(_ log: MindfulnessLog) {
        editTime = log.timestamp ?? Date()
        mindfulnessLogToEditTime = log
    }

    private func saveMindfulnessTime() {
        if let log = mindfulnessLogToEditTime {
            log.timestamp = editTime
        }
        mindfulnessLogToEditTime = nil
    }

    // Self-care functions
    private func selfCareStatus(_ practice: UserSelfCare) -> (completed: Bool, time: Date?) {
        let log = todaySelfCareLogs.first { $0.userSelfCare?.id == practice.id }
        return (log != nil, log?.timestamp)
    }

    private func logSelfCare(_ practice: UserSelfCare) {
        let log = SelfCareLog(
            userSelfCare: practice,
            practiceName: practice.name ?? "",
            timeOfDay: practice.timeOfDay,
            timestamp: Date()
        )
        modelContext.insert(log)

        // Check for completion after logging
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            checkForCategoryCompletion(practice.timeOfDay)
        }
    }

    private func deleteSelfCareLog(_ log: SelfCareLog) {
        modelContext.delete(log)
    }

    private func startEditSelfCareTime(_ log: SelfCareLog) {
        editTime = log.timestamp ?? Date()
        selfCareLogToEditTime = log
    }

    private func saveSelfCareTime() {
        if let log = selfCareLogToEditTime {
            log.timestamp = editTime
        }
        selfCareLogToEditTime = nil
    }

    private func selfCareSummary(for timeOfDay: SelfCareTimeOfDay) -> String {
        let practices: [UserSelfCare]
        let logs: [SelfCareLog]

        switch timeOfDay {
        case .morning:
            practices = morningSelfCare
            logs = todayMorningSelfCareLogs
        case .afternoon:
            practices = afternoonSelfCare
            logs = todayAfternoonSelfCareLogs
        case .evening:
            practices = eveningSelfCare
            logs = todayEveningSelfCareLogs
        }

        if practices.isEmpty {
            return "None"
        }

        let completed = practices.filter { practice in
            logs.contains { $0.userSelfCare?.id == practice.id }
        }.count

        return "\(completed)/\(practices.count)"
    }

    private func isCategoryComplete(_ timeOfDay: SelfCareTimeOfDay) -> Bool {
        let practices: [UserSelfCare]
        let logs: [SelfCareLog]

        switch timeOfDay {
        case .morning:
            practices = morningSelfCare
            logs = todayMorningSelfCareLogs
        case .afternoon:
            practices = afternoonSelfCare
            logs = todayAfternoonSelfCareLogs
        case .evening:
            practices = eveningSelfCare
            logs = todayEveningSelfCareLogs
        }

        guard !practices.isEmpty else { return false }

        let completed = practices.filter { practice in
            logs.contains { $0.userSelfCare?.id == practice.id }
        }.count

        return completed == practices.count
    }

    private func checkForCategoryCompletion(_ timeOfDay: SelfCareTimeOfDay) {
        guard isCategoryComplete(timeOfDay) else { return }
        completedTimeOfDay = timeOfDay
    }

    private var medicationsSummary: String {
        if scheduledMedications.isEmpty {
            let prnCount = todayPrnLogs.count
            return prnCount == 0 ? "None today" : "\(prnCount) dose\(prnCount == 1 ? "" : "s")"
        } else {
            let prnCount = todayPrnLogs.count
            let prnSuffix = prnCount > 0 ? " + \(prnCount) PRN" : ""
            return "\(medicationsTakenCount)/\(scheduledMedications.count)\(prnSuffix)"
        }
    }

    private var substancesSummary: String {
        if todaySubstanceLogs.isEmpty {
            return "None today"
        }
        return "\(todaySubstanceLogs.count) log\(todaySubstanceLogs.count == 1 ? "" : "s")"
    }

    private var mindfulnessSummary: String {
        if todayMindfulnessLogs.isEmpty {
            return "None today"
        }
        return "\(todayMindfulnessLogs.count) session\(todayMindfulnessLogs.count == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationStack {
            List {
                if let entry = todayEntry {
                    // All Done Card - hides tracking sections
                    Section {
                        AllDoneCard(entry: entry, onEdit: { showingEditEntry = true })
                    }
                } else {
                    // Log Today's Entry button
                    Section {
                        Button(action: { showingAddEntry = true }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Log Today's Entry")
                                        .font(.headline)
                                    Text("Track your mood, sleep & symptoms")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Morning Self-Care Section
                    if !morningSelfCare.isEmpty {
                        selfCareSection(for: .morning, practices: morningSelfCare, logs: todayMorningSelfCareLogs)
                    }

                    // Afternoon Self-Care Section
                    if !afternoonSelfCare.isEmpty {
                        selfCareSection(for: .afternoon, practices: afternoonSelfCare, logs: todayAfternoonSelfCareLogs)
                    }

                    // Evening Self-Care Section
                    if !eveningSelfCare.isEmpty {
                        selfCareSection(for: .evening, practices: eveningSelfCare, logs: todayEveningSelfCareLogs)
                    }

                    // Medications Section
                    if !scheduledMedications.isEmpty || !prnMedications.isEmpty {
                    Section {
                        // Scheduled medications
                        ForEach(scheduledMedications) { medication in
                            let status = medicationStatus(medication)
                            ScheduledMedicationRow(
                                medication: medication,
                                taken: status.taken,
                                time: status.time,
                                onToggle: { logMedication(medication) }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if status.taken {
                                    Button {
                                        untickMedication(medication)
                                    } label: {
                                        Label("Undo", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.orange)

                                    Button {
                                        startEditScheduledMedicationTime(medication)
                                    } label: {
                                        Label("Time", systemImage: "clock")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }

                        // PRN logs
                        ForEach(todayPrnLogs) { log in
                            PrnLogRow(log: log)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteMedicationLog(log)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        startEditMedicationLogTime(log)
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
                                        logMedication(medication)
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
                }

                // Substances Section
                if !userSubstances.isEmpty || !todaySubstanceLogs.isEmpty {
                    Section {
                        ForEach(todaySubstanceLogs) { log in
                            SubstanceLogRow(log: log)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteSubstanceLog(log)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        startEditSubstanceTime(log)
                                    } label: {
                                        Label("Time", systemImage: "clock")
                                    }
                                    .tint(.blue)

                                    Button {
                                        startEditSubstanceAmount(log)
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
                                        promptLogSubstance(substance)
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
                }

                // Mindfulness Section
                if !userMindfulness.isEmpty || !todayMindfulnessLogs.isEmpty {
                    Section {
                        ForEach(todayMindfulnessLogs) { log in
                            MindfulnessLogRow(log: log)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteMindfulnessLog(log)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        startEditMindfulnessTime(log)
                                    } label: {
                                        Label("Time", systemImage: "clock")
                                    }
                                    .tint(.blue)
                                }
                        }

                        if !userMindfulness.isEmpty {
                            Menu {
                                ForEach(userMindfulness) { practice in
                                    Button {
                                        logMindfulness(practice)
                                    } label: {
                                        Label(practice.name ?? "Unknown", systemImage: practice.category?.icon ?? "brain.head.profile")
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("Log Practice")
                                        .foregroundStyle(.blue)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Label("Mindfulness", systemImage: "brain.head.profile")
                            Spacer()
                            Text(mindfulnessSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                } // end else (no todayEntry)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingArchive = true
                        } label: {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }

                        Button {
                            showingAddEntry = true
                        } label: {
                            Label("Add Entry", systemImage: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddSymptomView()
            }
            .sheet(isPresented: $showingEditEntry) {
                if let entry = todayEntry {
                    AddSymptomView(entryToEdit: entry)
                }
            }
            .sheet(isPresented: $showingArchive) {
                ArchiveView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Log Substance", isPresented: Binding(
                get: { substanceToLog != nil },
                set: { if !$0 { substanceToLog = nil } }
            )) {
                TextField("Amount", text: $substanceAmount)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) {
                    substanceToLog = nil
                }
                Button("Log") {
                    confirmLogSubstance()
                }
            } message: {
                if let substance = substanceToLog {
                    Text("\(substance.name ?? "Unknown") (\(substance.defaultUnit?.abbreviation ?? ""))")
                }
            }
            // Edit time for PRN medication log
            .sheet(isPresented: Binding(
                get: { medicationLogToEditTime != nil },
                set: { if !$0 { medicationLogToEditTime = nil } }
            )) {
                if let log = medicationLogToEditTime {
                    EditTimeSheet(
                        title: "Edit Time",
                        subtitle: log.medicationName ?? "Medication",
                        time: $editTime,
                        onSave: saveMedicationLogTime,
                        onCancel: { medicationLogToEditTime = nil }
                    )
                }
            }
            // Edit time for scheduled medication
            .sheet(isPresented: Binding(
                get: { medicationToEditTime != nil },
                set: { if !$0 { medicationToEditTime = nil } }
            )) {
                if let medication = medicationToEditTime {
                    EditTimeSheet(
                        title: "Edit Time",
                        subtitle: medication.name ?? "Medication",
                        time: $editTime,
                        onSave: saveScheduledMedicationTime,
                        onCancel: { medicationToEditTime = nil }
                    )
                }
            }
            // Edit time for substance log
            .sheet(isPresented: Binding(
                get: { substanceLogToEditTime != nil },
                set: { if !$0 { substanceLogToEditTime = nil } }
            )) {
                if let log = substanceLogToEditTime {
                    EditTimeSheet(
                        title: "Edit Time",
                        subtitle: log.substanceName ?? "Substance",
                        time: $editTime,
                        onSave: saveSubstanceTime,
                        onCancel: { substanceLogToEditTime = nil }
                    )
                }
            }
            // Edit amount for substance log
            .alert("Edit Amount", isPresented: Binding(
                get: { substanceLogToEditAmount != nil },
                set: { if !$0 { substanceLogToEditAmount = nil } }
            )) {
                TextField("Amount", text: $editAmount)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) {
                    substanceLogToEditAmount = nil
                }
                Button("Save") {
                    saveSubstanceAmount()
                }
            } message: {
                if let log = substanceLogToEditAmount {
                    Text("\(log.substanceName ?? "Unknown") (\(log.unit?.abbreviation ?? ""))")
                }
            }
            // Edit time for mindfulness log
            .sheet(isPresented: Binding(
                get: { mindfulnessLogToEditTime != nil },
                set: { if !$0 { mindfulnessLogToEditTime = nil } }
            )) {
                if let log = mindfulnessLogToEditTime {
                    EditTimeSheet(
                        title: "Edit Time",
                        subtitle: log.practiceName ?? "Practice",
                        time: $editTime,
                        onSave: saveMindfulnessTime,
                        onCancel: { mindfulnessLogToEditTime = nil }
                    )
                }
            }
            // Edit time for self-care log
            .sheet(isPresented: Binding(
                get: { selfCareLogToEditTime != nil },
                set: { if !$0 { selfCareLogToEditTime = nil } }
            )) {
                if let log = selfCareLogToEditTime {
                    EditTimeSheet(
                        title: "Edit Time",
                        subtitle: log.practiceName ?? "Practice",
                        time: $editTime,
                        onSave: saveSelfCareTime,
                        onCancel: { selfCareLogToEditTime = nil }
                    )
                }
            }
            // Self-care completion celebration
            .alert("Well Done!", isPresented: Binding(
                get: { completedTimeOfDay != nil },
                set: { if !$0 { completedTimeOfDay = nil } }
            )) {
                Button("OK") {
                    completedTimeOfDay = nil
                }
            } message: {
                if let timeOfDay = completedTimeOfDay {
                    Text(timeOfDay.completionMessage)
                }
            }
        }
    }

    @ViewBuilder
    private func selfCareSection(for timeOfDay: SelfCareTimeOfDay, practices: [UserSelfCare], logs: [SelfCareLog]) -> some View {
        Section {
            ForEach(practices) { practice in
                let status = selfCareStatus(practice)
                TodaySelfCareRow(
                    practice: practice,
                    completed: status.completed,
                    time: status.time,
                    onToggle: { logSelfCare(practice) }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if status.completed {
                        if let log = todaySelfCareLogs.first(where: { $0.userSelfCare?.id == practice.id }) {
                            Button(role: .destructive) {
                                deleteSelfCareLog(log)
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.orange)

                            Button {
                                startEditSelfCareTime(log)
                            } label: {
                                Label("Time", systemImage: "clock")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }

            // Log Practice menu for practices not yet logged
            let unloggedPractices = practices.filter { practice in
                !logs.contains { $0.userSelfCare?.id == practice.id }
            }
            if !unloggedPractices.isEmpty {
                Menu {
                    ForEach(unloggedPractices) { practice in
                        Button {
                            logSelfCare(practice)
                        } label: {
                            Label(practice.name ?? "Unknown", systemImage: timeOfDay.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Log Practice")
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
            }
        } header: {
            HStack {
                Label("\(timeOfDay.displayName) Self-Care", systemImage: timeOfDay.icon)
                    .foregroundStyle(timeOfDay.color)
                Spacer()
                Text(selfCareSummary(for: timeOfDay))
                    .font(.subheadline)
                    .foregroundStyle(isCategoryComplete(timeOfDay) ? .green : .secondary)
            }
        }
    }
}

// MARK: - All Done Card

private struct AllDoneCard: View {
    let entry: SymptomEntry
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("All done for today!")
                    .font(.title2.bold())
            }

            VStack(spacing: 12) {
                if let mood = entry.moodLevel {
                    HStack {
                        Text(mood.emoji)
                            .font(.title)
                        Text(mood.displayName)
                            .font(.headline)
                        Spacer()
                    }
                }

                if let anxiety = entry.anxietyLevel, anxiety != .none {
                    HStack {
                        Label("Anxiety", systemImage: "brain.head.profile")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(anxiety.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(anxietyColor(anxiety).opacity(0.2))
                            .foregroundStyle(anxietyColor(anxiety))
                            .clipShape(Capsule())
                    }
                }

                if let anhedonia = entry.anhedoniaLevel, anhedonia != .none {
                    HStack {
                        Label("Anhedonia", systemImage: "sparkles")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(anhedonia.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }

                if entry.sleepHours != nil || entry.exerciseMinutes != nil || entry.timeInDaylightMinutes != nil {
                    Divider()

                    HStack(spacing: 20) {
                        if let sleep = entry.sleepHours {
                            VStack(spacing: 4) {
                                Image(systemName: "moon.zzz.fill")
                                    .foregroundStyle(.indigo)
                                Text(String(format: "%.1fh", sleep))
                                    .font(.subheadline.bold())
                            }
                        }
                        if let exercise = entry.exerciseMinutes {
                            VStack(spacing: 4) {
                                Image(systemName: "figure.run")
                                    .foregroundStyle(.green)
                                Text("\(Int(exercise))m")
                                    .font(.subheadline.bold())
                            }
                        }
                        if let daylight = entry.timeInDaylightMinutes {
                            VStack(spacing: 4) {
                                Image(systemName: "sun.max.fill")
                                    .foregroundStyle(.orange)
                                Text("\(Int(daylight))m")
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Button(action: onEdit) {
                Label("Edit Entry", systemImage: "pencil")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func anxietyColor(_ level: AnxietyLevel) -> Color {
        switch level {
        case .none: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        case .extreme: return .purple
        }
    }
}

// MARK: - Today Entry Row

private struct TodayEntryRow: View {
    let entry: SymptomEntry
    let onEditTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                if let mood = entry.moodLevel {
                    VStack {
                        Text(mood.emoji)
                            .font(.title)
                        Text(mood.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let anxiety = entry.anxietyLevel, anxiety != .none {
                    statusBadge(
                        title: "Anxiety",
                        value: anxiety.displayName,
                        color: anxietyColor(anxiety)
                    )
                }

                if let anhedonia = entry.anhedoniaLevel, anhedonia != .none {
                    statusBadge(
                        title: "Anhedonia",
                        value: anhedonia.displayName,
                        color: .purple
                    )
                }

                Button("Edit", action: onEditTap)
                    .font(.subheadline)
            }

            if entry.sleepHours != nil || entry.exerciseMinutes != nil || entry.timeInDaylightMinutes != nil {
                Divider()

                HStack(spacing: 16) {
                    if let sleep = entry.sleepHours {
                        metricView(icon: "moon.zzz", value: String(format: "%.1fh", sleep))
                    }
                    if let exercise = entry.exerciseMinutes {
                        metricView(icon: "figure.run", value: "\(Int(exercise))m")
                    }
                    if let daylight = entry.timeInDaylightMinutes {
                        metricView(icon: "sun.max", value: "\(Int(daylight))m")
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.2))
                .foregroundStyle(color)
                .clipShape(Capsule())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func metricView(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.caption)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func anxietyColor(_ level: AnxietyLevel) -> Color {
        switch level {
        case .none: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        case .extreme: return .purple
        }
    }
}

// MARK: - Scheduled Medication Row

private struct ScheduledMedicationRow: View {
    let medication: UserMedication
    let taken: Bool
    let time: Date?
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

// MARK: - PRN Log Row

private struct PrnLogRow: View {
    let log: MedicationLog

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
                Text(log.medicationName ?? "Unknown")
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

            if let time = log.timestamp {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Substance Log Row

private struct SubstanceLogRow: View {
    let log: SubstanceLog

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    private var formattedAmount: String {
        let amount = log.amount ?? 0
        let unit = log.unit ?? .other
        let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", amount)
            : String(format: "%.1f", amount)
        return "\(formattedAmount) \(unit.abbreviation)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            Text(log.substanceName ?? "Unknown")
                .font(.subheadline)

            Spacer()

            Text(formattedAmount)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let time = log.timestamp {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Mindfulness Log Row

private struct MindfulnessLogRow: View {
    let log: MindfulnessLog

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

            Text(log.practiceName ?? "Unknown")
                .font(.subheadline)

            Spacer()

            if let time = log.timestamp {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Self-Care Row

private struct TodaySelfCareRow: View {
    let practice: UserSelfCare
    let completed: Bool
    let time: Date?
    let onToggle: () -> Void

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(completed ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(completed)

            Text(practice.name ?? "Unknown")
                .font(.subheadline)

            Spacer()

            if let time = time {
                Text(timeFormatter.string(from: time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Edit Time Sheet

private struct EditTimeSheet: View {
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

#Preview {
    TodayView()
        .modelContainer(for: [SymptomEntry.self, UserMedication.self, UserSubstance.self, UserMindfulness.self, UserSelfCare.self, MedicationLog.self, SubstanceLog.self, MindfulnessLog.self, SelfCareLog.self], inMemory: true)
}

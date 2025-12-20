//
//  TodayView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    // Haptic generators
    private let successFeedback = UINotificationFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
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

    // Completion celebration
    @State private var completedTimeOfDay: SelfCareTimeOfDay?

    // MARK: - Computed Properties

    private var scheduledMedications: [UserMedication] {
        userMedications.filter { $0.frequency != .asNeeded }
    }

    private var prnMedications: [UserMedication] {
        userMedications.filter { $0.frequency == .asNeeded }
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
        }
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
        }
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
        }
    }

    private var showFinishDayButton: Bool {
        todayEntry == nil
    }

    // MARK: - Timeline Building

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []

        // Scheduled medications
        for med in scheduledMedications {
            let log = todayMedicationLogs.first { $0.medicationName == med.name }
            let plannedTime = med.reminderTime ?? TimeBlock.from(date: Date()).defaultTime
            items.append(TimelineItem(
                id: "med_\(med.id)",
                type: .scheduledMedication(med),
                name: med.name ?? "Unknown",
                time: log?.timestamp ?? plannedTime,
                plannedTime: plannedTime,
                isCompleted: log != nil,
                subtitle: med.dosage
            ))
        }

        // PRN medication logs
        let prnMedicationNames = Set(prnMedications.compactMap { $0.name })
        for log in todayMedicationLogs {
            guard let name = log.medicationName, prnMedicationNames.contains(name) else { continue }
            items.append(TimelineItem(
                id: "prn_\(log.id)",
                type: .prnMedication(log),
                name: name,
                time: log.timestamp ?? Date(),
                plannedTime: nil,
                isCompleted: true,
                subtitle: nil
            ))
        }

        // Substance logs
        for log in todaySubstanceLogs {
            let amount = log.amount ?? 0
            let unit = log.unit ?? .other
            let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", amount)
                : String(format: "%.1f", amount)
            items.append(TimelineItem(
                id: "sub_\(log.id)",
                type: .substance(log),
                name: log.substanceName ?? "Unknown",
                time: log.timestamp ?? Date(),
                plannedTime: nil,
                isCompleted: true,
                subtitle: "\(formattedAmount) \(unit.abbreviation)"
            ))
        }

        // Mindfulness logs
        for log in todayMindfulnessLogs {
            items.append(TimelineItem(
                id: "mind_\(log.id)",
                type: .mindfulness(log),
                name: log.practiceName ?? "Unknown",
                time: log.timestamp ?? Date(),
                plannedTime: nil,
                isCompleted: true,
                subtitle: isGuidedPractice(log) ? "Guided" : nil
            ))
        }

        // Self-care (scheduled and logged)
        for practice in userSelfCare {
            let log = todaySelfCareLogs.first { $0.userSelfCare?.id == practice.id }
            let plannedTime = practice.timeOfDay.defaultTime
            items.append(TimelineItem(
                id: "selfcare_\(practice.id)",
                type: log != nil ? .loggedSelfCare(log!) : .scheduledSelfCare(practice),
                name: practice.name ?? "Unknown",
                time: log?.timestamp ?? plannedTime,
                plannedTime: plannedTime,
                isCompleted: log != nil,
                subtitle: practice.timeOfDay.displayName
            ))
        }

        return items.sorted { $0.effectiveTime < $1.effectiveTime }
    }

    private var timelineSections: [TimeBlockSection] {
        let grouped = Dictionary(grouping: timelineItems) { $0.timeBlock }
        return TimeBlock.allCases.compactMap { block in
            guard let items = grouped[block], !items.isEmpty else { return nil }
            return TimeBlockSection(block: block, items: items)
        }
    }

    private func isGuidedPractice(_ log: MindfulnessLog) -> Bool {
        guard let notes = log.notes else { return false }
        return GuidedPracticeLogMetadata.from(json: notes) != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header card if entry exists
                        if let entry = todayEntry {
                            AllDoneCard(entry: entry, onEdit: { showingEditEntry = true })
                                .padding()
                        }

                        // Timeline sections
                        if timelineSections.isEmpty && todayEntry == nil {
                            EmptyTimelineView()
                        } else {
                            ForEach(timelineSections) { section in
                                timelineSection(section)
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timelineItems.map { "\($0.id)_\($0.time.timeIntervalSince1970)" })
                        }

                        // Finish Day button
                        if showFinishDayButton {
                            FinishDayButton(action: { showingAddEntry = true })
                                .padding(.top, 16)
                        }

                        // Bottom padding for FAB
                        Color.clear.frame(height: 80)
                    }
                }
                .background(Color(.systemGroupedBackground))

                // FAB
                AddItemFAB(
                    userSubstances: userSubstances,
                    userMindfulness: userMindfulness,
                    userSelfCare: userSelfCare.filter { practice in
                        !todaySelfCareLogs.contains { $0.userSelfCare?.id == practice.id }
                    },
                    prnMedications: prnMedications,
                    onLogSubstance: promptLogSubstance,
                    onLogMindfulness: logMindfulness,
                    onLogSelfCare: logSelfCare,
                    onLogPRN: logMedication
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingArchive = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
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
                StepperEntryView()
            }
            .sheet(isPresented: $showingEditEntry) {
                if let entry = todayEntry {
                    StepperEntryView(entryToEdit: entry)
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
            // Edit time sheets
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

    // MARK: - Timeline Section

    @ViewBuilder
    private func timelineSection(_ section: TimeBlockSection) -> some View {
        VStack(spacing: 0) {
            TimeBlockHeader(
                block: section.block,
                completedCount: section.items.filter(\.isCompleted).count,
                totalCount: section.items.count
            )

            ForEach(section.items) { item in
                let actions = swipeActions(for: item)
                if actions.isEmpty {
                    TimelineItemRow(item: item) {
                        handleItemTap(item)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                } else {
                    SwipeableTimelineItemRow(
                        item: item,
                        onTap: { handleItemTap(item) },
                        swipeActions: actions
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
        }
        .padding(.vertical, 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: section.items.map(\.id))
    }

    private func swipeActions(for item: TimelineItem) -> [SwipeAction] {
        var actions: [SwipeAction] = []

        switch item.type {
        case .scheduledMedication(let med):
            if item.isCompleted {
                actions.append(SwipeAction(
                    icon: "arrow.uturn.backward",
                    label: "Undo",
                    color: .orange,
                    action: { untickMedication(med) }
                ))
                actions.append(SwipeAction(
                    icon: "clock",
                    label: "Time",
                    color: .blue,
                    action: { startEditScheduledMedicationTime(med) }
                ))
            }

        case .prnMedication(let log):
            actions.append(SwipeAction(
                icon: "clock",
                label: "Time",
                color: .blue,
                action: { startEditMedicationLogTime(log) }
            ))
            actions.append(SwipeAction(
                icon: "trash",
                label: "Delete",
                color: .red,
                action: { deleteMedicationLog(log) }
            ))

        case .substance(let log):
            actions.append(SwipeAction(
                icon: "number",
                label: "Amount",
                color: .purple,
                action: { startEditSubstanceAmount(log) }
            ))
            actions.append(SwipeAction(
                icon: "clock",
                label: "Time",
                color: .blue,
                action: { startEditSubstanceTime(log) }
            ))
            actions.append(SwipeAction(
                icon: "trash",
                label: "Delete",
                color: .red,
                action: { deleteSubstanceLog(log) }
            ))

        case .mindfulness(let log):
            actions.append(SwipeAction(
                icon: "clock",
                label: "Time",
                color: .blue,
                action: { startEditMindfulnessTime(log) }
            ))
            actions.append(SwipeAction(
                icon: "trash",
                label: "Delete",
                color: .red,
                action: { deleteMindfulnessLog(log) }
            ))

        case .scheduledSelfCare:
            break

        case .loggedSelfCare(let log):
            actions.append(SwipeAction(
                icon: "clock",
                label: "Time",
                color: .blue,
                action: { startEditSelfCareTime(log) }
            ))
            actions.append(SwipeAction(
                icon: "arrow.uturn.backward",
                label: "Undo",
                color: .orange,
                action: { deleteSelfCareLog(log) }
            ))
        }

        return actions
    }

    private func handleItemTap(_ item: TimelineItem) {
        switch item.type {
        case .scheduledMedication(let med):
            if !item.isCompleted {
                logMedication(med)
            }
        case .scheduledSelfCare(let practice):
            logSelfCare(practice)
        default:
            break
        }
    }

    // MARK: - Logging Functions

    private func logMedication(_ medication: UserMedication) {
        let log = MedicationLog(
            userMedication: medication,
            medicationName: medication.name ?? "",
            timestamp: Date()
        )
        modelContext.insert(log)
        successFeedback.notificationOccurred(.success)
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
        successFeedback.notificationOccurred(.success)
    }

    private func logMindfulness(_ practice: UserMindfulness) {
        let log = MindfulnessLog(
            userMindfulness: practice,
            practiceName: practice.name ?? "",
            timestamp: Date()
        )
        modelContext.insert(log)
        successFeedback.notificationOccurred(.success)
    }

    private func logSelfCare(_ practice: UserSelfCare) {
        let log = SelfCareLog(
            userSelfCare: practice,
            practiceName: practice.name ?? "",
            timeOfDay: practice.timeOfDay,
            timestamp: Date()
        )
        modelContext.insert(log)
        successFeedback.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            checkForCategoryCompletion(practice.timeOfDay)
        }
    }

    // MARK: - Delete Functions

    private func deleteMedicationLog(_ log: MedicationLog) {
        modelContext.delete(log)
        impactFeedback.impactOccurred()
    }

    private func untickMedication(_ medication: UserMedication) {
        if let log = todayMedicationLogs.first(where: { $0.medicationName == medication.name }) {
            modelContext.delete(log)
            impactFeedback.impactOccurred()
        }
    }

    private func deleteSubstanceLog(_ log: SubstanceLog) {
        modelContext.delete(log)
        impactFeedback.impactOccurred()
    }

    private func deleteMindfulnessLog(_ log: MindfulnessLog) {
        modelContext.delete(log)
        impactFeedback.impactOccurred()
    }

    private func deleteSelfCareLog(_ log: SelfCareLog) {
        modelContext.delete(log)
        impactFeedback.impactOccurred()
    }

    // MARK: - Edit Functions

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
            impactFeedback.impactOccurred()
        }
        medicationLogToEditTime = nil
    }

    private func saveScheduledMedicationTime() {
        if let medication = medicationToEditTime,
           let log = todayMedicationLogs.first(where: { $0.medicationName == medication.name }) {
            log.timestamp = editTime
            impactFeedback.impactOccurred()
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
            impactFeedback.impactOccurred()
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
            impactFeedback.impactOccurred()
        }
        substanceLogToEditAmount = nil
    }

    private func startEditMindfulnessTime(_ log: MindfulnessLog) {
        editTime = log.timestamp ?? Date()
        mindfulnessLogToEditTime = log
    }

    private func saveMindfulnessTime() {
        if let log = mindfulnessLogToEditTime {
            log.timestamp = editTime
            impactFeedback.impactOccurred()
        }
        mindfulnessLogToEditTime = nil
    }

    private func startEditSelfCareTime(_ log: SelfCareLog) {
        editTime = log.timestamp ?? Date()
        selfCareLogToEditTime = log
    }

    private func saveSelfCareTime() {
        if let log = selfCareLogToEditTime {
            log.timestamp = editTime
            impactFeedback.impactOccurred()
        }
        selfCareLogToEditTime = nil
    }

    // MARK: - Self-Care Completion

    private func checkForCategoryCompletion(_ timeOfDay: SelfCareTimeOfDay) {
        let practicesForTimeOfDay = userSelfCare.filter { $0.timeOfDay == timeOfDay }
        guard !practicesForTimeOfDay.isEmpty else { return }

        let completedCount = practicesForTimeOfDay.filter { practice in
            todaySelfCareLogs.contains { $0.userSelfCare?.id == practice.id }
        }.count

        if completedCount == practicesForTimeOfDay.count {
            completedTimeOfDay = timeOfDay
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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

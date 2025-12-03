//
//  MedicationReminderService.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
class MedicationReminderService {
    static let shared = MedicationReminderService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderPrefix = "medicationReminder_"

    // UserDefaults keys for default times
    static let morningReminderTimeKey = "medicationMorningReminderTime"
    static let afternoonReminderTimeKey = "medicationAfternoonReminderTime"
    static let eveningReminderTimeKey = "medicationEveningReminderTime"

    private init() {}

    private struct MedicationData {
        let id: String
        let name: String
        let dosage: String?
    }

    func scheduleMedicationReminders(medications: [UserMedication]) {
        var morningMeds: [MedicationData] = []
        var afternoonMeds: [MedicationData] = []
        var eveningMeds: [MedicationData] = []
        var customMeds: [(MedicationData, Date)] = []

        for medication in medications {
            guard medication.reminderEnabled == true,
                  medication.isActive == true,
                  medication.frequency != .asNeeded, // PRN medications excluded
                  let name = medication.name else { continue }

            let data = MedicationData(
                id: medication.id?.uuidString ?? UUID().uuidString,
                name: name,
                dosage: medication.dosage
            )

            let timeOfDay = medication.timeOfDay ?? .morning

            switch timeOfDay {
            case .morning:
                morningMeds.append(data)
            case .afternoon:
                afternoonMeds.append(data)
            case .evening:
                eveningMeds.append(data)
            case .custom:
                if let customTime = medication.customReminderTime {
                    customMeds.append((data, customTime))
                }
            }
        }

        Task {
            await removeAllMedicationReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "medicationReminderEnabled")
            guard masterEnabled else { return }

            if !morningMeds.isEmpty {
                let time = getMorningReminderTime()
                await scheduleGroupedReminder(timeOfDay: .morning, medications: morningMeds, time: time)
            }

            if !afternoonMeds.isEmpty {
                let time = getAfternoonReminderTime()
                await scheduleGroupedReminder(timeOfDay: .afternoon, medications: afternoonMeds, time: time)
            }

            if !eveningMeds.isEmpty {
                let time = getEveningReminderTime()
                await scheduleGroupedReminder(timeOfDay: .evening, medications: eveningMeds, time: time)
            }

            for (data, time) in customMeds {
                await scheduleIndividualReminder(data: data, time: time)
            }
        }
    }

    func scheduleMedicationRemindersFromContext() {
        Task {
            let fileManager = FileManager.default
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
            let storeURL = appSupportURL.appendingPathComponent("NeuralPath.store")

            let schema = Schema([
                SymptomEntry.self,
                Medication.self,
                Substance.self,
                UserMedication.self,
                UserSubstance.self,
                MedicationLog.self,
                SubstanceLog.self,
                UserMindfulness.self,
                MindfulnessLog.self,
                UserSelfCare.self,
                SelfCareLog.self
            ])
            let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)

            guard let container = try? ModelContainer(for: schema, configurations: [config]) else { return }
            let context = container.mainContext

            let descriptor = FetchDescriptor<UserMedication>(
                predicate: #Predicate { $0.isActive == true && $0.reminderEnabled == true }
            )

            guard let medications = try? context.fetch(descriptor) else { return }

            var morningMeds: [MedicationData] = []
            var afternoonMeds: [MedicationData] = []
            var eveningMeds: [MedicationData] = []
            var customMeds: [(MedicationData, Date)] = []

            for medication in medications {
                guard medication.frequency != .asNeeded,
                      let name = medication.name else { continue }

                let data = MedicationData(
                    id: medication.id?.uuidString ?? UUID().uuidString,
                    name: name,
                    dosage: medication.dosage
                )

                let timeOfDay = medication.timeOfDay ?? .morning

                switch timeOfDay {
                case .morning:
                    morningMeds.append(data)
                case .afternoon:
                    afternoonMeds.append(data)
                case .evening:
                    eveningMeds.append(data)
                case .custom:
                    if let customTime = medication.customReminderTime {
                        customMeds.append((data, customTime))
                    }
                }
            }

            await removeAllMedicationReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "medicationReminderEnabled")
            guard masterEnabled else { return }

            if !morningMeds.isEmpty {
                let time = getMorningReminderTime()
                await scheduleGroupedReminder(timeOfDay: .morning, medications: morningMeds, time: time)
            }

            if !afternoonMeds.isEmpty {
                let time = getAfternoonReminderTime()
                await scheduleGroupedReminder(timeOfDay: .afternoon, medications: afternoonMeds, time: time)
            }

            if !eveningMeds.isEmpty {
                let time = getEveningReminderTime()
                await scheduleGroupedReminder(timeOfDay: .evening, medications: eveningMeds, time: time)
            }

            for (data, time) in customMeds {
                await scheduleIndividualReminder(data: data, time: time)
            }
        }
    }

    private func scheduleGroupedReminder(
        timeOfDay: MedicationTimeOfDay,
        medications: [MedicationData],
        time: Date
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"

        let medNames = medications.map { med in
            if let dosage = med.dosage, !dosage.isEmpty {
                return "\(med.name) (\(dosage))"
            }
            return med.name
        }

        if medications.count == 1 {
            content.body = "Time to take \(medNames[0])"
        } else {
            let list = medNames.joined(separator: ", ")
            content.body = "It's time for your \(timeOfDay.displayName.lowercased()) medications: \(list)"
        }

        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER_\(timeOfDay.rawValue.uppercased())"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = "\(reminderPrefix)\(timeOfDay.rawValue)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule grouped medication reminder: \(error)")
        }
    }

    private func scheduleIndividualReminder(data: MedicationData, time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"

        if let dosage = data.dosage, !dosage.isEmpty {
            content.body = "Time to take \(data.name) (\(dosage))"
        } else {
            content.body = "Time to take \(data.name)"
        }

        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER_CUSTOM"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = "\(reminderPrefix)custom_\(data.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule custom medication reminder: \(error)")
        }
    }

    // MARK: - Default Time Helpers

    private func getMorningReminderTime() -> Date {
        UserDefaults.standard.object(forKey: Self.morningReminderTimeKey) as? Date
            ?? Self.defaultReminderTime(for: .morning)
    }

    private func getAfternoonReminderTime() -> Date {
        UserDefaults.standard.object(forKey: Self.afternoonReminderTimeKey) as? Date
            ?? Self.defaultReminderTime(for: .afternoon)
    }

    private func getEveningReminderTime() -> Date {
        UserDefaults.standard.object(forKey: Self.eveningReminderTimeKey) as? Date
            ?? Self.defaultReminderTime(for: .evening)
    }

    static func defaultReminderTime(for timeOfDay: MedicationTimeOfDay) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = timeOfDay.defaultReminderHour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    static func getReminderTime(for timeOfDay: MedicationTimeOfDay) -> Date {
        switch timeOfDay {
        case .morning:
            return UserDefaults.standard.object(forKey: morningReminderTimeKey) as? Date
                ?? defaultReminderTime(for: .morning)
        case .afternoon:
            return UserDefaults.standard.object(forKey: afternoonReminderTimeKey) as? Date
                ?? defaultReminderTime(for: .afternoon)
        case .evening:
            return UserDefaults.standard.object(forKey: eveningReminderTimeKey) as? Date
                ?? defaultReminderTime(for: .evening)
        case .custom:
            return defaultReminderTime(for: .morning)
        }
    }

    // MARK: - Removal and Permissions

    func removeAllMedicationReminders() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let medicationIdentifiers = pending
            .map { $0.identifier }
            .filter { $0.hasPrefix(reminderPrefix) }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: medicationIdentifiers)
    }

    func cancelAllMedicationReminders() {
        Task {
            await removeAllMedicationReminders()
        }
    }

    func requestNotificationPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
}

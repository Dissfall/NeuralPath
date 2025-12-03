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
    static let nightReminderTimeKey = "medicationNightReminderTime"

    private init() {}

    private struct MedicationData {
        let id: String
        let name: String
        let dosage: String?
        let frequency: MedicationFrequency
        let weeklyReminderDay: Int?
        let userSelectedTimeOfDay: MedicationTimeOfDay?
        let customReminderTime: Date?
    }

    /// Returns time slots for a given frequency
    static func getTimeSlotsForFrequency(_ frequency: MedicationFrequency, userSelected: MedicationTimeOfDay?) -> [MedicationTimeOfDay] {
        switch frequency {
        case .onceDaily:
            return [userSelected ?? .morning]
        case .twiceDaily:
            return [.morning, .evening]
        case .threeTimesDaily:
            return [.morning, .afternoon, .evening]
        case .fourTimesDaily:
            return [.morning, .afternoon, .evening, .night]
        case .weekly, .everyOtherDay:
            return [userSelected ?? .morning]
        case .asNeeded:
            return []
        }
    }

    func scheduleMedicationReminders(medications: [UserMedication]) {
        // Group by time-of-day for daily frequencies
        var morningMeds: [MedicationData] = []
        var afternoonMeds: [MedicationData] = []
        var eveningMeds: [MedicationData] = []
        var nightMeds: [MedicationData] = []
        var customMeds: [(MedicationData, Date)] = []
        var weeklyMeds: [MedicationData] = []
        var everyOtherDayMeds: [MedicationData] = []

        for medication in medications {
            let frequency = medication.frequency ?? .onceDaily
            guard medication.reminderEnabled == true,
                  medication.isActive == true,
                  frequency != .asNeeded,
                  let name = medication.name else { continue }

            let data = MedicationData(
                id: medication.id?.uuidString ?? UUID().uuidString,
                name: name,
                dosage: medication.dosage,
                frequency: frequency,
                weeklyReminderDay: medication.weeklyReminderDay,
                userSelectedTimeOfDay: medication.timeOfDay,
                customReminderTime: medication.customReminderTime
            )

            // Handle custom time separately
            if medication.timeOfDay == .custom, let customTime = medication.customReminderTime {
                customMeds.append((data, customTime))
                continue
            }

            // Handle non-daily frequencies
            switch frequency {
            case .weekly:
                weeklyMeds.append(data)
            case .everyOtherDay:
                everyOtherDayMeds.append(data)
            default:
                // Daily frequencies - use auto-assignment
                let timeSlots = Self.getTimeSlotsForFrequency(frequency, userSelected: medication.timeOfDay)
                for slot in timeSlots {
                    switch slot {
                    case .morning:
                        morningMeds.append(data)
                    case .afternoon:
                        afternoonMeds.append(data)
                    case .evening:
                        eveningMeds.append(data)
                    case .night:
                        nightMeds.append(data)
                    case .custom:
                        break
                    }
                }
            }
        }

        Task {
            await removeAllMedicationReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "medicationReminderEnabled")
            guard masterEnabled else { return }

            // Schedule daily grouped reminders
            if !morningMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .morning, medications: morningMeds, time: getMorningReminderTime())
            }
            if !afternoonMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .afternoon, medications: afternoonMeds, time: getAfternoonReminderTime())
            }
            if !eveningMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .evening, medications: eveningMeds, time: getEveningReminderTime())
            }
            if !nightMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .night, medications: nightMeds, time: getNightReminderTime())
            }

            // Schedule custom time reminders
            for (data, time) in customMeds {
                await scheduleIndividualReminder(data: data, time: time)
            }

            // Schedule weekly reminders
            for data in weeklyMeds {
                await scheduleWeeklyReminder(data: data)
            }

            // Schedule every-other-day reminders
            for data in everyOtherDayMeds {
                await scheduleEveryOtherDayReminder(data: data)
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

            // Group by time-of-day for daily frequencies
            var morningMeds: [MedicationData] = []
            var afternoonMeds: [MedicationData] = []
            var eveningMeds: [MedicationData] = []
            var nightMeds: [MedicationData] = []
            var customMeds: [(MedicationData, Date)] = []
            var weeklyMeds: [MedicationData] = []
            var everyOtherDayMeds: [MedicationData] = []

            for medication in medications {
                let frequency = medication.frequency ?? .onceDaily
                guard frequency != .asNeeded,
                      let name = medication.name else { continue }

                let data = MedicationData(
                    id: medication.id?.uuidString ?? UUID().uuidString,
                    name: name,
                    dosage: medication.dosage,
                    frequency: frequency,
                    weeklyReminderDay: medication.weeklyReminderDay,
                    userSelectedTimeOfDay: medication.timeOfDay,
                    customReminderTime: medication.customReminderTime
                )

                // Handle custom time separately
                if medication.timeOfDay == .custom, let customTime = medication.customReminderTime {
                    customMeds.append((data, customTime))
                    continue
                }

                // Handle non-daily frequencies
                switch frequency {
                case .weekly:
                    weeklyMeds.append(data)
                case .everyOtherDay:
                    everyOtherDayMeds.append(data)
                default:
                    // Daily frequencies - use auto-assignment
                    let timeSlots = Self.getTimeSlotsForFrequency(frequency, userSelected: medication.timeOfDay)
                    for slot in timeSlots {
                        switch slot {
                        case .morning:
                            morningMeds.append(data)
                        case .afternoon:
                            afternoonMeds.append(data)
                        case .evening:
                            eveningMeds.append(data)
                        case .night:
                            nightMeds.append(data)
                        case .custom:
                            break
                        }
                    }
                }
            }

            await removeAllMedicationReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "medicationReminderEnabled")
            guard masterEnabled else { return }

            // Schedule daily grouped reminders
            if !morningMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .morning, medications: morningMeds, time: getMorningReminderTime())
            }
            if !afternoonMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .afternoon, medications: afternoonMeds, time: getAfternoonReminderTime())
            }
            if !eveningMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .evening, medications: eveningMeds, time: getEveningReminderTime())
            }
            if !nightMeds.isEmpty {
                await scheduleGroupedReminder(timeOfDay: .night, medications: nightMeds, time: getNightReminderTime())
            }

            // Schedule custom time reminders
            for (data, time) in customMeds {
                await scheduleIndividualReminder(data: data, time: time)
            }

            // Schedule weekly reminders (individual, not grouped)
            for data in weeklyMeds {
                await scheduleWeeklyReminder(data: data)
            }

            // Schedule every-other-day reminders (individual, interval-based)
            for data in everyOtherDayMeds {
                await scheduleEveryOtherDayReminder(data: data)
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

    private func scheduleWeeklyReminder(data: MedicationData) async {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Medication Reminder"

        if let dosage = data.dosage, !dosage.isEmpty {
            content.body = "Time to take \(data.name) (\(dosage))"
        } else {
            content.body = "Time to take \(data.name)"
        }

        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER_WEEKLY"

        let timeOfDay = data.userSelectedTimeOfDay ?? .morning
        let time = getTime(for: timeOfDay)

        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.weekday = data.weeklyReminderDay ?? 2 // Monday default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = "\(reminderPrefix)weekly_\(data.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule weekly medication reminder: \(error)")
        }
    }

    private func scheduleEveryOtherDayReminder(data: MedicationData) async {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"

        if let dosage = data.dosage, !dosage.isEmpty {
            content.body = "Time to take \(data.name) (\(dosage))"
        } else {
            content.body = "Time to take \(data.name)"
        }

        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER_QOD"

        // 48 hours in seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 60 * 60, repeats: true)

        let identifier = "\(reminderPrefix)qod_\(data.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule every-other-day medication reminder: \(error)")
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

    private func getNightReminderTime() -> Date {
        UserDefaults.standard.object(forKey: Self.nightReminderTimeKey) as? Date
            ?? Self.defaultReminderTime(for: .night)
    }

    private func getTime(for timeOfDay: MedicationTimeOfDay) -> Date {
        switch timeOfDay {
        case .morning: return getMorningReminderTime()
        case .afternoon: return getAfternoonReminderTime()
        case .evening: return getEveningReminderTime()
        case .night: return getNightReminderTime()
        case .custom: return getMorningReminderTime()
        }
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
        case .night:
            return UserDefaults.standard.object(forKey: nightReminderTimeKey) as? Date
                ?? defaultReminderTime(for: .night)
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

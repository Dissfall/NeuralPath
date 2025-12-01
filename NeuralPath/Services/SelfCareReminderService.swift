//
//  SelfCareReminderService.swift
//  NeuralPath
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
class SelfCareReminderService {
    static let shared = SelfCareReminderService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderPrefix = "selfCareReminder_"

    // UserDefaults keys for reminder settings
    static let morningReminderEnabledKey = "selfCareMorningReminderEnabled"
    static let afternoonReminderEnabledKey = "selfCareAfternoonReminderEnabled"
    static let eveningReminderEnabledKey = "selfCareEveningReminderEnabled"
    static let morningReminderTimeKey = "selfCareMorningReminderTime"
    static let afternoonReminderTimeKey = "selfCareAfternoonReminderTime"
    static let eveningReminderTimeKey = "selfCareEveningReminderTime"

    private init() {}

    // Plain struct to hold practice data for async scheduling
    private struct SelfCarePracticeData {
        let timeOfDay: SelfCareTimeOfDay
        let isActive: Bool
    }

    func scheduleSelfCareReminders(practices: [UserSelfCare]) {
        // Extract data synchronously before async work
        let practiceData: [SelfCarePracticeData] = practices.map { practice in
            SelfCarePracticeData(
                timeOfDay: practice.timeOfDay,
                isActive: practice.isActive == true
            )
        }

        Task {
            await removeAllSelfCareReminders()

            // Group practices by time of day
            let morningCount = practiceData.filter { $0.timeOfDay == .morning && $0.isActive }.count
            let afternoonCount = practiceData.filter { $0.timeOfDay == .afternoon && $0.isActive }.count
            let eveningCount = practiceData.filter { $0.timeOfDay == .evening && $0.isActive }.count

            // Schedule morning reminder
            if morningCount > 0,
               UserDefaults.standard.bool(forKey: Self.morningReminderEnabledKey),
               let reminderTime = UserDefaults.standard.object(forKey: Self.morningReminderTimeKey) as? Date {
                await scheduleReminder(for: .morning, time: reminderTime, practiceCount: morningCount)
            }

            // Schedule afternoon reminder
            if afternoonCount > 0,
               UserDefaults.standard.bool(forKey: Self.afternoonReminderEnabledKey),
               let reminderTime = UserDefaults.standard.object(forKey: Self.afternoonReminderTimeKey) as? Date {
                await scheduleReminder(for: .afternoon, time: reminderTime, practiceCount: afternoonCount)
            }

            // Schedule evening reminder
            if eveningCount > 0,
               UserDefaults.standard.bool(forKey: Self.eveningReminderEnabledKey),
               let reminderTime = UserDefaults.standard.object(forKey: Self.eveningReminderTimeKey) as? Date {
                await scheduleReminder(for: .evening, time: reminderTime, practiceCount: eveningCount)
            }
        }
    }

    func scheduleSelfCareRemindersFromContext() {
        Task {
            let fileManager = FileManager.default
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
            let storeURL = appSupportURL.appendingPathComponent("NeuralPath.store")

            // NOTE: Must use full schema matching main app to avoid "no such table" errors
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

            let descriptor = FetchDescriptor<UserSelfCare>(
                predicate: #Predicate { $0.isActive == true }
            )

            guard let practices = try? context.fetch(descriptor) else { return }

            // Extract data synchronously within same context
            let practiceData: [SelfCarePracticeData] = practices.map { practice in
                SelfCarePracticeData(
                    timeOfDay: practice.timeOfDay,
                    isActive: practice.isActive == true
                )
            }

            await removeAllSelfCareReminders()

            // Group practices by time of day
            let morningCount = practiceData.filter { $0.timeOfDay == .morning && $0.isActive }.count
            let afternoonCount = practiceData.filter { $0.timeOfDay == .afternoon && $0.isActive }.count
            let eveningCount = practiceData.filter { $0.timeOfDay == .evening && $0.isActive }.count

            // Schedule morning reminder
            if morningCount > 0,
               UserDefaults.standard.bool(forKey: Self.morningReminderEnabledKey),
               let reminderTime = UserDefaults.standard.object(forKey: Self.morningReminderTimeKey) as? Date {
                await scheduleReminder(for: .morning, time: reminderTime, practiceCount: morningCount)
            }

            // Schedule afternoon reminder
            if afternoonCount > 0,
               UserDefaults.standard.bool(forKey: Self.afternoonReminderEnabledKey),
               let reminderTime = UserDefaults.standard.object(forKey: Self.afternoonReminderTimeKey) as? Date {
                await scheduleReminder(for: .afternoon, time: reminderTime, practiceCount: afternoonCount)
            }

            // Schedule evening reminder
            if eveningCount > 0,
               UserDefaults.standard.bool(forKey: Self.eveningReminderEnabledKey),
               let reminderTime = UserDefaults.standard.object(forKey: Self.eveningReminderTimeKey) as? Date {
                await scheduleReminder(for: .evening, time: reminderTime, practiceCount: eveningCount)
            }
        }
    }

    private func scheduleReminder(for timeOfDay: SelfCareTimeOfDay, time: Date, practiceCount: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Self-Care Reminder"
        content.body = "Don't forget to log your \(timeOfDay.displayName.lowercased()) self-care routine"
        content.sound = .default
        content.categoryIdentifier = "SELFCARE_REMINDER_\(timeOfDay.rawValue.uppercased())"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = "\(reminderPrefix)\(timeOfDay.rawValue)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule self-care reminder: \(error)")
        }
    }

    func removeAllSelfCareReminders() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let selfCareIdentifiers = pending
            .map { $0.identifier }
            .filter { $0.hasPrefix(reminderPrefix) }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: selfCareIdentifiers)
    }

    func cancelAllSelfCareReminders() {
        Task {
            await removeAllSelfCareReminders()
        }
    }

    // Helper to get default reminder time for a time of day
    static func defaultReminderTime(for timeOfDay: SelfCareTimeOfDay) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = timeOfDay.defaultReminderHour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // Check if any self-care reminder is enabled
    static var hasAnyReminderEnabled: Bool {
        UserDefaults.standard.bool(forKey: morningReminderEnabledKey) ||
        UserDefaults.standard.bool(forKey: afternoonReminderEnabledKey) ||
        UserDefaults.standard.bool(forKey: eveningReminderEnabledKey)
    }
}

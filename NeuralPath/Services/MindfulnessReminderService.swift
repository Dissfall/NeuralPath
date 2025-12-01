//
//  MindfulnessReminderService.swift
//  NeuralPath
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
class MindfulnessReminderService {
    static let shared = MindfulnessReminderService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderPrefix = "mindfulnessReminder_"

    private init() {}

    // Plain struct to hold practice data for async scheduling
    private struct MindfulnessReminderData {
        let id: String
        let name: String
        let reminderTime: Date
    }

    func scheduleMindfulnessReminders(practices: [UserMindfulness]) {
        // Extract data synchronously before async work
        let reminderData: [MindfulnessReminderData] = practices.compactMap { practice in
            guard practice.reminderEnabled == true,
                  let reminderTime = practice.reminderTime,
                  let name = practice.name,
                  practice.isActive == true else {
                return nil
            }
            return MindfulnessReminderData(
                id: practice.id?.uuidString ?? UUID().uuidString,
                name: name,
                reminderTime: reminderTime
            )
        }

        Task {
            await removeAllMindfulnessReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "mindfulnessReminderEnabled")
            guard masterEnabled else { return }

            for data in reminderData {
                await scheduleReminder(data: data)
            }
        }
    }

    func scheduleMindfulnessRemindersFromContext() {
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

            let descriptor = FetchDescriptor<UserMindfulness>(
                predicate: #Predicate { $0.isActive == true && $0.reminderEnabled == true }
            )

            guard let practices = try? context.fetch(descriptor) else { return }

            // Extract data synchronously within same context
            let reminderData: [MindfulnessReminderData] = practices.compactMap { practice in
                guard let reminderTime = practice.reminderTime,
                      let name = practice.name else {
                    return nil
                }
                return MindfulnessReminderData(
                    id: practice.id?.uuidString ?? UUID().uuidString,
                    name: name,
                    reminderTime: reminderTime
                )
            }

            await removeAllMindfulnessReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "mindfulnessReminderEnabled")
            guard masterEnabled else { return }

            for data in reminderData {
                await scheduleReminder(data: data)
            }
        }
    }

    private func scheduleReminder(data: MindfulnessReminderData) async {
        let content = UNMutableNotificationContent()
        content.title = "Mindfulness Reminder"
        content.body = "Time for your \(data.name) practice"
        content.sound = .default
        content.categoryIdentifier = "MINDFULNESS_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: data.reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = "\(reminderPrefix)\(data.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule mindfulness reminder: \(error)")
        }
    }

    func removeAllMindfulnessReminders() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let mindfulnessIdentifiers = pending
            .map { $0.identifier }
            .filter { $0.hasPrefix(reminderPrefix) }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: mindfulnessIdentifiers)
    }

    func cancelAllMindfulnessReminders() {
        Task {
            await removeAllMindfulnessReminders()
        }
    }
}

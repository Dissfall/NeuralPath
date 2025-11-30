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

    func scheduleMindfulnessReminders(practices: [UserMindfulness]) {
        Task {
            await removeAllMindfulnessReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "mindfulnessReminderEnabled")
            guard masterEnabled else { return }

            for practice in practices {
                guard practice.reminderEnabled == true,
                      let reminderTime = practice.reminderTime,
                      let name = practice.name,
                      practice.isActive == true else {
                    continue
                }

                await scheduleReminder(for: practice, name: name, time: reminderTime)
            }
        }
    }

    func scheduleMindfulnessRemindersFromContext() {
        Task {
            let fileManager = FileManager.default
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
            let storeURL = appSupportURL.appendingPathComponent("NeuralPath.store")

            let schema = Schema([UserMindfulness.self])
            let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)

            guard let container = try? ModelContainer(for: schema, configurations: [config]) else { return }
            let context = container.mainContext

            let descriptor = FetchDescriptor<UserMindfulness>(
                predicate: #Predicate { $0.isActive == true && $0.reminderEnabled == true }
            )

            guard let practices = try? context.fetch(descriptor) else { return }
            scheduleMindfulnessReminders(practices: practices)
        }
    }

    private func scheduleReminder(for practice: UserMindfulness, name: String, time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Mindfulness Reminder"
        content.body = "Time for your \(name) practice"
        content.sound = .default
        content.categoryIdentifier = "MINDFULNESS_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = reminderIdentifier(for: practice)
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

    private func reminderIdentifier(for practice: UserMindfulness) -> String {
        "\(reminderPrefix)\(practice.id?.uuidString ?? UUID().uuidString)"
    }
}

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

    private init() {}

    func scheduleMedicationReminders(medications: [UserMedication]) {
        Task {
            // First, remove all existing medication reminders
            await removeAllMedicationReminders()

            // Check if master toggle is enabled
            let masterEnabled = UserDefaults.standard.bool(forKey: "medicationReminderEnabled")
            guard masterEnabled else { return }

            // Schedule reminders for each medication with reminder enabled
            for medication in medications {
                guard medication.reminderEnabled == true,
                      let reminderTime = medication.reminderTime,
                      let name = medication.name,
                      medication.isActive == true else {
                    continue
                }

                await scheduleReminder(for: medication, name: name, time: reminderTime)
            }
        }
    }

    func scheduleMedicationRemindersFromContext() {
        Task {
            guard let container = try? ModelContainer(for: UserMedication.self) else { return }
            let context = container.mainContext

            let descriptor = FetchDescriptor<UserMedication>(
                predicate: #Predicate { $0.isActive == true && $0.reminderEnabled == true }
            )

            guard let medications = try? context.fetch(descriptor) else { return }
            scheduleMedicationReminders(medications: medications)
        }
    }

    private func scheduleReminder(for medication: UserMedication, name: String, time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"

        if let dosage = medication.dosage, !dosage.isEmpty {
            content.body = "Time to take \(name) (\(dosage))"
        } else {
            content.body = "Time to take \(name)"
        }

        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = reminderIdentifier(for: medication)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule medication reminder: \(error)")
        }
    }

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

    private func reminderIdentifier(for medication: UserMedication) -> String {
        "\(reminderPrefix)\(medication.id?.uuidString ?? UUID().uuidString)"
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

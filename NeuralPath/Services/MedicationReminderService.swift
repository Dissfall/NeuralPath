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

    // Plain struct to hold medication data for async scheduling
    private struct MedicationReminderData {
        let id: String
        let name: String
        let dosage: String?
        let reminderTime: Date
    }

    func scheduleMedicationReminders(medications: [UserMedication]) {
        // Extract data synchronously before async work
        let reminderData: [MedicationReminderData] = medications.compactMap { medication in
            guard medication.reminderEnabled == true,
                  let reminderTime = medication.reminderTime,
                  let name = medication.name,
                  medication.isActive == true else {
                return nil
            }
            return MedicationReminderData(
                id: medication.id?.uuidString ?? UUID().uuidString,
                name: name,
                dosage: medication.dosage,
                reminderTime: reminderTime
            )
        }

        Task {
            await removeAllMedicationReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "medicationReminderEnabled")
            guard masterEnabled else { return }

            for data in reminderData {
                await scheduleReminder(data: data)
            }
        }
    }

    func scheduleMedicationRemindersFromContext() {
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

            let descriptor = FetchDescriptor<UserMedication>(
                predicate: #Predicate { $0.isActive == true && $0.reminderEnabled == true }
            )

            guard let medications = try? context.fetch(descriptor) else { return }

            // Extract data synchronously within same context
            let reminderData: [MedicationReminderData] = medications.compactMap { medication in
                guard let reminderTime = medication.reminderTime,
                      let name = medication.name else {
                    return nil
                }
                return MedicationReminderData(
                    id: medication.id?.uuidString ?? UUID().uuidString,
                    name: name,
                    dosage: medication.dosage,
                    reminderTime: reminderTime
                )
            }

            await removeAllMedicationReminders()

            let masterEnabled = UserDefaults.standard.bool(forKey: "medicationReminderEnabled")
            guard masterEnabled else { return }

            for data in reminderData {
                await scheduleReminder(data: data)
            }
        }
    }

    private func scheduleReminder(data: MedicationReminderData) async {
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"

        if let dosage = data.dosage, !dosage.isEmpty {
            content.body = "Time to take \(data.name) (\(dosage))"
        } else {
            content.body = "Time to take \(data.name)"
        }

        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: data.reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let identifier = "\(reminderPrefix)\(data.id)"
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

    func requestNotificationPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
}

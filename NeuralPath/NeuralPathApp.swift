//
//  NeuralPathApp.swift
//  NeuralPath
//
//  Created by Goša Lukyanau on 16/11/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

func migrateMedicationTimeOfDay() {
    let migrationKey = "medicationTimeOfDayMigrationCompleted"
    guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

    Task {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let storeURL = appSupportURL.appendingPathComponent("NeuralPath.store")

        let schema = Schema([
            SymptomEntry.self, Medication.self, Substance.self,
            UserMedication.self, UserSubstance.self, MedicationLog.self, SubstanceLog.self,
            UserMindfulness.self, MindfulnessLog.self, UserSelfCare.self, SelfCareLog.self
        ])
        let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else { return }
        let context = container.mainContext

        let descriptor = FetchDescriptor<UserMedication>(
            predicate: #Predicate { $0.isActive == true && $0.reminderEnabled == true }
        )

        guard let medications = try? context.fetch(descriptor) else { return }

        for medication in medications {
            // Skip if already migrated
            guard medication.timeOfDay == nil else { continue }

            // Map existing reminderTime to timeOfDay
            if let reminderTime = medication.reminderTime {
                let hour = Calendar.current.component(.hour, from: reminderTime)
                let timeOfDay: MedicationTimeOfDay
                switch hour {
                case 5..<11: timeOfDay = .morning
                case 11..<17: timeOfDay = .afternoon
                case 17..<24, 0..<5: timeOfDay = .evening
                default: timeOfDay = .morning
                }
                medication.timeOfDay = timeOfDay
            } else {
                medication.timeOfDay = .morning
            }
        }

        try? context.save()
        await MainActor.run {
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
}

func rescheduleRemindersIfNeeded() {
    // Migrate medications to new time-of-day system
    migrateMedicationTimeOfDay()

    // Re-schedule medication reminders
    if UserDefaults.standard.bool(forKey: "medicationReminderEnabled") {
        MedicationReminderService.shared.scheduleMedicationRemindersFromContext()
    }

    // Re-schedule mindfulness reminders
    if UserDefaults.standard.bool(forKey: "mindfulnessReminderEnabled") {
        MindfulnessReminderService.shared.scheduleMindfulnessRemindersFromContext()
    }

    // Re-schedule self-care reminders
    if SelfCareReminderService.hasAnyReminderEnabled {
        SelfCareReminderService.shared.scheduleSelfCareRemindersFromContext()
    }

    // Re-schedule daily entry reminder
    if UserDefaults.standard.bool(forKey: "dailyReminderEnabled"),
       let savedTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyEntryReminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Check In"
        content.body = "How are you feeling today? Take a moment to log your mood and symptoms."
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: savedTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyEntryReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to re-schedule daily reminder: \(error)")
            }
        }
    }
}

@main
struct NeuralPathApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var whatsNewManager = WhatsNewManager()
    @StateObject private var onboardingManager = OnboardingManager()
    @StateObject private var donationManager = DonationManager()

    var sharedModelContainer: ModelContainer = {
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

        // Get the Application Support directory and ensure it exists
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access Application Support directory")
        }

        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            do {
                try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
                print("NeuralPath: Created Application Support directory")
            } catch {
                print("NeuralPath: Failed to create Application Support directory: \(error)")
            }
        }

        // Set up the store URL explicitly
        let storeURL = appSupportURL.appendingPathComponent("NeuralPath.store")
        print("NeuralPath: Using store URL: \(storeURL)")

        // Use CloudKitManager to determine if we should use CloudKit
        let useCloudKit = CloudKitManager.shared.shouldUseCloudKit()

        // Create configuration with explicit URL
        let modelConfiguration: ModelConfiguration
        if useCloudKit {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .automatic
            )
            print("NeuralPath: Configuring with CloudKit support")
        } else {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            print("NeuralPath: Using local storage only")
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If configuration fails, try local-only as fallback
            print("NeuralPath: Failed to create ModelContainer: \(error)")
            print("NeuralPath: Attempting local-only fallback with explicit URL")

            let localConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )

            do {
                return try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                // Last resort - in-memory storage
                print("NeuralPath: Failed local storage, using in-memory: \(error)")
                let memoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )

                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfiguration])
                } catch {
                    fatalError("Could not create any ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Check CloudKit availability asynchronously after app starts
                    CloudKitManager.shared.checkCloudKitAvailability()
                    // Check onboarding status first
                    onboardingManager.checkOnboardingStatus()
                    // Increment session count for donation prompt
                    donationManager.incrementSessionAndCheck()
                    // Re-schedule reminders on app launch
                    rescheduleRemindersIfNeeded()
                    // Auto-initialize ML analysis
                    MLModelManager.shared.autoInitializeIfNeeded()
                }
                // Show onboarding first for new users
                .fullScreenCover(isPresented: $onboardingManager.shouldShowOnboarding) {
                    OnboardingView(onComplete: {
                        onboardingManager.completeOnboarding()
                        // After onboarding, check for What's New
                        whatsNewManager.checkForWhatsNew()
                    })
                }
                // Show What's New for returning users on new version
                .fullScreenCover(isPresented: $whatsNewManager.shouldShowWhatsNew) {
                    WhatsNewView(
                        features: whatsNewManager.currentFeatures,
                        onDismiss: {
                            whatsNewManager.markAsSeen()
                        }
                    )
                }
                // Show donation prompt (after onboarding and whatsNew)
                .sheet(isPresented: $donationManager.shouldShowDonation) {
                    DonationView(
                        onDismiss: {
                            donationManager.dismissForNow()
                        },
                        onNeverShow: {
                            donationManager.dismissForever()
                        }
                    )
                }
                .onChange(of: onboardingManager.shouldShowOnboarding) { _, showingOnboarding in
                    // When onboarding is dismissed, check for What's New
                    if !showingOnboarding && onboardingManager.hasCompletedOnboarding {
                        whatsNewManager.checkForWhatsNew()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

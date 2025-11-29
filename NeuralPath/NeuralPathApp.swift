//
//  NeuralPathApp.swift
//  NeuralPath
//
//  Created by Goša Lukyanau on 16/11/2025.
//

import SwiftUI
import SwiftData

@main
struct NeuralPathApp: App {
    @StateObject private var whatsNewManager = WhatsNewManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SymptomEntry.self,
            Medication.self,
            Substance.self,
            UserMedication.self,
            UserSubstance.self,
            MedicationLog.self,
            SubstanceLog.self
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
                    // Check if we should show What's New
                    whatsNewManager.checkForWhatsNew()
                }
                .fullScreenCover(isPresented: $whatsNewManager.shouldShowWhatsNew) {
                    WhatsNewView(
                        features: whatsNewManager.currentFeatures,
                        onDismiss: {
                            whatsNewManager.markAsSeen()
                        }
                    )
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

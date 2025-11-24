//
//  CloudKitManager.swift
//  NeuralPath
//
//  CloudKit availability and configuration manager
//

import Foundation
import SwiftData

// Only import CloudKit on non-simulator platforms
#if !targetEnvironment(simulator)
import CloudKit
#endif

class CloudKitManager {
    static let shared = CloudKitManager()

    private init() {}

    enum CloudKitAvailability {
        case available
        case unavailable(reason: String)
        case checking
    }

    private(set) var availability: CloudKitAvailability = .checking

    func shouldUseCloudKit() -> Bool {
        // Synchronously check if we should attempt CloudKit
        #if targetEnvironment(simulator)
            print("NeuralPath: Running on simulator - CloudKit disabled")
            // Set availability immediately for simulator
            availability = .unavailable(reason: "Running on simulator")
            return false
        #else
            // On real device, attempt CloudKit unless explicitly disabled

            // Check for explicit disable via environment variable
            if ProcessInfo.processInfo.environment["DISABLE_CLOUDKIT"] != nil {
                print("NeuralPath: CloudKit disabled via environment variable")
                availability = .unavailable(reason: "Disabled via environment")
                return false
            }

            // Check for explicit disable via user defaults
            if UserDefaults.standard.bool(forKey: "DisableCloudKit") {
                print("NeuralPath: CloudKit disabled via user preferences")
                availability = .unavailable(reason: "Disabled via preferences")
                return false
            }

            // Default to trying CloudKit on real devices
            return true
        #endif
    }

    func checkCloudKitAvailability() {
        // Don't check CloudKit on simulator at all
        #if targetEnvironment(simulator)
            // Already set in shouldUseCloudKit()
            print("NeuralPath: Skipping CloudKit availability check on simulator")
            NotificationCenter.default.post(
                name: NSNotification.Name("CloudKitAvailabilityChanged"),
                object: nil
            )
        #else
            // Only check CloudKit on real devices
            CKContainer.default().accountStatus { [weak self] status, error in
                DispatchQueue.main.async {
                    switch status {
                    case .available:
                        self?.availability = .available
                        print("NeuralPath: ✅ iCloud account available - CloudKit sync enabled")

                    case .noAccount:
                        self?.availability = .unavailable(reason: "No iCloud account configured")
                        print("NeuralPath: ⚠️ No iCloud account - using local storage only")

                    case .restricted:
                        self?.availability = .unavailable(reason: "iCloud account restricted")
                        print("NeuralPath: ⚠️ iCloud restricted - using local storage only")

                    case .couldNotDetermine:
                        let reason = error?.localizedDescription ?? "Unknown error"
                        self?.availability = .unavailable(reason: "Could not determine status: \(reason)")
                        print("NeuralPath: ⚠️ Could not determine iCloud status - using local storage only")

                    case .temporarilyUnavailable:
                        self?.availability = .unavailable(reason: "iCloud temporarily unavailable")
                        print("NeuralPath: ⚠️ iCloud temporarily unavailable - using local storage only")

                    @unknown default:
                        self?.availability = .unavailable(reason: "Unknown iCloud status")
                        print("NeuralPath: ⚠️ Unknown iCloud status - using local storage only")
                    }

                    // Post notification for UI updates
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CloudKitAvailabilityChanged"),
                        object: nil
                    )
                }
            }
        #endif
    }

    func isCloudKitAvailable() -> Bool {
        switch availability {
        case .available:
            return true
        case .unavailable, .checking:
            return false
        }
    }
}
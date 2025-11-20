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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

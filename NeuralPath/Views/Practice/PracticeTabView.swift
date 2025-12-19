//
//  PracticeTabView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct PracticeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]
    @Query(sort: \UserMindfulness.name) private var userMindfulness: [UserMindfulness]

    @State private var selectedPractice: GuidedPractice?

    var body: some View {
        NavigationStack {
            PracticeCatalogView(
                latestEntry: entries.first,
                onStartPractice: { practice in
                    selectedPractice = practice
                }
            )
            .navigationTitle("Practice")
        }
        .fullScreenCover(item: $selectedPractice) { practice in
            PracticeSessionView(
                practice: practice,
                userMindfulness: userMindfulness,
                onComplete: { completed, stepsCompleted in
                    logPractice(practice, completed: completed, stepsCompleted: stepsCompleted)
                }
            )
        }
    }

    private func logPractice(_ practice: GuidedPractice, completed: Bool, stepsCompleted: Int) {
        let metadata = GuidedPracticeLogMetadata(
            practiceId: practice.id,
            completed: completed,
            stepsCompleted: stepsCompleted,
            totalSteps: practice.steps.count
        )

        let log = MindfulnessLog(
            userMindfulness: nil,
            practiceName: practice.name,
            timestamp: Date(),
            notes: metadata.toJSON()
        )

        modelContext.insert(log)
    }
}

#Preview {
    PracticeTabView()
        .modelContainer(for: [SymptomEntry.self, MindfulnessLog.self, UserMindfulness.self], inMemory: true)
}

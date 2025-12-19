//
//  PracticeSuggestionEngine.swift
//  NeuralPath
//

import Foundation

enum PracticeSuggestionEngine {

    static func suggestPractices(
        latestEntry: SymptomEntry?,
        timeOfDay: Date,
        maxResults: Int = 3
    ) -> [GuidedPractice] {
        var scoredPractices: [(GuidedPractice, Int)] = []

        for practice in GuidedPracticeDatabase.allPractices {
            var score = 0

            // Score based on anxiety
            if let anxiety = latestEntry?.anxietyLevel {
                if anxiety == .moderate || anxiety == .severe || anxiety == .extreme {
                    if practice.suggestedFor.forAnxiety {
                        score += 3
                    }
                }
            }

            // Score based on mood
            if let mood = latestEntry?.moodLevel {
                if mood == .veryLow || mood == .low {
                    if practice.suggestedFor.forLowMood {
                        score += 3
                    }
                }
            }

            // Score based on time of day
            let hour = Calendar.current.component(.hour, from: timeOfDay)
            if hour < 10 && practice.suggestedFor.forMorning {
                score += 2
            }
            if hour >= 20 && practice.suggestedFor.forEvening {
                score += 2
            }

            // Slightly favor quick practices
            if practice.suggestedFor.forQuickBreak {
                score += 1
            }

            if score > 0 {
                scoredPractices.append((practice, score))
            }
        }

        // Sort by score descending, then take top results
        let sorted = scoredPractices
            .sorted { $0.1 > $1.1 }
            .prefix(maxResults)
            .map { $0.0 }

        // If no suggestions based on context, return some defaults
        if sorted.isEmpty {
            return defaultSuggestions(for: timeOfDay)
        }

        return Array(sorted)
    }

    private static func defaultSuggestions(for timeOfDay: Date) -> [GuidedPractice] {
        let hour = Calendar.current.component(.hour, from: timeOfDay)

        // Morning defaults
        if hour < 12 {
            return [
                GuidedPracticeDatabase.boxBreathing,
                GuidedPracticeDatabase.oneMindfulBreath,
                GuidedPracticeDatabase.noticingPractice
            ]
        }

        // Afternoon defaults
        if hour < 18 {
            return [
                GuidedPracticeDatabase.physiologicalSigh,
                GuidedPracticeDatabase.gentleMovement,
                GuidedPracticeDatabase.fiveFourThreeTwoOne
            ]
        }

        // Evening defaults
        return [
            GuidedPracticeDatabase.fourSevenEightBreathing,
            GuidedPracticeDatabase.bodyCheckIn,
            GuidedPracticeDatabase.selfCompassionBreak
        ]
    }
}

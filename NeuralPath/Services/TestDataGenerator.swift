import Foundation
import SwiftData
import SwiftUI

@MainActor
class TestDataGenerator {

    enum DataPattern {
        case improving
        case worsening
        case stable
        case variable
    }

    struct GenerationOptions {
        var numberOfDays: Int = 30
        var pattern: DataPattern = .variable
        var includeMedications: Bool = true
        var includeSubstances: Bool = true
        var includeSleep: Bool = true
        var includeExercise: Bool = true
        var includeDaylight: Bool = true
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Main Generation Method

    func generateTestData(options: GenerationOptions) async throws {
        // Create or get test user medications
        let medications = options.includeMedications ? try await setupTestMedications() : []
        let substances = options.includeSubstances ? try await setupTestSubstances() : []

        // Generate entries for each day
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -options.numberOfDays, to: endDate)!

        var currentDate = startDate
        var dayIndex = 0

        while currentDate <= endDate {
            let entry = generateEntry(
                for: currentDate,
                dayIndex: dayIndex,
                totalDays: options.numberOfDays,
                pattern: options.pattern,
                medications: medications,
                substances: substances,
                options: options
            )

            modelContext.insert(entry)

            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            dayIndex += 1
        }

        try modelContext.save()
    }

    // MARK: - Setup Test Data

    private func setupTestMedications() async throws -> [UserMedication] {
        // Check if test medications already exist
        let descriptor = FetchDescriptor<UserMedication>(
            predicate: #Predicate { med in
                med.name?.contains("[TEST]") == true
            }
        )

        let existing = try modelContext.fetch(descriptor)
        if !existing.isEmpty {
            return existing
        }

        // Create test medications
        let sertraline = UserMedication(
            name: "[TEST] Sertraline",
            dosage: "50mg",
            category: .ssri,
            frequency: .onceDaily,
            notes: "Test medication - SSRI",
            isActive: true
        )

        let melatonin = UserMedication(
            name: "[TEST] Melatonin",
            dosage: "3mg",
            category: .sleepAid,
            frequency: .asNeeded,
            notes: "Test supplement - Sleep aid",
            isActive: true
        )

        modelContext.insert(sertraline)
        modelContext.insert(melatonin)

        try modelContext.save()

        return [sertraline, melatonin]
    }

    private func setupTestSubstances() async throws -> [UserSubstance] {
        // Check if test substances already exist
        let descriptor = FetchDescriptor<UserSubstance>(
            predicate: #Predicate { sub in
                sub.name?.contains("[TEST]") == true
            }
        )

        let existing = try modelContext.fetch(descriptor)
        if !existing.isEmpty {
            return existing
        }

        // Create test substances
        let coffee = UserSubstance(
            name: "[TEST] Coffee",
            defaultUnit: .cups,
            notes: "Test substance - Caffeine",
            isActive: true
        )

        let alcohol = UserSubstance(
            name: "[TEST] Alcohol",
            defaultUnit: .drinks,
            notes: "Test substance - Depressant",
            isActive: true
        )

        modelContext.insert(coffee)
        modelContext.insert(alcohol)

        try modelContext.save()

        return [coffee, alcohol]
    }

    // MARK: - Entry Generation

    private func generateEntry(
        for date: Date,
        dayIndex: Int,
        totalDays: Int,
        pattern: DataPattern,
        medications: [UserMedication],
        substances: [UserSubstance],
        options: GenerationOptions
    ) -> SymptomEntry {

        let progress = Double(dayIndex) / Double(totalDays)

        // Calculate base values based on pattern
        let (mood, anxiety, anhedonia) = calculateSymptoms(
            progress: progress,
            pattern: pattern,
            dayIndex: dayIndex
        )

        // Create entry
        let entry = SymptomEntry(
            timestamp: randomTimeOnDay(date),
            moodLevel: MoodLevel(rawValue: mood),
            anxietyLevel: AnxietyLevel(rawValue: anxiety),
            anhedoniaLevel: AnhedoniaLevel(rawValue: anhedonia),
            notes: generateNote(pattern: pattern, dayIndex: dayIndex)
        )

        // Add sleep data
        if options.includeSleep {
            entry.sleepHours = generateSleepHours(pattern: pattern, progress: progress)
            entry.sleepQualityRating = Int(entry.sleepHours! / 2)  // Simple quality based on hours
        }

        // Add exercise
        if options.includeExercise {
            // More exercise correlates with better mood
            let exerciseChance = pattern == .improving ? 0.6 : 0.3
            if Double.random(in: 0...1) < exerciseChance {
                entry.exerciseMinutes = Double.random(in: 20...60)
            }
        }

        // Add daylight
        if options.includeDaylight {
            entry.timeInDaylightMinutes = Double.random(in: 15...90)
        }

        // Add medications
        if options.includeMedications && !medications.isEmpty {
            var meds: [Medication] = []

            for userMed in medications {
                // Adherence varies by pattern
                let adherenceRate = pattern == .improving ? 0.9 : 0.7
                if Double.random(in: 0...1) < adherenceRate {
                    let med = Medication(
                        name: userMed.name?.replacingOccurrences(of: "[TEST] ", with: "") ?? "",
                        dosage: userMed.dosage,
                        timestamp: morningTime(for: date),
                        taken: true
                    )
                    meds.append(med)
                }
            }

            entry.medications = meds
        }

        // Add substances
        if options.includeSubstances && !substances.isEmpty {
            var subs: [Substance] = []

            // Coffee in the morning (most days)
            if let coffee = substances.first(where: { $0.name?.contains("Coffee") == true }) {
                if Double.random(in: 0...1) < 0.8 {
                    let sub = Substance(
                        name: coffee.name?.replacingOccurrences(of: "[TEST] ", with: "") ?? "",
                        amount: Double.random(in: 1...3),
                        unit: .cups,
                        timestamp: morningTime(for: date)
                    )
                    subs.append(sub)
                }
            }

            // Alcohol on weekends or bad days
            if let alcohol = substances.first(where: { $0.name?.contains("Alcohol") == true }) {
                let isWeekend = Calendar.current.isDateInWeekend(date)
                let drinkChance = isWeekend ? 0.6 : (pattern == .worsening ? 0.4 : 0.2)

                if Double.random(in: 0...1) < drinkChance {
                    let sub = Substance(
                        name: alcohol.name?.replacingOccurrences(of: "[TEST] ", with: "") ?? "",
                        amount: Double.random(in: 1...3),
                        unit: .drinks,
                        timestamp: eveningTime(for: date)
                    )
                    subs.append(sub)
                }
            }

            entry.substances = subs
        }

        return entry
    }

    // MARK: - Symptom Calculation

    private func calculateSymptoms(
        progress: Double,
        pattern: DataPattern,
        dayIndex: Int
    ) -> (mood: Int, anxiety: Int, anhedonia: Int) {

        let variation = Double.random(in: -0.5...0.5)

        switch pattern {
        case .improving:
            // Symptoms improve over time
            let mood = min(5, Int(2 + progress * 3 + variation))
            let anxiety = max(1, Int(4 - progress * 2 + variation))
            let anhedonia = max(1, Int(4 - progress * 2 + variation))
            return (mood, anxiety, anhedonia)

        case .worsening:
            // Symptoms worsen over time
            let mood = max(1, Int(4 - progress * 2 + variation))
            let anxiety = min(5, Int(2 + progress * 3 + variation))
            let anhedonia = min(5, Int(2 + progress * 2 + variation))
            return (mood, anxiety, anhedonia)

        case .stable:
            // Symptoms remain relatively constant
            let mood = Int(3 + variation)
            let anxiety = Int(3 + variation)
            let anhedonia = Int(3 + variation)
            return (mood, anxiety, anhedonia)

        case .variable:
            // Realistic variation with weekly patterns
            let weekProgress = Double(dayIndex % 7) / 7.0
            let mood = Int(3 + sin(weekProgress * .pi * 2) + variation)
            let anxiety = Int(3 + cos(weekProgress * .pi * 2) * 0.5 + variation)
            let anhedonia = Int(3 + variation)
            return (
                max(1, min(5, mood)),
                max(1, min(5, anxiety)),
                max(1, min(5, anhedonia))
            )
        }
    }

    // MARK: - Helper Methods

    private func generateSleepHours(pattern: DataPattern, progress: Double) -> Double {
        switch pattern {
        case .improving:
            return 6.0 + progress * 2.0 + Double.random(in: -1...1)
        case .worsening:
            return 8.0 - progress * 2.0 + Double.random(in: -1...1)
        case .stable:
            return 7.0 + Double.random(in: -1...1)
        case .variable:
            return Double.random(in: 5...9)
        }
    }

    private func generateNote(pattern: DataPattern, dayIndex: Int) -> String {
        let notes = [
            "Test entry - Day \(dayIndex + 1)",
            pattern == .improving ? "Feeling a bit better today" : "",
            pattern == .worsening ? "Struggling today" : "",
            dayIndex % 7 == 0 ? "Weekly check-in" : ""
        ].filter { !$0.isEmpty }

        return notes.randomElement() ?? "Test entry"
    }

    private func randomTimeOnDay(_ date: Date) -> Date {
        let calendar = Calendar.current
        let hour = Int.random(in: 8...22)
        let minute = Int.random(in: 0...59)

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private func morningTime(for date: Date) -> Date {
        let calendar = Calendar.current
        let hour = Int.random(in: 7...9)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }

    private func eveningTime(for date: Date) -> Date {
        let calendar = Calendar.current
        let hour = Int.random(in: 18...22)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }

    // MARK: - Cleanup

    func clearAllTestData() async throws {
        // Delete test entries
        let entryDescriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { entry in
                entry.notes?.contains("Test entry") == true
            }
        )

        let testEntries = try modelContext.fetch(entryDescriptor)
        for entry in testEntries {
            modelContext.delete(entry)
        }

        // Delete test medications
        let medDescriptor = FetchDescriptor<UserMedication>(
            predicate: #Predicate { med in
                med.name?.contains("[TEST]") == true
            }
        )

        let testMeds = try modelContext.fetch(medDescriptor)
        for med in testMeds {
            modelContext.delete(med)
        }

        // Delete test substances
        let subDescriptor = FetchDescriptor<UserSubstance>(
            predicate: #Predicate { sub in
                sub.name?.contains("[TEST]") == true
            }
        )

        let testSubs = try modelContext.fetch(subDescriptor)
        for sub in testSubs {
            modelContext.delete(sub)
        }

        try modelContext.save()
    }
}
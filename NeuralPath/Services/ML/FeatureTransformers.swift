//
//  FeatureTransformers.swift
//  NeuralPath
//
//  Data transformation logic for ML feature extraction
//

import Foundation

// MARK: - Emotion Transformer

struct EmotionTransformer {

    private let clinicalPositive: Set<Emotion> = [.calm, .energetic, .confident, .hopeful]
    private let clinicalNegative: Set<Emotion> = [.hopeless, .anxious, .overwhelmed, .numb]

    func transform(_ emotions: [Emotion]) -> EmotionFeatures {
        let positive = emotions.filter { $0.valence == .positive }
        let negative = emotions.filter { $0.valence == .negative }
        let neutral = emotions.filter { $0.valence == .neutral }
        let total = Double(emotions.count)

        return EmotionFeatures(
            positiveCount: Double(positive.count) / 10.0,
            negativeCount: Double(negative.count) / 10.0,
            neutralCount: Double(neutral.count) / 8.0,
            emotionalIntensity: total / 28.0,
            valenceBalance: total > 0 ? Double(positive.count - negative.count) / total : 0,
            hasHopeless: emotions.contains(.hopeless) ? 1.0 : 0.0,
            hasAnxious: emotions.contains(.anxious) ? 1.0 : 0.0,
            hasOverwhelmed: emotions.contains(.overwhelmed) ? 1.0 : 0.0,
            hasNumb: emotions.contains(.numb) ? 1.0 : 0.0,
            hasCalm: emotions.contains(.calm) ? 1.0 : 0.0,
            hasEnergetic: emotions.contains(.energetic) ? 1.0 : 0.0
        )
    }
}

// MARK: - Medication Transformer

struct MedicationTransformer {

    private let antidepressantCategories: Set<MedicationCategory> = [
        .ssri, .snri, .tca, .tetracyclic, .maoi, .ndri, .nassa, .sari, .sms,
        .melatonergic, .atypicalAntidepressant
    ]

    private let anxiolyticCategories: Set<MedicationCategory> = [
        .benzodiazepine, .buspirone, .sleepAid
    ]

    private let moodStabilizerCategories: Set<MedicationCategory> = [
        .antipsychotic, .moodStabilizer, .lithium, .anticonvulsant
    ]

    private let stimulantCategories: Set<MedicationCategory> = [
        .stimulant, .nonStimulantADHD
    ]

    func transform(
        activeMedications: [UserMedication],
        logs: [MedicationLog],
        forDate date: Date,
        regimenEvents: [MedicationRegimenEvent] = []
    ) -> MedicationFeatures {
        var features = MedicationFeatures()

        // Category presence
        let activeCategories = Set(activeMedications.compactMap { $0.category })

        features.antidepressantActive = activeCategories.intersection(antidepressantCategories).isEmpty ? 0 : 1
        features.anxiolyticActive = activeCategories.intersection(anxiolyticCategories).isEmpty ? 0 : 1
        features.moodStabilizerActive = activeCategories.intersection(moodStabilizerCategories).isEmpty ? 0 : 1
        features.stimulantActive = activeCategories.intersection(stimulantCategories).isEmpty ? 0 : 1
        features.supplementActive = activeCategories.contains(.supplement) ? 1 : 0

        // Specific categories
        features.ssriActive = activeCategories.contains(.ssri) ? 1 : 0
        features.snriActive = activeCategories.contains(.snri) ? 1 : 0
        features.benzodiazepineActive = activeCategories.contains(.benzodiazepine) ? 1 : 0
        features.antipsychoticActive = activeCategories.contains(.antipsychotic) ? 1 : 0

        // PRN medications
        features.hasPRNMedication = activeMedications.contains { $0.frequency == .asNeeded } ? 1 : 0

        // Total active medications (normalized, cap at 10)
        features.totalActiveMedications = min(Double(activeMedications.count), 10) / 10.0

        // Calculate adherence rate for the day
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let dayLogs = logs.filter { log in
            guard let logDate = log.timestamp else { return false }
            return logDate >= dayStart && logDate < dayEnd
        }

        let scheduledMeds = activeMedications.filter { $0.frequency != .asNeeded }
        if !scheduledMeds.isEmpty {
            let expectedDoses = calculateExpectedDoses(medications: scheduledMeds)
            let actualDoses = dayLogs.count
            features.medicationAdherenceRate = min(Double(actualDoses) / Double(max(1, expectedDoses)), 1.0)
        }

        // Days since last dose
        if let lastLog = logs.sorted(by: { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }).first,
           let lastDate = lastLog.timestamp {
            let days = Calendar.current.dateComponents([.day], from: lastDate, to: date).day ?? 0
            features.daysSinceLastDose = min(Double(days), 7) / 7.0
        } else {
            features.daysSinceLastDose = 1.0
        }

        // Average daily doses
        let frequencyDoses: [MedicationFrequency: Double] = [
            .onceDaily: 1, .twiceDaily: 2, .threeTimesDaily: 3, .fourTimesDaily: 4,
            .weekly: 0.14, .everyOtherDay: 0.5, .asNeeded: 0
        ]
        let totalExpected = activeMedications.reduce(0.0) { sum, med in
            sum + (frequencyDoses[med.frequency ?? .onceDaily] ?? 1)
        }
        features.averageDailyDoses = min(totalExpected, 10) / 10.0

        // Regimen change features
        if let mostRecentChange = regimenEvents.sorted(by: { $0.date > $1.date }).first {
            let daysSinceChange = Calendar.current.dateComponents([.day], from: mostRecentChange.date, to: date).day ?? 90
            features.daysSinceLastMedChange = min(Double(daysSinceChange), 90) / 90.0
            features.isInTransitionPeriod = daysSinceChange <= 14 ? 1 : 0
            features.stabilizationScore = min(Double(daysSinceChange), 90) / 90.0

            switch mostRecentChange.type {
            case .started: features.recentChangeType = 0.33
            case .stopped: features.recentChangeType = 0.66
            case .dosageChange: features.recentChangeType = 1.0
            case .resumed: features.recentChangeType = 0.33
            }
        }

        return features
    }

    private func calculateExpectedDoses(medications: [UserMedication]) -> Int {
        medications.reduce(0) { sum, med in
            switch med.frequency ?? .onceDaily {
            case .onceDaily: return sum + 1
            case .twiceDaily: return sum + 2
            case .threeTimesDaily: return sum + 3
            case .fourTimesDaily: return sum + 4
            case .weekly, .everyOtherDay, .asNeeded: return sum
            }
        }
    }

    func detectRegimenChanges(
        medications: [UserMedication],
        since startDate: Date
    ) -> [MedicationRegimenEvent] {
        var events: [MedicationRegimenEvent] = []

        for med in medications {
            // Check for start events
            if let start = med.startDate, start >= startDate {
                events.append(MedicationRegimenEvent(
                    date: start,
                    type: .started,
                    medicationName: med.name ?? "Unknown",
                    medicationCategory: med.category,
                    previousDosage: nil,
                    newDosage: med.dosage
                ))
            }

            // Check for end events
            if let end = med.endDate, end >= startDate {
                events.append(MedicationRegimenEvent(
                    date: end,
                    type: .stopped,
                    medicationName: med.name ?? "Unknown",
                    medicationCategory: med.category,
                    previousDosage: med.dosage,
                    newDosage: nil
                ))
            }
        }

        return events.sorted { $0.date < $1.date }
    }

    func parseDosage(_ dosageString: String?) -> Double? {
        guard let dosage = dosageString else { return nil }
        let pattern = #"(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: dosage, range: NSRange(dosage.startIndex..., in: dosage)),
              let range = Range(match.range(at: 1), in: dosage) else {
            return nil
        }
        return Double(dosage[range])
    }
}

// MARK: - Temporal Transformer

struct TemporalTransformer {

    func transform(
        entry: SymptomEntry,
        historicalEntries: [SymptomEntry],
        mindfulnessLogs: [MindfulnessLog] = []
    ) -> TemporalFeatures {
        var features = TemporalFeatures()

        let timestamp = entry.timestamp ?? Date()
        let calendar = Calendar.current

        // Day of week (cyclical encoding)
        let dayOfWeek = Double(calendar.component(.weekday, from: timestamp) - 1) // 0-6
        features.dayOfWeekSin = sin(2 * .pi * dayOfWeek / 7)
        features.dayOfWeekCos = cos(2 * .pi * dayOfWeek / 7)
        features.isWeekend = (dayOfWeek == 0 || dayOfWeek == 6) ? 1 : 0

        // Hour of day (cyclical encoding)
        let hour = Double(calendar.component(.hour, from: timestamp))
        features.hourOfDaySin = sin(2 * .pi * hour / 24)
        features.hourOfDayCos = cos(2 * .pi * hour / 24)

        // Rolling averages (past 7 days)
        let recentEntries = historicalEntries
            .filter { entry in
                guard let entryDate = entry.timestamp else { return false }
                let daysDiff = calendar.dateComponents([.day], from: entryDate, to: timestamp).day ?? 0
                return daysDiff > 0 && daysDiff <= 7
            }
            .sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }

        if !recentEntries.isEmpty {
            // Mood averages and trends
            let moods = recentEntries.compactMap { $0.moodLevel?.rawValue }.map { Double($0) }
            if !moods.isEmpty {
                features.mood7DayAvg = moods.reduce(0, +) / Double(moods.count) / 5.0
                features.mood7DayTrend = calculateTrendSlope(moods)
            }

            // Anxiety averages and trends
            let anxieties = recentEntries.compactMap { $0.anxietyLevel?.rawValue }.map { Double($0) }
            if !anxieties.isEmpty {
                features.anxiety7DayAvg = anxieties.reduce(0, +) / Double(anxieties.count) / 4.0
                features.anxiety7DayTrend = calculateTrendSlope(anxieties)
            }

            // Anhedonia average
            let anhedonias = recentEntries.compactMap { $0.anhedoniaLevel?.rawValue }.map { Double($0) }
            if !anhedonias.isEmpty {
                features.anhedonia7DayAvg = anhedonias.reduce(0, +) / Double(anhedonias.count) / 4.0
            }
        }

        // Days since last entry
        if let lastEntry = historicalEntries.last,
           let lastDate = lastEntry.timestamp {
            let days = calendar.dateComponents([.day], from: lastDate, to: timestamp).day ?? 0
            features.daysSinceLastEntry = min(Double(max(0, days)), 7) / 7.0
        }

        // Days since last mindfulness
        if let lastMindfulness = mindfulnessLogs.sorted(by: { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }).first,
           let lastDate = lastMindfulness.timestamp {
            let days = calendar.dateComponents([.day], from: lastDate, to: timestamp).day ?? 0
            features.daysSinceLastMindfulness = min(Double(max(0, days)), 7) / 7.0
        }

        // Days since last exercise
        let exerciseEntries = historicalEntries.filter { ($0.exerciseMinutes ?? 0) > 10 }
        if let lastExercise = exerciseEntries.last,
           let lastDate = lastExercise.timestamp {
            let days = calendar.dateComponents([.day], from: lastDate, to: timestamp).day ?? 0
            features.daysSinceLastExercise = min(Double(max(0, days)), 7) / 7.0
        }

        // Consecutive entry days (streak)
        features.consecutiveEntryDays = Double(calculateStreak(entries: historicalEntries, beforeDate: timestamp)) / 30.0

        return features
    }

    private func calculateTrendSlope(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let n = Double(values.count)
        let xMean = (n - 1) / 2
        let yMean = values.reduce(0, +) / n

        var numerator = 0.0
        var denominator = 0.0
        for (i, y) in values.enumerated() {
            let x = Double(i)
            numerator += (x - xMean) * (y - yMean)
            denominator += (x - xMean) * (x - xMean)
        }

        let slope = denominator > 0 ? numerator / denominator : 0
        return max(-1, min(1, slope)) // Normalize to -1 to 1
    }

    private func calculateStreak(entries: [SymptomEntry], beforeDate: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: beforeDate))!

        let sortedEntries = entries.sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }

        for entry in sortedEntries {
            guard let entryDate = entry.timestamp else { continue }
            if calendar.isDate(entryDate, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if entryDate < checkDate {
                break
            }
        }

        return min(streak, 30)
    }
}

// MARK: - Mindfulness Transformer

struct MindfulnessTransformer {

    func transform(
        todayLogs: [MindfulnessLog],
        practices: [UserMindfulness],
        historicalLogs: [MindfulnessLog] = [],
        forDate date: Date
    ) -> MindfulnessFeatures {
        var features = MindfulnessFeatures()

        // Get categories practiced today
        let todayCategories = Set(todayLogs.compactMap { log -> MindfulnessCategory? in
            // Find the practice to get category
            guard let practiceName = log.practiceName else { return nil }
            return practices.first { $0.name == practiceName }?.category
        })

        // Category presence
        features.meditationToday = todayCategories.contains(.meditation) ? 1 : 0
        features.breathingToday = todayCategories.contains(.breathing) ? 1 : 0
        features.yogaToday = todayCategories.contains(.yoga) ? 1 : 0
        features.journalingToday = todayCategories.contains(.journaling) ? 1 : 0
        features.bodyScanToday = todayCategories.contains(.bodyScan) ? 1 : 0
        features.relaxationToday = todayCategories.contains(.relaxation) ? 1 : 0
        features.walkingToday = todayCategories.contains(.walking) ? 1 : 0
        features.gratitudeToday = todayCategories.contains(.gratitude) ? 1 : 0

        // Total practices today
        features.totalPracticesToday = min(Double(todayLogs.count), 8) / 8.0

        // Total minutes today
        let totalMinutes = todayLogs.reduce(0.0) { sum, log in
            guard let practiceName = log.practiceName,
                  let practice = practices.first(where: { $0.name == practiceName }) else {
                return sum
            }
            return sum + Double(practice.durationMinutes ?? 10)
        }
        features.totalMinutesToday = min(totalMinutes, 120) / 120.0

        // 7-day variety
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: date)!
        let weekLogs = historicalLogs.filter { log in
            guard let logDate = log.timestamp else { return false }
            return logDate >= weekAgo && logDate <= date
        }
        let weekCategories = Set(weekLogs.compactMap { log -> MindfulnessCategory? in
            guard let practiceName = log.practiceName else { return nil }
            return practices.first { $0.name == practiceName }?.category
        })
        features.practiceVariety7Day = Double(weekCategories.count) / 8.0

        // Average daily practices (7-day)
        var dayPracticeCounts: [Int] = []
        for dayOffset in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: date))!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayCount = historicalLogs.filter { log in
                guard let logDate = log.timestamp else { return false }
                return logDate >= dayStart && logDate < dayEnd
            }.count
            dayPracticeCounts.append(dayCount)
        }
        features.averageDailyPractices = Double(dayPracticeCounts.reduce(0, +)) / 7.0 / 8.0

        return features
    }
}

// MARK: - Self-Care Transformer

struct SelfCareTransformer {

    func transform(
        todayLogs: [SelfCareLog],
        practices: [UserSelfCare],
        historicalLogs: [SelfCareLog] = [],
        forDate date: Date
    ) -> SelfCareFeatures {
        var features = SelfCareFeatures()

        // Get active practices by time of day
        let activePractices = practices.filter { $0.isActive == true }
        let morningPractices = activePractices.filter { $0.timeOfDay == SelfCareTimeOfDay.morning }
        let afternoonPractices = activePractices.filter { $0.timeOfDay == SelfCareTimeOfDay.afternoon }
        let eveningPractices = activePractices.filter { $0.timeOfDay == SelfCareTimeOfDay.evening }

        // Get completed by time of day
        let morningCompleted = todayLogs.filter { $0.timeOfDay == SelfCareTimeOfDay.morning }
        let afternoonCompleted = todayLogs.filter { $0.timeOfDay == SelfCareTimeOfDay.afternoon }
        let eveningCompleted = todayLogs.filter { $0.timeOfDay == SelfCareTimeOfDay.evening }

        // Completion rates
        features.morningCompletionRate = morningPractices.isEmpty ? 0 :
            min(Double(morningCompleted.count) / Double(morningPractices.count), 1.0)
        features.afternoonCompletionRate = afternoonPractices.isEmpty ? 0 :
            min(Double(afternoonCompleted.count) / Double(afternoonPractices.count), 1.0)
        features.eveningCompletionRate = eveningPractices.isEmpty ? 0 :
            min(Double(eveningCompleted.count) / Double(eveningPractices.count), 1.0)

        // Total completion rate
        let totalActive = activePractices.count
        features.totalCompletionRate = totalActive == 0 ? 0 :
            min(Double(todayLogs.count) / Double(totalActive), 1.0)

        // 7-day consistency
        let calendar = Calendar.current
        var daysWithActivity = 0
        for dayOffset in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: date))!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let hasActivity = historicalLogs.contains { log in
                guard let logDate = log.timestamp else { return false }
                return logDate >= dayStart && logDate < dayEnd
            }
            if hasActivity { daysWithActivity += 1 }
        }
        features.consistencyScore7Day = Double(daysWithActivity) / 7.0

        // Time of day balance (1 - variance)
        let rates = [features.morningCompletionRate, features.afternoonCompletionRate, features.eveningCompletionRate]
        let mean = rates.reduce(0, +) / 3.0
        let variance = rates.map { pow($0 - mean, 2) }.reduce(0, +) / 3.0
        features.timeOfDayBalance = max(0, 1 - sqrt(variance))

        return features
    }
}

// MARK: - Lifestyle Transformer

struct LifestyleTransformer {

    private let defaultSleepHours = 7.5
    private let defaultExerciseMinutes = 0.0
    private let defaultDaylightMinutes = 30.0

    func transform(entry: SymptomEntry) -> LifestyleFeatures {
        var features = LifestyleFeatures()

        // Sleep hours (normalize: 4-12 hours -> 0-1)
        let sleep = entry.sleepHours ?? defaultSleepHours
        features.sleepHoursNormalized = max(0, min(1, (sleep - 4) / 8))

        // Sleep quality
        let quality = entry.sleepQualityRating ?? 3
        features.sleepQualityNormalized = Double(quality) / 5.0

        // Exercise minutes (cap at 120)
        let exercise = entry.exerciseMinutes ?? defaultExerciseMinutes
        features.exerciseMinutesNormalized = min(exercise, 120) / 120.0

        // Daylight minutes (cap at 180)
        let daylight = entry.timeInDaylightMinutes ?? defaultDaylightMinutes
        features.daylightMinutesNormalized = min(daylight, 180) / 180.0

        return features
    }
}

// MARK: - Interaction Transformer

struct InteractionTransformer {

    func transform(
        entry: SymptomEntry,
        previousEntry: SymptomEntry?,
        medications: MedicationFeatures,
        mindfulness: MindfulnessFeatures
    ) -> InteractionFeatures {
        var features = InteractionFeatures()

        let sleepHours = entry.sleepHours ?? 7.5
        let sleepQuality = Double(entry.sleepQualityRating ?? 3) / 5.0
        let exercise = entry.exerciseMinutes ?? 0
        let daylight = entry.timeInDaylightMinutes ?? 0
        let anxiety = Double(entry.anxietyLevel?.rawValue ?? 2) / 4.0
        let mood = Double(entry.moodLevel?.rawValue ?? 3) / 5.0

        // Sleep interactions
        features.sleepMedicationInteraction = (sleepHours / 12.0) * medications.anxiolyticActive
        features.sleepExerciseInteraction = (sleepHours / 12.0) * min(exercise, 120) / 120.0
        features.sleepAnxietyInteraction = sleepQuality * (1 - anxiety)

        // Exercise interactions
        if let prev = previousEntry {
            let prevExercise = prev.exerciseMinutes ?? 0
            features.exerciseMoodLag = min(prevExercise, 120) / 120.0 * mood
        }
        features.exerciseDaylightInteraction = min(exercise, 120) / 120.0 * min(daylight, 180) / 180.0

        // Mindfulness interactions
        let mindfulnessActive = mindfulness.totalPracticesToday > 0 ? 1.0 : 0.0
        features.mindfulnessAnxietyReduction = mindfulnessActive * anxiety
        features.mindfulnessConsistencyBonus = mindfulness.averageDailyPractices * mood

        // Medication interactions
        features.medicationSleepInteraction = medications.antidepressantActive * sleepQuality
        features.medicationAdherenceMood = medications.medicationAdherenceRate * mood

        return features
    }
}

// MARK: - Missing Data Handler

struct MissingDataHandler {
    let minimumEntriesForRollingWindow = 3
    let sleepHoursDefault = 7.5
    let exerciseMinutesDefault = 0.0
    let daylightMinutesMedian = 30.0

    func filterValidEntries(_ entries: [SymptomEntry]) -> [SymptomEntry] {
        entries.filter { entry in
            entry.moodLevel != nil &&
            entry.anxietyLevel != nil &&
            entry.anhedoniaLevel != nil
        }
    }

    func canComputeRollingFeatures(historicalCount: Int) -> Bool {
        historicalCount >= minimumEntriesForRollingWindow
    }
}

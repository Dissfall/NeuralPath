//
//  MLAnalysisEngine.swift
//  NeuralPath
//
//  CoreML integration for ML-based analysis
//

import Foundation
import CoreML
import TabularData

@MainActor
@Observable
class MLAnalysisEngine {

    enum ModelStatus: Equatable {
        case notLoaded
        case loading
        case ready
        case failed(String)
        case insufficientData

        static func == (lhs: ModelStatus, rhs: ModelStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notLoaded, .notLoaded): return true
            case (.loading, .loading): return true
            case (.ready, .ready): return true
            case (.failed(let l), .failed(let r)): return l == r
            case (.insufficientData, .insufficientData): return true
            default: return false
            }
        }
    }

    // Model status
    var moodPredictorStatus: ModelStatus = .notLoaded
    var patternMatcherStatus: ModelStatus = .notLoaded
    var forecasterStatus: ModelStatus = .notLoaded

    // Models
    private var moodPredictor: MLModel?
    private var patternMatcherData: [MLFeatureVector] = []
    private var forecasterTrained: Bool = false

    // Configuration
    private let minimumEntriesForPrediction = 30
    private let minimumEntriesForForecasting = 14
    private let knnNeighbors = 5

    // MARK: - Initialization

    init() {}

    // MARK: - Model Loading

    func loadBundledModels() async throws {
        moodPredictorStatus = .loading

        // Try to load bundled mood predictor model
        if let modelURL = Bundle.main.url(forResource: "MoodPredictor", withExtension: "mlmodelc") {
            do {
                moodPredictor = try MLModel(contentsOf: modelURL)
                moodPredictorStatus = .ready
            } catch {
                print("Failed to load bundled MoodPredictor: \(error)")
                moodPredictorStatus = .failed(error.localizedDescription)
            }
        } else {
            // No bundled model - will use pattern matching fallback
            moodPredictorStatus = .notLoaded
        }
    }

    // MARK: - Pattern Matcher (k-NN)

    func trainPatternMatcher(data: [MLFeatureVector]) async throws {
        guard data.count >= minimumEntriesForPrediction else {
            patternMatcherStatus = .insufficientData
            throw MLError.insufficientData(have: data.count, need: minimumEntriesForPrediction)
        }

        patternMatcherStatus = .loading
        patternMatcherData = data
        patternMatcherStatus = .ready
    }

    func findSimilarDays(features: MLFeatureVector, count: Int = 5) async -> [SimilarDay] {
        guard !patternMatcherData.isEmpty else { return [] }

        let inputArray = features.toArray()

        // Calculate distances to all historical entries
        var distances: [(vector: MLFeatureVector, distance: Double)] = []

        for historical in patternMatcherData {
            let historicalArray = historical.toArray()
            let distance = euclideanDistance(inputArray, historicalArray)
            distances.append((historical, distance))
        }

        // Sort by distance and take top k
        let sorted = distances.sorted { $0.distance < $1.distance }
        let topK = sorted.prefix(count)

        // Convert to SimilarDay
        return topK.compactMap { item in
            guard let mood = getMoodFromTarget(item.vector.targetMood) else { return nil }

            // Calculate similarity (inverse of normalized distance)
            let maxDistance = sorted.last?.distance ?? 1.0
            let similarity = maxDistance > 0 ? 1.0 - (item.distance / maxDistance) : 1.0

            // Identify key factors that differ
            let keyFactors = identifyKeyFactors(current: features, historical: item.vector)

            return SimilarDay(
                entryId: item.vector.entryId,
                date: item.vector.timestamp,
                similarity: similarity,
                mood: mood,
                keyFactors: keyFactors
            )
        }
    }

    private func euclideanDistance(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return Double.infinity }
        var sum = 0.0
        for i in 0..<a.count {
            sum += pow(a[i] - b[i], 2)
        }
        return sqrt(sum)
    }

    private func getMoodFromTarget(_ target: Double?) -> MoodLevel? {
        guard let t = target else { return nil }
        let rawValue = Int(round(t * 5))
        return MoodLevel(rawValue: max(1, min(5, rawValue)))
    }

    private func identifyKeyFactors(current: MLFeatureVector, historical: MLFeatureVector) -> [String] {
        var factors: [String] = []

        // Check emotional state
        if abs(current.emotions.valenceBalance - historical.emotions.valenceBalance) > 0.3 {
            if historical.emotions.valenceBalance > current.emotions.valenceBalance {
                factors.append("More positive emotions")
            } else {
                factors.append("Fewer negative emotions")
            }
        }

        // Check sleep
        if abs(current.lifestyle.sleepHoursNormalized - historical.lifestyle.sleepHoursNormalized) > 0.2 {
            if historical.lifestyle.sleepHoursNormalized > current.lifestyle.sleepHoursNormalized {
                factors.append("Better sleep")
            }
        }

        // Check exercise
        if abs(current.lifestyle.exerciseMinutesNormalized - historical.lifestyle.exerciseMinutesNormalized) > 0.3 {
            if historical.lifestyle.exerciseMinutesNormalized > current.lifestyle.exerciseMinutesNormalized {
                factors.append("More exercise")
            }
        }

        // Check mindfulness
        if historical.mindfulness.totalPracticesToday > current.mindfulness.totalPracticesToday + 0.2 {
            factors.append("Mindfulness practice")
        }

        return factors
    }

    // MARK: - Mood Prediction

    func predictTomorrowMood(features: MLFeatureVector) async -> MoodPrediction? {
        // If we have a trained model, use it
        if let model = moodPredictor {
            return await predictWithModel(model, features: features)
        }

        // Otherwise, use k-NN based prediction
        return await predictWithKNN(features: features)
    }

    private func predictWithModel(_ model: MLModel, features: MLFeatureVector) async -> MoodPrediction? {
        do {
            let featureArray = features.toArray()

            // Create MLMultiArray from features
            let multiArray = try MLMultiArray(shape: [NSNumber(value: featureArray.count)], dataType: .double)
            for (i, value) in featureArray.enumerated() {
                multiArray[i] = NSNumber(value: value)
            }

            // Create feature provider
            let featureProvider = try MLDictionaryFeatureProvider(dictionary: ["features": multiArray])

            // Get prediction
            let prediction = try await model.prediction(from: featureProvider)

            // Extract mood prediction
            if let moodValue = prediction.featureValue(for: "mood")?.doubleValue {
                let rawMood = Int(round(moodValue * 5))
                if let mood = MoodLevel(rawValue: max(1, min(5, rawMood))) {
                    let confidence = prediction.featureValue(for: "confidence")?.doubleValue ?? 0.7

                    return MoodPrediction(
                        level: mood,
                        confidence: confidence,
                        contributingFactors: extractContributingFactors(features: features)
                    )
                }
            }
        } catch {
            print("Prediction with model failed: \(error)")
        }

        // Fallback to k-NN
        return await predictWithKNN(features: features)
    }

    private func predictWithKNN(features: MLFeatureVector) async -> MoodPrediction? {
        let similarDays = await findSimilarDays(features: features, count: knnNeighbors)
        guard !similarDays.isEmpty else { return nil }

        // Weighted average of similar days' moods
        var weightedSum = 0.0
        var totalWeight = 0.0

        for day in similarDays {
            let weight = day.similarity
            weightedSum += Double(day.mood.rawValue) * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return nil }

        let predictedValue = weightedSum / totalWeight
        let rawMood = Int(round(predictedValue))

        guard let mood = MoodLevel(rawValue: max(1, min(5, rawMood))) else { return nil }

        // Confidence based on similarity spread
        let avgSimilarity = similarDays.map(\.similarity).reduce(0, +) / Double(similarDays.count)

        return MoodPrediction(
            level: mood,
            confidence: avgSimilarity,
            contributingFactors: extractContributingFactors(features: features)
        )
    }

    private func extractContributingFactors(features: MLFeatureVector) -> [(name: String, impact: Double)] {
        var factors: [(String, Double)] = []

        // Sleep impact
        let sleepImpact = (features.lifestyle.sleepHoursNormalized - 0.5) * 2
        if abs(sleepImpact) > 0.2 {
            factors.append(("Sleep", sleepImpact))
        }

        // Exercise impact
        if features.lifestyle.exerciseMinutesNormalized > 0.3 {
            factors.append(("Exercise", features.lifestyle.exerciseMinutesNormalized))
        }

        // Emotional valence impact
        if abs(features.emotions.valenceBalance) > 0.2 {
            factors.append(("Emotional State", features.emotions.valenceBalance))
        }

        // Mindfulness impact
        if features.mindfulness.totalPracticesToday > 0 {
            factors.append(("Mindfulness", features.mindfulness.totalPracticesToday))
        }

        // Medication adherence impact
        if features.medications.medicationAdherenceRate > 0.8 {
            factors.append(("Medication Adherence", 0.3))
        } else if features.medications.medicationAdherenceRate < 0.5 && features.medications.totalActiveMedications > 0 {
            factors.append(("Medication Adherence", -0.3))
        }

        // Sort by absolute impact
        return factors.sorted { abs($0.1) > abs($1.1) }
    }

    // MARK: - Time Series Forecasting

    func trainForecaster(entries: [SymptomEntry]) async throws {
        guard entries.count >= minimumEntriesForForecasting else {
            forecasterStatus = .insufficientData
            throw MLError.insufficientData(have: entries.count, need: minimumEntriesForForecasting)
        }

        forecasterStatus = .loading

        // Store entries for forecasting (simple statistical approach)
        // NOTE: Full ML-based forecasting requires Create ML Components
        // which is only available on macOS. On iOS, we use linear
        // extrapolation as a fallback approach.
        forecasterTrained = true
        forecasterStatus = .ready
    }

    func forecast7Days(entries: [SymptomEntry]) async -> [ForecastPoint] {
        guard entries.count >= minimumEntriesForForecasting else { return [] }

        // Simple linear extrapolation fallback
        // In production, this would use the trained TimeSeriesForecaster
        let recentMoods = entries.suffix(14).compactMap { entry -> (Date, Double)? in
            guard let date = entry.timestamp, let mood = entry.moodLevel else { return nil }
            return (date, Double(mood.rawValue))
        }

        guard recentMoods.count >= 7 else { return [] }

        // Calculate trend
        let trend = calculateTrend(values: recentMoods.map(\.1))
        let lastMood = recentMoods.last?.1 ?? 3.0
        let lastDate = recentMoods.last?.0 ?? Date()

        // Generate 7-day forecast
        var forecast: [ForecastPoint] = []

        for day in 1...7 {
            let forecastDate = Calendar.current.date(byAdding: .day, value: day, to: lastDate)!
            let predictedMood = max(1, min(5, lastMood + trend * Double(day)))

            // Confidence decreases with distance
            let baseConfidence = 0.8
            let confidenceDecay = 0.05 * Double(day)
            let confidence = baseConfidence - confidenceDecay

            // Convert to 0-1 normalized score
            let normalizedScore = (predictedMood - 1) / 4.0
            let confidenceInterval = (1 - confidence) * 0.25

            forecast.append(ForecastPoint(
                date: forecastDate,
                predictedScore: normalizedScore,
                confidenceInterval: confidenceInterval
            ))
        }

        return forecast
    }

    private func calculateTrend(values: [Double]) -> Double {
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

        return denominator > 0 ? numerator / denominator : 0
    }

    // MARK: - Pattern Detection

    func detectPatterns(entries: [SymptomEntry]) async -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        // Detect weekly patterns
        if let weeklyPattern = detectWeeklyPattern(entries: entries) {
            patterns.append(weeklyPattern)
        }

        // Detect sleep correlation
        if let sleepPattern = detectSleepCorrelation(entries: entries) {
            patterns.append(sleepPattern)
        }

        // Detect exercise benefit
        if let exercisePattern = detectExerciseBenefit(entries: entries) {
            patterns.append(exercisePattern)
        }

        // Detect medication effects (requires regimen data)
        // This would be expanded in production

        return patterns
    }

    private func detectWeeklyPattern(entries: [SymptomEntry]) -> DetectedPattern? {
        guard entries.count >= 21 else { return nil } // Need at least 3 weeks

        var dayMoods: [Int: [Double]] = [:]

        for entry in entries {
            guard let date = entry.timestamp,
                  let mood = entry.moodLevel else { continue }
            let weekday = Calendar.current.component(.weekday, from: date)
            dayMoods[weekday, default: []].append(Double(mood.rawValue))
        }

        // Calculate average mood per day
        var dayAverages: [Int: Double] = [:]
        for (day, moods) in dayMoods where moods.count >= 2 {
            dayAverages[day] = moods.reduce(0, +) / Double(moods.count)
        }

        guard dayAverages.count >= 5 else { return nil }

        // Find best and worst days
        let sorted = dayAverages.sorted { $0.value > $1.value }
        guard let bestDay = sorted.first,
              let worstDay = sorted.last else { return nil }

        let difference = bestDay.value - worstDay.value

        // Only report if significant difference
        guard difference >= 0.5 else { return nil }

        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let bestDayName = dayNames[bestDay.key]
        let worstDayName = dayNames[worstDay.key]

        return DetectedPattern(
            type: .weekly,
            description: "Your mood tends to be higher on \(bestDayName) and lower on \(worstDayName)",
            strength: min(1.0, difference / 2.0),
            confidence: Double(entries.count) / 90.0,
            actionable: true,
            recommendation: "Consider planning self-care activities for \(worstDayName)"
        )
    }

    private func detectSleepCorrelation(entries: [SymptomEntry]) -> DetectedPattern? {
        guard entries.count >= 14 else { return nil }

        var goodSleepMoods: [Double] = []
        var poorSleepMoods: [Double] = []

        for entry in entries {
            guard let mood = entry.moodLevel,
                  let sleep = entry.sleepHours else { continue }

            if sleep >= 7 {
                goodSleepMoods.append(Double(mood.rawValue))
            } else if sleep < 6 {
                poorSleepMoods.append(Double(mood.rawValue))
            }
        }

        guard goodSleepMoods.count >= 5 && poorSleepMoods.count >= 5 else { return nil }

        let goodAvg = goodSleepMoods.reduce(0, +) / Double(goodSleepMoods.count)
        let poorAvg = poorSleepMoods.reduce(0, +) / Double(poorSleepMoods.count)
        let difference = goodAvg - poorAvg

        guard difference >= 0.3 else { return nil }

        return DetectedPattern(
            type: .sleepCorrelation,
            description: "Your mood is typically \(Int(difference * 20))% better when you get 7+ hours of sleep",
            strength: min(1.0, difference / 1.5),
            confidence: min(1.0, Double(goodSleepMoods.count + poorSleepMoods.count) / 30.0),
            actionable: true,
            recommendation: "Prioritizing sleep could significantly improve your mood"
        )
    }

    private func detectExerciseBenefit(entries: [SymptomEntry]) -> DetectedPattern? {
        guard entries.count >= 14 else { return nil }

        var exerciseMoods: [Double] = []
        var noExerciseMoods: [Double] = []

        for entry in entries {
            guard let mood = entry.moodLevel else { continue }
            let exercise = entry.exerciseMinutes ?? 0

            if exercise >= 20 {
                exerciseMoods.append(Double(mood.rawValue))
            } else if exercise < 5 {
                noExerciseMoods.append(Double(mood.rawValue))
            }
        }

        guard exerciseMoods.count >= 5 && noExerciseMoods.count >= 5 else { return nil }

        let exerciseAvg = exerciseMoods.reduce(0, +) / Double(exerciseMoods.count)
        let noExerciseAvg = noExerciseMoods.reduce(0, +) / Double(noExerciseMoods.count)
        let difference = exerciseAvg - noExerciseAvg

        guard difference >= 0.3 else { return nil }

        return DetectedPattern(
            type: .exerciseBenefit,
            description: "Days with 20+ minutes of exercise show \(Int(difference * 20))% better mood",
            strength: min(1.0, difference / 1.5),
            confidence: min(1.0, Double(exerciseMoods.count + noExerciseMoods.count) / 30.0),
            actionable: true,
            recommendation: "Even a short walk can help improve your mood"
        )
    }

    // MARK: - Analysis Results

    func analyzeAll(
        features: MLFeatureVector,
        entries: [SymptomEntry]
    ) async -> MLAnalysisResult {
        async let prediction = predictTomorrowMood(features: features)
        async let similarDays = findSimilarDays(features: features, count: 5)
        async let patterns = detectPatterns(entries: entries)
        async let forecast = forecast7Days(entries: entries)

        let pred = await prediction
        let similar = await similarDays
        let pats = await patterns
        let fore = await forecast

        // Calculate overall ML confidence
        let predConfidence = pred?.confidence ?? 0
        let patternConfidence = pats.isEmpty ? 0 : pats.map(\.confidence).reduce(0, +) / Double(pats.count)
        let overallConfidence = (predConfidence + patternConfidence) / 2

        return MLAnalysisResult(
            prediction: pred,
            similarDays: similar,
            patterns: pats,
            forecast: fore,
            confidence: overallConfidence
        )
    }
}

// MARK: - ML Analysis Result

struct MLAnalysisResult {
    let prediction: MoodPrediction?
    let similarDays: [SimilarDay]
    let patterns: [DetectedPattern]
    let forecast: [ForecastPoint]
    let confidence: Double
}

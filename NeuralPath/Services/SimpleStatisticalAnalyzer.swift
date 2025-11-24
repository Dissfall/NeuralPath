import Foundation
import SwiftUI
import SwiftData
import Charts
import Observation

/// Simple statistical analyzer - NO ML REQUIRED!
/// Uses basic math to determine medication effectiveness and substance impacts
@MainActor
@Observable
class SimpleStatisticalAnalyzer {

    // MARK: - Analysis Results

    struct ComprehensiveAnalysis {
        let overallHealthScore: Double
        let overallTrend: TrendAnalysis
        let topPositiveFactors: [FactorImpact]
        let topNegativeFactors: [FactorImpact]
        let allFactors: [FactorImpact]
        let keyInsights: [String]
        let recommendations: [String]
        let lastUpdated: Date
    }

    struct FactorImpact: Identifiable {
        let id = UUID()
        let name: String
        let category: FactorCategory
        let impactScore: Double // -1 to 1
        let confidence: Double // 0 to 1
        let trend: TrendDirection
        let icon: String // SF Symbol name
        let detail: String // Brief explanation
    }

    enum FactorCategory: String, CaseIterable {
        case medication = "Medication"
        case substance = "Substance"
        case sleep = "Sleep"
        case exercise = "Exercise"
        case daylight = "Daylight"

        var icon: String {
            switch self {
            case .medication: return "pills.fill"
            case .substance: return "drop.triangle.fill"
            case .sleep: return "moon.zzz.fill"
            case .exercise: return "figure.run"
            case .daylight: return "sun.max.fill"
            }
        }

        var color: Color {
            switch self {
            case .medication: return .blue
            case .substance: return .purple
            case .sleep: return .indigo
            case .exercise: return .orange
            case .daylight: return .yellow
            }
        }
    }

    enum TrendDirection: String {
        case strongImprovement = "Strong Improvement"
        case improving = "Improving"
        case stable = "Stable"
        case worsening = "Worsening"
        case strongDecline = "Strong Decline"

        var icon: String {
            switch self {
            case .strongImprovement: return "arrow.up"
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .worsening: return "arrow.down.right"
            case .strongDecline: return "arrow.down"
            }
        }

        var color: Color {
            switch self {
            case .strongImprovement: return .green
            case .improving: return .mint
            case .stable: return .blue
            case .worsening: return .orange
            case .strongDecline: return .red
            }
        }
    }

    struct MedicationEffectiveness {
        let medicationName: String
        let beforeAverage: Double      // Symptom average before starting
        let afterAverage: Double       // Symptom average after starting
        let percentChange: Double      // % improvement/worsening
        let correlation: Double        // Correlation coefficient (-1 to 1)
        let confidence: Double         // Statistical confidence (0-1)
        let daysAnalyzed: Int
        let interpretation: Label<Text, Image> // Human-readable conclusion
        let isEffective: Bool         // Simple yes/no
    }

    struct SubstanceImpact {
        let substanceName: String
        let dayWithSubstance: SymptomAverage
        let dayAfterSubstance: SymptomAverage  // Next day effects
        let typicalDay: SymptomAverage          // Days without substance
        let impactScore: Double                 // -1 (harmful) to 1 (helpful)
        let interpretation: Label<Text, Image>
    }

    struct SymptomAverage {
        let mood: Double
        let anxiety: Double
        let anhedonia: Double

        var composite: Double {
            // Higher is better: good mood, low anxiety, low anhedonia
            return mood - (anxiety + anhedonia) / 2.0
        }
    }

    struct TrendAnalysis {
        let slope: Double              // Rate of change per day
        let intercept: Double          // Starting point
        let rSquared: Double          // How well line fits (0-1)
        let trending: Trending
        let daysToImprovement: Int?   // Estimated days to reach "good" level

        enum Trending {
            case improving, worsening, stable
        }
    }

    // MARK: - Core Analysis Methods (NO ML!)

    /// Analyzes if a medication is effective using simple before/after comparison
    func analyzeMedicationEffectiveness(
        medication: String,
        entries: [SymptomEntry]
    ) -> MedicationEffectiveness {

        // Find when medication started
        let startDate = findMedicationStartDate(medication: medication, entries: entries)

        // Split entries into before/after
        let beforeEntries = entries.filter { ($0.timestamp ?? Date.distantPast) < startDate }
        let afterEntries = entries.filter {
            ($0.timestamp ?? Date.distantPast) >= startDate &&
            ($0.medications?.contains { $0.name == medication } ?? false)
        }

        // Need minimum data for analysis
        guard beforeEntries.count >= 7, afterEntries.count >= 7 else {
            return MedicationEffectiveness(
                medicationName: medication,
                beforeAverage: 0,
                afterAverage: 0,
                percentChange: 0,
                correlation: 0,
                confidence: 0,
                daysAnalyzed: 0,
                interpretation: Label("Insufficient data (need at least 7 days before and after)", systemImage: "calendar.badge.clock"),
                isEffective: false
            )
        }

        // Calculate simple averages
        let beforeAvg = calculateSymptomAverage(beforeEntries)
        let afterAvg = calculateSymptomAverage(afterEntries)

        // Calculate improvement (positive = better)
        let improvement = afterAvg.composite - beforeAvg.composite
        let percentChange = (improvement / abs(beforeAvg.composite)) * 100

        // Calculate correlation between medication adherence and symptoms
        let correlation = calculateCorrelation(
            medicationEntries: afterEntries,
            medication: medication
        )

        // Statistical confidence based on sample size and consistency
        let confidence = calculateConfidence(
            sampleSize: afterEntries.count,
            standardDeviation: calculateStandardDeviation(afterEntries)
        )

        // Determine effectiveness
        let isEffective = percentChange > 20 && correlation > 0.3 && confidence > 0.6

        // Generate interpretation
        let interpretation = generateInterpretation(
            percentChange: percentChange,
            correlation: correlation,
            daysAnalyzed: afterEntries.count,
            isEffective: isEffective
        )

        return MedicationEffectiveness(
            medicationName: medication,
            beforeAverage: beforeAvg.composite,
            afterAverage: afterAvg.composite,
            percentChange: percentChange,
            correlation: correlation,
            confidence: confidence,
            daysAnalyzed: afterEntries.count,
            interpretation: interpretation,
            isEffective: isEffective
        )
    }

    /// Analyzes substance impact using day-of and day-after comparisons
    func analyzeSubstanceImpact(
        substance: String,
        entries: [SymptomEntry]
    ) -> SubstanceImpact {

        // Group entries by substance use
        let daysWithSubstance = entries.filter { entry in
            entry.substances?.contains { $0.name == substance } ?? false
        }

        let daysWithoutSubstance = entries.filter { entry in
            !(entry.substances?.contains { $0.name == substance } ?? false)
        }

        // Calculate next-day effects
        let dayAfterEffects = calculateDayAfterEffects(
            substanceDays: daysWithSubstance,
            allEntries: entries
        )

        // Calculate averages
        let withSubstanceAvg = calculateSymptomAverage(daysWithSubstance)
        let withoutSubstanceAvg = calculateSymptomAverage(daysWithoutSubstance)

        // Calculate impact score (-1 to 1)
        let impactScore = calculateImpactScore(
            withSubstance: withSubstanceAvg,
            without: withoutSubstanceAvg,
            dayAfter: dayAfterEffects
        )

        // Generate interpretation
        let interpretation = interpretSubstanceImpact(
            substance: substance,
            impactScore: impactScore,
            dayAfter: dayAfterEffects
        )

        return SubstanceImpact(
            substanceName: substance,
            dayWithSubstance: withSubstanceAvg,
            dayAfterSubstance: dayAfterEffects,
            typicalDay: withoutSubstanceAvg,
            impactScore: impactScore,
            interpretation: interpretation
        )
    }

    /// Calculates simple linear trend (no ML needed!)
    func calculateTrend(entries: [SymptomEntry]) -> TrendAnalysis {
        guard entries.count >= 3 else {
            return TrendAnalysis(
                slope: 0,
                intercept: 0,
                rSquared: 0,
                trending: .stable,
                daysToImprovement: nil
            )
        }

        // Prepare data for linear regression
        let sortedEntries = entries.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
        var xValues: [Double] = []  // Days from start
        var yValues: [Double] = []  // Symptom scores

        let startDate = sortedEntries[0].timestamp ?? Date()

        for entry in sortedEntries {
            let daysSinceStart = Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: entry.timestamp ?? Date()
            ).day ?? 0

            xValues.append(Double(daysSinceStart))

            // Calculate composite score
            let score = calculateCompositeScore(entry)
            yValues.append(score)
        }

        // Simple linear regression (y = mx + b)
        let (slope, intercept, rSquared) = linearRegression(x: xValues, y: yValues)

        // Determine trend
        let trending: TrendAnalysis.Trending
        if abs(slope) < 0.01 {
            trending = .stable
        } else if slope > 0 {
            trending = .improving
        } else {
            trending = .worsening
        }

        // Estimate days to reach "good" level (score of 4.0)
        var daysToImprovement: Int? = nil
        if slope > 0 && yValues.last ?? 0 < 4.0 {
            let currentScore = yValues.last ?? 0
            let daysNeeded = (4.0 - currentScore) / slope
            daysToImprovement = Int(daysNeeded)
        }

        return TrendAnalysis(
            slope: slope,
            intercept: intercept,
            rSquared: rSquared,
            trending: trending,
            daysToImprovement: daysToImprovement
        )
    }

    // MARK: - Comprehensive Analysis

    /// Analyzes all factors at once and returns a comprehensive overview
    func analyzeAllFactors(entries: [SymptomEntry]) -> ComprehensiveAnalysis? {
        guard entries.count >= 7 else { return nil }

        var allFactors: [FactorImpact] = []

        // Analyze all medications
        let uniqueMedications = Set(entries.flatMap { $0.medications ?? [] }.compactMap { $0.name })
        for medication in uniqueMedications {
            let effectiveness = analyzeMedicationEffectiveness(
                medication: medication,
                entries: entries
            )

            if effectiveness.daysAnalyzed >= 7 {
                let impact = FactorImpact(
                    name: medication,
                    category: .medication,
                    impactScore: effectiveness.percentChange / 100.0,
                    confidence: effectiveness.confidence,
                    trend: getTrendDirection(from: effectiveness.percentChange),
                    icon: FactorCategory.medication.icon,
                    detail: "Taken for \(effectiveness.daysAnalyzed) days"
                )
                allFactors.append(impact)
            }
        }

        // Analyze all substances
        let uniqueSubstances = Set(entries.flatMap { $0.substances ?? [] }.compactMap { $0.name })
        for substance in uniqueSubstances {
            let impact = analyzeSubstanceImpact(
                substance: substance,
                entries: entries
            )

            let factorImpact = FactorImpact(
                name: substance,
                category: .substance,
                impactScore: impact.impactScore,
                confidence: 0.7, // Calculate based on sample size
                trend: getTrendDirection(from: impact.impactScore * 100),
                icon: FactorCategory.substance.icon,
                detail: impact.dayAfterSubstance.composite < impact.typicalDay.composite ?
                    "Negative next-day effects" : "No significant after-effects"
            )
            allFactors.append(factorImpact)
        }

        // Analyze sleep impact
        if let sleepImpact = analyzeSleepImpact(entries: entries) {
            allFactors.append(sleepImpact)
        }

        // Analyze exercise impact
        if let exerciseImpact = analyzeExerciseImpact(entries: entries) {
            allFactors.append(exerciseImpact)
        }

        // Analyze daylight impact
        if let daylightImpact = analyzeDaylightImpact(entries: entries) {
            allFactors.append(daylightImpact)
        }

        // Sort factors by absolute impact score
        allFactors.sort { abs($0.impactScore) > abs($1.impactScore) }

        // Get top positive and negative factors
        let topPositive = allFactors.filter { $0.impactScore > 0 }.prefix(3)
        let topNegative = allFactors.filter { $0.impactScore < 0 }.prefix(3)

        // Calculate overall health score (0-100)
        let avgMood = entries.compactMap { $0.moodLevel?.rawValue }.reduce(0, +) / max(1, entries.count)
        let avgAnxiety = entries.compactMap { $0.anxietyLevel?.rawValue }.reduce(0, +) / max(1, entries.count)
        let avgAnhedonia = entries.compactMap { $0.anhedoniaLevel?.rawValue }.reduce(0, +) / max(1, entries.count)
        let overallScore = ((Double(avgMood) / 5.0) * 40 +
                           (1.0 - Double(avgAnxiety) / 5.0) * 30 +
                           (1.0 - Double(avgAnhedonia) / 5.0) * 30)

        // Get overall trend
        let overallTrend = calculateTrend(entries: entries)

        // Generate insights
        let insights = generateKeyInsights(
            factors: allFactors,
            entries: entries,
            trend: overallTrend
        )

        // Generate recommendations
        let recommendations = generateRecommendations(
            topPositive: Array(topPositive),
            topNegative: Array(topNegative),
            overallTrend: overallTrend
        )

        return ComprehensiveAnalysis(
            overallHealthScore: overallScore,
            overallTrend: overallTrend,
            topPositiveFactors: Array(topPositive),
            topNegativeFactors: Array(topNegative),
            allFactors: allFactors,
            keyInsights: insights,
            recommendations: recommendations,
            lastUpdated: Date()
        )
    }

    private func analyzeSleepImpact(entries: [SymptomEntry]) -> FactorImpact? {
        let goodSleepEntries = entries.filter { ($0.sleepHours ?? 0) > 7 }
        let poorSleepEntries = entries.filter { ($0.sleepHours ?? 0) < 6 }

        guard !goodSleepEntries.isEmpty && !poorSleepEntries.isEmpty else { return nil }

        let goodSleepScore = goodSleepEntries.map { calculateCompositeScore($0) }.reduce(0, +) / Double(goodSleepEntries.count)
        let poorSleepScore = poorSleepEntries.map { calculateCompositeScore($0) }.reduce(0, +) / Double(poorSleepEntries.count)

        let impact = (goodSleepScore - poorSleepScore) / max(abs(poorSleepScore), 1)

        return FactorImpact(
            name: "Sleep Quality",
            category: .sleep,
            impactScore: impact,
            confidence: min(1.0, Double(goodSleepEntries.count + poorSleepEntries.count) / 20.0),
            trend: getTrendDirection(from: impact * 100),
            icon: FactorCategory.sleep.icon,
            detail: "Good sleep (\(String(format: "%.1f", goodSleepScore)) avg) vs Poor sleep (\(String(format: "%.1f", poorSleepScore)) avg)"
        )
    }

    private func analyzeExerciseImpact(entries: [SymptomEntry]) -> FactorImpact? {
        let exerciseEntries = entries.filter { ($0.exerciseMinutes ?? 0) > 20 }
        let noExerciseEntries = entries.filter { ($0.exerciseMinutes ?? 0) < 5 }

        guard !exerciseEntries.isEmpty && !noExerciseEntries.isEmpty else { return nil }

        let exerciseScore = exerciseEntries.map { calculateCompositeScore($0) }.reduce(0, +) / Double(exerciseEntries.count)
        let noExerciseScore = noExerciseEntries.map { calculateCompositeScore($0) }.reduce(0, +) / Double(noExerciseEntries.count)

        let impact = (exerciseScore - noExerciseScore) / max(abs(noExerciseScore), 1)

        return FactorImpact(
            name: "Exercise",
            category: .exercise,
            impactScore: impact,
            confidence: min(1.0, Double(exerciseEntries.count + noExerciseEntries.count) / 20.0),
            trend: getTrendDirection(from: impact * 100),
            icon: FactorCategory.exercise.icon,
            detail: "\(Int(exerciseEntries.map { $0.exerciseMinutes ?? 0 }.reduce(0, +) / Double(exerciseEntries.count))) min avg on active days"
        )
    }

    private func analyzeDaylightImpact(entries: [SymptomEntry]) -> FactorImpact? {
        let highDaylightEntries = entries.filter { ($0.timeInDaylightMinutes ?? 0) > 30 }
        let lowDaylightEntries = entries.filter { ($0.timeInDaylightMinutes ?? 0) < 10 }

        guard !highDaylightEntries.isEmpty && !lowDaylightEntries.isEmpty else { return nil }

        let highDaylightScore = highDaylightEntries.map { calculateCompositeScore($0) }.reduce(0, +) / Double(highDaylightEntries.count)
        let lowDaylightScore = lowDaylightEntries.map { calculateCompositeScore($0) }.reduce(0, +) / Double(lowDaylightEntries.count)

        let impact = (highDaylightScore - lowDaylightScore) / max(abs(lowDaylightScore), 1)

        return FactorImpact(
            name: "Daylight Exposure",
            category: .daylight,
            impactScore: impact,
            confidence: min(1.0, Double(highDaylightEntries.count + lowDaylightEntries.count) / 20.0),
            trend: getTrendDirection(from: impact * 100),
            icon: FactorCategory.daylight.icon,
            detail: "\(Int(highDaylightEntries.map { $0.timeInDaylightMinutes ?? 0 }.reduce(0, +) / Double(highDaylightEntries.count))) min avg on sunny days"
        )
    }

    private func getTrendDirection(from percentChange: Double) -> TrendDirection {
        if percentChange > 50 { return .strongImprovement }
        if percentChange > 20 { return .improving }
        if percentChange < -50 { return .strongDecline }
        if percentChange < -20 { return .worsening }
        return .stable
    }

    private func generateKeyInsights(factors: [FactorImpact], entries: [SymptomEntry], trend: TrendAnalysis) -> [String] {
        var insights: [String] = []

        // Trend insight
        if trend.trending == .improving {
            insights.append("Your symptoms are showing consistent improvement over time")
        } else if trend.trending == .worsening {
            insights.append("Your symptoms have been worsening - consider reviewing your treatment plan")
        }

        // Top factor insights
        if let topPositive = factors.filter({ $0.impactScore > 0 }).first {
            insights.append("\(topPositive.name) shows the strongest positive impact on your symptoms")
        }

        if let topNegative = factors.filter({ $0.impactScore < 0 }).first {
            insights.append("\(topNegative.name) appears to worsen your symptoms significantly")
        }

        // Sleep insight
        if let sleepFactor = factors.first(where: { $0.category == .sleep }) {
            if abs(sleepFactor.impactScore) > 0.3 {
                insights.append("Sleep quality is a major factor in your symptom management")
            }
        }

        // Medication consistency insight
        let medicationFactors = factors.filter { $0.category == .medication }
        if !medicationFactors.isEmpty {
            let avgConfidence = medicationFactors.map { $0.confidence }.reduce(0, +) / Double(medicationFactors.count)
            if avgConfidence > 0.7 {
                insights.append("Your medication regimen shows consistent patterns of effectiveness")
            }
        }

        return insights
    }

    private func generateRecommendations(
        topPositive: [FactorImpact],
        topNegative: [FactorImpact],
        overallTrend: TrendAnalysis
    ) -> [String] {
        var recommendations: [String] = []

        // Positive factor recommendations
        for factor in topPositive.prefix(2) {
            switch factor.category {
            case .medication:
                recommendations.append("Continue taking \(factor.name) as prescribed - it's showing positive effects")
            case .exercise:
                recommendations.append("Maintain your exercise routine - it's benefiting your mental health")
            case .sleep:
                recommendations.append("Keep prioritizing good sleep habits")
            case .daylight:
                recommendations.append("Continue getting regular daylight exposure")
            case .substance:
                recommendations.append("Your use of \(factor.name) appears beneficial - maintain current pattern")
            }
        }

        // Negative factor recommendations
        for factor in topNegative.prefix(2) {
            switch factor.category {
            case .medication:
                recommendations.append("Discuss \(factor.name) with your provider - it may need adjustment")
            case .substance:
                recommendations.append("Consider reducing or eliminating \(factor.name)")
            case .sleep:
                recommendations.append("Focus on improving sleep quality - it's affecting your symptoms")
            case .exercise:
                recommendations.append("Try to maintain a more consistent exercise routine")
            case .daylight:
                recommendations.append("Try to get more natural light exposure during the day")
            }
        }

        // Trend-based recommendation
        if overallTrend.trending == .stable {
            recommendations.append("Your symptoms are stable - maintain current routines while monitoring for changes")
        }

        return recommendations
    }

    // MARK: - Statistical Helper Functions

    /// Simple linear regression without any ML library
    private func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double, rSquared: Double) {
        let n = Double(x.count)
        guard n > 1 else { return (0, 0, 0) }

        // Calculate means
        let xMean = x.reduce(0, +) / n
        let yMean = y.reduce(0, +) / n

        // Calculate slope (m)
        var numerator = 0.0
        var denominator = 0.0

        for i in 0..<x.count {
            numerator += (x[i] - xMean) * (y[i] - yMean)
            denominator += pow(x[i] - xMean, 2)
        }

        let slope = denominator != 0 ? numerator / denominator : 0

        // Calculate intercept (b)
        let intercept = yMean - slope * xMean

        // Calculate R-squared
        var ssRes = 0.0  // Residual sum of squares
        var ssTot = 0.0  // Total sum of squares

        for i in 0..<x.count {
            let predicted = slope * x[i] + intercept
            ssRes += pow(y[i] - predicted, 2)
            ssTot += pow(y[i] - yMean, 2)
        }

        let rSquared = ssTot != 0 ? 1 - (ssRes / ssTot) : 0

        return (slope, intercept, max(0, min(1, rSquared)))
    }

    /// Calculates Pearson correlation coefficient
    private func calculateCorrelation(medicationEntries: [SymptomEntry], medication: String) -> Double {
        guard medicationEntries.count > 1 else { return 0 }

        var adherence: [Double] = []
        var symptoms: [Double] = []

        for entry in medicationEntries {
            // Adherence: 1 if taken, 0 if not
            let taken = (entry.medications?.contains { $0.name == medication } ?? false) ? 1.0 : 0.0
            adherence.append(taken)

            // Symptom composite score
            symptoms.append(calculateCompositeScore(entry))
        }

        return pearsonCorrelation(adherence, symptoms)
    }

    /// Pearson correlation calculation
    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let n = Double(x.count)
        guard n > 1 else { return 0 }

        let xMean = x.reduce(0, +) / n
        let yMean = y.reduce(0, +) / n

        var numerator = 0.0
        var xDenominator = 0.0
        var yDenominator = 0.0

        for i in 0..<x.count {
            let xDiff = x[i] - xMean
            let yDiff = y[i] - yMean

            numerator += xDiff * yDiff
            xDenominator += xDiff * xDiff
            yDenominator += yDiff * yDiff
        }

        let denominator = sqrt(xDenominator * yDenominator)
        return denominator != 0 ? numerator / denominator : 0
    }

    /// Calculate standard deviation
    private func calculateStandardDeviation(_ entries: [SymptomEntry]) -> Double {
        let scores = entries.map { calculateCompositeScore($0) }
        let mean = scores.reduce(0, +) / Double(scores.count)

        let squaredDifferences = scores.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(scores.count)

        return sqrt(variance)
    }

    /// Statistical confidence based on sample size and consistency
    private func calculateConfidence(sampleSize: Int, standardDeviation: Double) -> Double {
        // More data = higher confidence
        let sizeConfidence = min(1.0, Double(sampleSize) / 30.0)

        // Less variation = higher confidence
        let consistencyConfidence = max(0, 1.0 - (standardDeviation / 2.0))

        return (sizeConfidence + consistencyConfidence) / 2.0
    }

    // MARK: - Helper Methods

    private func findMedicationStartDate(medication: String, entries: [SymptomEntry]) -> Date {
        let sortedEntries = entries.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }

        for entry in sortedEntries {
            if entry.medications?.contains(where: { $0.name == medication }) ?? false {
                return entry.timestamp ?? Date()
            }
        }

        return Date()
    }

    private func calculateSymptomAverage(_ entries: [SymptomEntry]) -> SymptomAverage {
        guard !entries.isEmpty else {
            return SymptomAverage(mood: 3, anxiety: 3, anhedonia: 3)
        }

        let moods = entries.compactMap { $0.moodLevel?.rawValue }
        let anxieties = entries.compactMap { $0.anxietyLevel?.rawValue }
        let anhedonias = entries.compactMap { $0.anhedoniaLevel?.rawValue }

        return SymptomAverage(
            mood: moods.isEmpty ? 3 : Double(moods.reduce(0, +)) / Double(moods.count),
            anxiety: anxieties.isEmpty ? 3 : Double(anxieties.reduce(0, +)) / Double(anxieties.count),
            anhedonia: anhedonias.isEmpty ? 3 : Double(anhedonias.reduce(0, +)) / Double(anhedonias.count)
        )
    }

    private func calculateCompositeScore(_ entry: SymptomEntry) -> Double {
        let mood = Double(entry.moodLevel?.rawValue ?? 3)
        let anxiety = Double(entry.anxietyLevel?.rawValue ?? 3)
        let anhedonia = Double(entry.anhedoniaLevel?.rawValue ?? 3)

        // Higher score = better overall state
        return mood - (anxiety + anhedonia) / 2.0
    }

    private func calculateDayAfterEffects(
        substanceDays: [SymptomEntry],
        allEntries: [SymptomEntry]
    ) -> SymptomAverage {

        var dayAfterEntries: [SymptomEntry] = []
        let sortedEntries = allEntries.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }

        for (index, entry) in sortedEntries.enumerated() {
            // Check if this was a substance day
            if substanceDays.contains(where: { $0.id == entry.id }) {
                // Get next day's entry if it exists
                if index + 1 < sortedEntries.count {
                    let nextDay = sortedEntries[index + 1]

                    // Verify it's actually the next day (not same day)
                    let calendar = Calendar.current
                    if calendar.isDate(nextDay.timestamp ?? Date(), inSameDayAs: entry.timestamp ?? Date()) == false {
                        dayAfterEntries.append(nextDay)
                    }
                }
            }
        }

        return calculateSymptomAverage(dayAfterEntries)
    }

    private func calculateImpactScore(
        withSubstance: SymptomAverage,
        without: SymptomAverage,
        dayAfter: SymptomAverage
    ) -> Double {

        // Compare composite scores
        let immediateEffect = withSubstance.composite - without.composite
        let nextDayEffect = dayAfter.composite - without.composite

        // Weight immediate and next-day effects
        let totalEffect = (immediateEffect * 0.6) + (nextDayEffect * 0.4)

        // Normalize to -1 to 1 range
        return max(-1, min(1, totalEffect / 3.0))
    }

    // MARK: - Interpretation Methods

    private func generateInterpretation(
        percentChange: Double,
        correlation: Double,
        daysAnalyzed: Int,
        isEffective: Bool
    ) -> Label<Text, Image> {

        if daysAnalyzed < 14 {
            return Label("Too early to determine (need at least 2 weeks of data)", systemImage: "calendar.badge.clock")
        }

        if isEffective {
            if percentChange > 50 {
                return Label("Highly effective - significant improvement (\(Int(percentChange))% better)", systemImage: "arrow.up")
            } else {
                return Label("Moderately effective - noticeable improvement (\(Int(percentChange))% better)", systemImage: "arrow.up.right")
            }
        } else {
            if percentChange < -20 {
                return Label("May be worsening symptoms (\(Int(abs(percentChange)))% worse)", systemImage: "exclamationmark.triangle.fill")
            } else if percentChange < 10 {
                return Label("No significant effect detected", systemImage: "plus.minus.capsule")
            } else {
                return Label("Minimal improvement - consider discussing with provider", systemImage: "light.min")
            }
        }
    }

    private func interpretSubstanceImpact(
        substance: String,
        impactScore: Double,
        dayAfter: SymptomAverage
    ) -> Label<Text, Image> {
        if impactScore > 0.3 {
            return Label("\(substance) appears to improve symptoms", systemImage: "plus.square.fill")
        } else if impactScore < -0.3 {
            if dayAfter.composite < -0.5 {
                return Label("\(substance) worsens symptoms, especially next day", systemImage: "exclamationmark.triangle.fill")
            } else {
                return Label("\(substance) appears to worsen symptoms", systemImage: "exclamationmark.triangle.fill")
            }
        } else {
            return Label("􀅽 \(substance) has minimal impact on symptoms", systemImage: "plus.minus.capsule")
        }
    }
}

// MARK: - SwiftUI Views

struct StatisticalAnalysisView: View {
    @State private var analyzer = SimpleStatisticalAnalyzer()
    @Query(sort: \SymptomEntry.timestamp) private var entries: [SymptomEntry]
    @Query(filter: #Predicate<UserSubstance> { substance in
        substance.isActive == true
    }, sort: \UserSubstance.name) private var userSubstances: [UserSubstance]

    @State private var selectedMedication: String?
    @State private var selectedSubstance: String?
    @State private var medicationResults: SimpleStatisticalAnalyzer.MedicationEffectiveness?
    @State private var substanceResults: SimpleStatisticalAnalyzer.SubstanceImpact?
    @State private var trendAnalysis: SimpleStatisticalAnalyzer.TrendAnalysis?

    var uniqueMedications: [String] {
        Set(entries.flatMap { $0.medications ?? [] }.compactMap { $0.name }).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Overall Trend Card
                    TrendCard(trend: trendAnalysis)
                        .onAppear {
                            trendAnalysis = analyzer.calculateTrend(entries: entries)
                        }

                    // Medication Analysis
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Medication Effectiveness")
                            .font(.headline)

                        if uniqueMedications.isEmpty {
                            Text("No medications tracked yet")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Select Medication", selection: $selectedMedication) {
                                Text("Choose...").tag(nil as String?)
                                ForEach(uniqueMedications, id: \.self) { med in
                                    Text(med).tag(med as String?)
                                }
                            }
                            .pickerStyle(.menu)

                            if let medication = selectedMedication {
                                Button("Analyze \(medication)") {
                                    medicationResults = analyzer.analyzeMedicationEffectiveness(
                                        medication: medication,
                                        entries: entries
                                    )
                                }
                                .buttonStyle(.bordered)
                            }

                            if let results = medicationResults {
                                MedicationResultCard(results: results)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)

                    // Substance Impact Analysis
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Substance Impact")
                            .font(.headline)

                        if userSubstances.isEmpty {
                            Text("No substances tracked yet")
                                .foregroundColor(.secondary)

                            NavigationLink {
                                SubstanceManagementView()
                            } label: {
                                Label("Add Substances", systemImage: "plus.circle")
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Picker("Select Substance", selection: $selectedSubstance) {
                                Text("Choose...").tag(nil as String?)
                                ForEach(userSubstances) { substance in
                                    Text(substance.name ?? "").tag(substance.name)
                                }
                            }
                            .pickerStyle(.menu)

                            if let substance = selectedSubstance {
                                Button("Analyze \(substance)") {
                                    substanceResults = analyzer.analyzeSubstanceImpact(
                                        substance: substance,
                                        entries: entries
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        if let results = substanceResults {
                            SubstanceResultCard(results: results)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Statistical Analysis")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TrendCard: View {
    let trend: SimpleStatisticalAnalyzer.TrendAnalysis?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Overall Trend", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)

            if let trend = trend {
                HStack {
                    VStack(alignment: .leading) {
                        trendText
                            .font(.title2)
                            .foregroundColor(trendColor)

                        if let days = trend.daysToImprovement {
                            Text("Estimated \(days) days to reach good level")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(trend.rSquared * 100))%")
                            .font(.title3.bold())
                    }
                }

                // Mini chart visualization
                SimpleLineChart(slope: trend.slope, intercept: trend.intercept)
                    .frame(height: 60)
            } else {
                Text("Calculating...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }

    var trendText: some View {
        switch trend?.trending {
        case .improving: return Label("Improving", systemImage: "arrow.up.right")
        case .worsening: return Label("Worsening", systemImage: "arrow.down.right")
        case .stable: return Label("Stable", systemImage: "arrow.right")
        case nil: return Label("No data", systemImage: "minus")
        }
    }

    var trendColor: Color {
        switch trend?.trending {
        case .improving: return .green
        case .worsening: return .red
        case .stable: return .blue
        case nil: return .gray
        }
    }
}

struct SimpleLineChart: View {
    let slope: Double
    let intercept: Double

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                // Draw trend line
                let startY = height - (intercept * 10)  // Scale for visualization
                let endY = height - ((slope * 30 + intercept) * 10)  // 30 days projection

                path.move(to: CGPoint(x: 0, y: startY))
                path.addLine(to: CGPoint(x: width, y: endY))
            }
            .stroke(slope > 0 ? Color.green : (slope < 0 ? Color.red : Color.blue), lineWidth: 2)
        }
    }
}

struct MedicationResultCard: View {
    let results: SimpleStatisticalAnalyzer.MedicationEffectiveness

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            results.interpretation
                .font(.subheadline)
                .padding(.vertical, 5)

            HStack {
                VStack(alignment: .leading) {
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", results.beforeAverage))
                        .font(.title3.bold())
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading) {
                    Text("After")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", results.afterAverage))
                        .font(.title3.bold())
                        .foregroundColor(results.percentChange > 0 ? .green : .red)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%+.0f%%", results.percentChange))
                        .font(.title3.bold())
                        .foregroundColor(results.percentChange > 0 ? .green : .red)
                }
            }

            HStack {
                Label("\(results.daysAnalyzed) days analyzed", systemImage: "calendar")
                Spacer()
                Label("\(Int(results.confidence * 100))% confidence", systemImage: "checkmark.shield")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(results.isEffective ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SubstanceResultCard: View {
    let results: SimpleStatisticalAnalyzer.SubstanceImpact

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            results.interpretation
                .font(.subheadline)
                .padding(.vertical, 5)

            // Comparison bars
            VStack(alignment: .leading, spacing: 5) {
                SymptomBar(label: "Typical day", value: results.typicalDay.composite, maxValue: 5)
                SymptomBar(label: "With \(results.substanceName)", value: results.dayWithSubstance.composite, maxValue: 5)
                SymptomBar(label: "Day after", value: results.dayAfterSubstance.composite, maxValue: 5)
            }

            // Impact score visualization
            HStack {
                Text("Impact Score")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.2f", results.impactScore))
                    .font(.title3.bold())
                    .foregroundColor(impactColor)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }

    var impactColor: Color {
        if results.impactScore > 0.3 { return .green }
        if results.impactScore < -0.3 { return .red }
        return .blue
    }
}

struct SymptomBar: View {
    let label: String
    let value: Double
    let maxValue: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 100, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(barColor)
                        .frame(width: geometry.size.width * CGFloat(value / maxValue))
                }
            }
            .frame(height: 20)

            Text(String(format: "%.1f", value))
                .font(.caption.bold())
                .frame(width: 30, alignment: .trailing)
        }
    }

    var barColor: Color {
        if value > 3.5 { return .green }
        if value < 2.5 { return .red }
        return .blue
    }
}

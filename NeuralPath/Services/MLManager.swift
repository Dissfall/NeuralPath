import Foundation
import CoreML
import SwiftData

@Observable
class MLManager {
    static let shared = MLManager()

    private var moodModel: MoodPredictor?
    private var anxietyModel: AnxietyPredictor?
    private var anhedoniaModel: AnhedoniaPredictor?

    private(set) var isModelLoaded = false

    private init() {
        loadModels()
    }

    private func loadModels() {
        do {
            moodModel = try MoodPredictor(configuration: MLModelConfiguration())
            anxietyModel = try AnxietyPredictor(configuration: MLModelConfiguration())
            anhedoniaModel = try AnhedoniaPredictor(configuration: MLModelConfiguration())
            isModelLoaded = true
            print("✅ ML models loaded successfully")
        } catch {
            print("❌ Failed to load ML models: \(error)")
            isModelLoaded = false
        }
    }

    func predictMood(
        sleepHours: Double,
        sleepQuality: Int,
        daylightMinutes: Double,
        exerciseMinutes: Double,
        medicationTaken: Bool,
        substanceAmount: Double,
        dayOfWeek: Int,
        previousDaySleep: Double,
        previousDayMood: Int
    ) -> Double? {
        guard let model = moodModel else { return nil }

        do {
            let input = MoodPredictorInput(
                sleepHours: sleepHours,
                sleepQuality: Int64(sleepQuality),
                daylightMinutes: daylightMinutes,
                exerciseMinutes: exerciseMinutes,
                medicationTaken: medicationTaken ? 1 : 0,
                substanceAmount: substanceAmount,
                dayOfWeek: Int64(dayOfWeek),
                previousDaySleep: previousDaySleep,
                previousDayMood: Int64(previousDayMood)
            )

            let prediction = try model.prediction(input: input)
            return prediction.moodLevel
        } catch {
            print("❌ Mood prediction failed: \(error)")
            return nil
        }
    }

    func predictAnxiety(
        sleepHours: Double,
        sleepQuality: Int,
        daylightMinutes: Double,
        exerciseMinutes: Double,
        medicationTaken: Bool,
        substanceAmount: Double,
        dayOfWeek: Int,
        previousDaySleep: Double,
        previousDayMood: Int
    ) -> Double? {
        guard let model = anxietyModel else { return nil }

        do {
            let input = AnxietyPredictorInput(
                sleepHours: sleepHours,
                sleepQuality: Int64(sleepQuality),
                daylightMinutes: daylightMinutes,
                exerciseMinutes: exerciseMinutes,
                medicationTaken: medicationTaken ? 1 : 0,
                substanceAmount: substanceAmount,
                dayOfWeek: Int64(dayOfWeek),
                previousDaySleep: previousDaySleep,
                previousDayMood: Int64(previousDayMood)
            )

            let prediction = try model.prediction(input: input)
            return prediction.anxietyLevel
        } catch {
            print("❌ Anxiety prediction failed: \(error)")
            return nil
        }
    }

    func predictAnhedonia(
        sleepHours: Double,
        sleepQuality: Int,
        daylightMinutes: Double,
        exerciseMinutes: Double,
        medicationTaken: Bool,
        substanceAmount: Double,
        dayOfWeek: Int,
        previousDaySleep: Double,
        previousDayMood: Int
    ) -> Double? {
        guard let model = anhedoniaModel else { return nil }

        do {
            let input = AnhedoniaPredictorInput(
                sleepHours: sleepHours,
                sleepQuality: Int64(sleepQuality),
                daylightMinutes: daylightMinutes,
                exerciseMinutes: exerciseMinutes,
                medicationTaken: medicationTaken ? 1 : 0,
                substanceAmount: substanceAmount,
                dayOfWeek: Int64(dayOfWeek),
                previousDaySleep: previousDaySleep,
                previousDayMood: Int64(previousDayMood)
            )

            let prediction = try model.prediction(input: input)
            return prediction.anhedoniaLevel
        } catch {
            print("❌ Anhedonia prediction failed: \(error)")
            return nil
        }
    }

    func analyzeMedicationEffectiveness(entries: [SymptomEntry]) -> MedicationEffectiveness? {
        guard entries.count >= 30 else { return nil }

        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

        var daysWithMedication: [SymptomEntry] = []
        var daysWithoutMedication: [SymptomEntry] = []

        for entry in sortedEntries {
            let hasMedication = entry.medications?.contains { $0.taken } ?? false
            if hasMedication {
                daysWithMedication.append(entry)
            } else {
                daysWithoutMedication.append(entry)
            }
        }

        guard daysWithMedication.count >= 10 && daysWithoutMedication.count >= 10 else {
            return nil
        }

        let avgMoodWith = daysWithMedication.compactMap { $0.moodLevel?.rawValue }.reduce(0, +) / daysWithMedication.count
        let avgMoodWithout = daysWithoutMedication.compactMap { $0.moodLevel?.rawValue }.reduce(0, +) / daysWithoutMedication.count

        let avgAnxietyWith = daysWithMedication.compactMap { $0.anxietyLevel?.rawValue }.reduce(0, +) / daysWithMedication.count
        let avgAnxietyWithout = daysWithoutMedication.compactMap { $0.anxietyLevel?.rawValue }.reduce(0, +) / daysWithoutMedication.count

        let avgAnhedoniaWith = daysWithMedication.compactMap { $0.anhedoniaLevel?.rawValue }.reduce(0, +) / daysWithMedication.count
        let avgAnhedoniaWithout = daysWithoutMedication.compactMap { $0.anhedoniaLevel?.rawValue }.reduce(0, +) / daysWithoutMedication.count

        return MedicationEffectiveness(
            daysWithMedication: daysWithMedication.count,
            daysWithoutMedication: daysWithoutMedication.count,
            avgMoodWith: Double(avgMoodWith),
            avgMoodWithout: Double(avgMoodWithout),
            avgAnxietyWith: Double(avgAnxietyWith),
            avgAnxietyWithout: Double(avgAnxietyWithout),
            avgAnhedoniaWith: Double(avgAnhedoniaWith),
            avgAnhedoniaWithout: Double(avgAnhedoniaWithout)
        )
    }

    func generateInsights(entries: [SymptomEntry]) -> [Insight] {
        guard entries.count >= 7 else { return [] }

        var insights: [Insight] = []

        // Medication effectiveness
        if let medEffect = analyzeMedicationEffectiveness(entries: entries) {
            let moodImprovement = medEffect.avgMoodWith - medEffect.avgMoodWithout
            if moodImprovement > 0.5 {
                insights.append(Insight(
                    type: .medicationEffective,
                    title: "Medication is Working",
                    description: "Your mood is \(String(format: "%.1f", moodImprovement)) points higher on days you take medication",
                    impact: .positive,
                    confidence: medEffect.confidence
                ))
            }

            let anxietyReduction = medEffect.avgAnxietyWithout - medEffect.avgAnxietyWith
            if anxietyReduction > 0.5 {
                insights.append(Insight(
                    type: .medicationEffective,
                    title: "Reduced Anxiety",
                    description: "Medication reduces anxiety by \(String(format: "%.1f", anxietyReduction)) points on average",
                    impact: .positive,
                    confidence: medEffect.confidence
                ))
            }
        }

        // Sleep-mood correlation
        let sleepMoodCorrelation = calculateSleepMoodCorrelation(entries: entries)
        if abs(sleepMoodCorrelation) > 0.5 {
            insights.append(Insight(
                type: .sleepPattern,
                title: sleepMoodCorrelation > 0 ? "Better Sleep = Better Mood" : "Sleep Affects Mood",
                description: "Sleep quality shows \(interpretCorrelation(sleepMoodCorrelation)) with your mood",
                impact: sleepMoodCorrelation > 0 ? .positive : .negative,
                confidence: min(1.0, abs(sleepMoodCorrelation))
            ))
        }

        // Exercise benefits
        let exerciseBenefit = calculateExerciseBenefit(entries: entries)
        if exerciseBenefit > 0.3 {
            insights.append(Insight(
                type: .exercisePattern,
                title: "Exercise Improves Mood",
                description: "Days with exercise show \(String(format: "%.1f", exerciseBenefit)) better mood on average",
                impact: .positive,
                confidence: 0.8
            ))
        }

        return insights
    }

    private func calculateSleepMoodCorrelation(entries: [SymptomEntry]) -> Double {
        let pairs = entries.compactMap { entry -> (Double, Double)? in
            guard let sleep = entry.sleepHours,
                  let mood = entry.moodLevel?.rawValue else { return nil }
            return (sleep, Double(mood))
        }

        guard pairs.count >= 5 else { return 0 }

        let n = Double(pairs.count)
        let sumX = pairs.reduce(0.0) { $0 + $1.0 }
        let sumY = pairs.reduce(0.0) { $0 + $1.1 }
        let sumXY = pairs.reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2 = pairs.reduce(0.0) { $0 + $1.0 * $1.0 }
        let sumY2 = pairs.reduce(0.0) { $0 + $1.1 * $1.1 }

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }

    private func calculateExerciseBenefit(entries: [SymptomEntry]) -> Double {
        let withExercise = entries.filter { ($0.exerciseMinutes ?? 0) > 0 }
        let withoutExercise = entries.filter { ($0.exerciseMinutes ?? 0) == 0 }

        guard withExercise.count >= 3 && withoutExercise.count >= 3 else { return 0 }

        let avgMoodWith = withExercise.compactMap { $0.moodLevel?.rawValue }.reduce(0, +) / withExercise.count
        let avgMoodWithout = withoutExercise.compactMap { $0.moodLevel?.rawValue }.reduce(0, +) / withoutExercise.count

        return Double(avgMoodWith - avgMoodWithout)
    }

    private func interpretCorrelation(_ r: Double) -> String {
        let absR = abs(r)
        let direction = r >= 0 ? "positive correlation" : "negative correlation"

        if absR < 0.3 {
            return "weak \(direction)"
        } else if absR < 0.7 {
            return "moderate \(direction)"
        } else {
            return "strong \(direction)"
        }
    }
}

struct MedicationEffectiveness {
    let daysWithMedication: Int
    let daysWithoutMedication: Int
    let avgMoodWith: Double
    let avgMoodWithout: Double
    let avgAnxietyWith: Double
    let avgAnxietyWithout: Double
    let avgAnhedoniaWith: Double
    let avgAnhedoniaWithout: Double

    var moodImprovement: Double {
        avgMoodWith - avgMoodWithout
    }

    var anxietyReduction: Double {
        avgAnxietyWithout - avgAnxietyWith
    }

    var anhedoniaReduction: Double {
        avgAnhedoniaWithout - avgAnhedoniaWith
    }

    var confidence: Double {
        let totalDays = Double(daysWithMedication + daysWithoutMedication)
        return min(1.0, totalDays / 60.0)
    }
}

struct Insight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let impact: Impact
    let confidence: Double

    enum InsightType {
        case medicationEffective
        case sleepPattern
        case exercisePattern
        case substanceEffect
        case seasonalPattern
    }

    enum Impact {
        case positive
        case negative
        case neutral

        var color: String {
            switch self {
            case .positive: return "green"
            case .negative: return "red"
            case .neutral: return "blue"
            }
        }

        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .negative: return "exclamationmark.triangle.fill"
            case .neutral: return "info.circle.fill"
            }
        }
    }
}

//
//  MLFeatureVector.swift
//  NeuralPath
//
//  Feature schema for ML-based analysis (~70 features)
//

import Foundation

// MARK: - Main Feature Vector

struct MLFeatureVector {
    var emotions: EmotionFeatures
    var medications: MedicationFeatures
    var temporal: TemporalFeatures
    var mindfulness: MindfulnessFeatures
    var selfCare: SelfCareFeatures
    var lifestyle: LifestyleFeatures
    var interactions: InteractionFeatures

    // Metadata
    var entryId: UUID
    var timestamp: Date
    var featureVersion: Int = 1

    // Target variables (for training)
    var targetMood: Double?
    var targetAnxiety: Double?
    var targetAnhedonia: Double?
    var targetComposite: Double?
}

// MARK: - Emotion Features (11 features)

struct EmotionFeatures {
    // Valence aggregation
    var positiveCount: Double = 0      // 0-10 normalized to 0-1
    var negativeCount: Double = 0      // 0-10 normalized to 0-1
    var neutralCount: Double = 0       // 0-8 normalized to 0-1
    var emotionalIntensity: Double = 0 // total emotions / 28
    var valenceBalance: Double = 0     // (positive - negative) / total, range -1 to 1

    // Clinical marker emotions (one-hot)
    var hasHopeless: Double = 0        // Depression indicator
    var hasAnxious: Double = 0         // Anxiety indicator
    var hasOverwhelmed: Double = 0     // Stress indicator
    var hasNumb: Double = 0            // Dissociation indicator
    var hasCalm: Double = 0            // Positive baseline
    var hasEnergetic: Double = 0       // Activation level

    static let featureCount = 11
}

// MARK: - Medication Features (18 features)

struct MedicationFeatures {
    // Category groups (binary presence)
    var antidepressantActive: Double = 0   // Any of 11 antidepressant categories
    var anxiolyticActive: Double = 0       // benzodiazepine, buspirone, sleepAid
    var moodStabilizerActive: Double = 0   // antipsychotic, moodStabilizer, lithium, anticonvulsant
    var stimulantActive: Double = 0        // stimulant, nonStimulantADHD
    var supplementActive: Double = 0       // supplement category

    // Specific high-signal categories
    var ssriActive: Double = 0
    var snriActive: Double = 0
    var benzodiazepineActive: Double = 0
    var antipsychoticActive: Double = 0

    // Adherence metrics
    var medicationAdherenceRate: Double = 0  // logs_taken / expected_doses (0-1)
    var daysSinceLastDose: Double = 0        // normalized 0-1 (cap at 7 days)
    var totalActiveMedications: Double = 0   // count, normalized (cap at 10)

    // Frequency encoding
    var hasPRNMedication: Double = 0         // 0 or 1 (as-needed meds)
    var averageDailyDoses: Double = 0        // weighted by frequency, normalized

    // Regimen change features
    var daysSinceLastMedChange: Double = 1   // Normalized 0-1, cap at 90 days
    var isInTransitionPeriod: Double = 0     // 1 if within 14 days of change
    var recentChangeType: Double = 0         // 0=none, 0.33=started, 0.66=stopped, 1=dosageChange
    var stabilizationScore: Double = 1       // 0-1, increases with time since change

    static let featureCount = 18
}

// MARK: - Temporal Features (14 features)

struct TemporalFeatures {
    // Day-of-week encoding (cyclical)
    var dayOfWeekSin: Double = 0       // sin(2 * pi * dayOfWeek / 7)
    var dayOfWeekCos: Double = 0       // cos(2 * pi * dayOfWeek / 7)
    var isWeekend: Double = 0          // 0 or 1

    // Time-of-day (for entry timestamp)
    var hourOfDaySin: Double = 0       // sin(2 * pi * hour / 24)
    var hourOfDayCos: Double = 0       // cos(2 * pi * hour / 24)

    // Rolling windows (7-day)
    var mood7DayAvg: Double = 0.5      // average mood over past 7 days, normalized
    var mood7DayTrend: Double = 0      // slope of mood over past 7 days (-1 to 1)
    var anxiety7DayAvg: Double = 0.5   // average anxiety, normalized
    var anxiety7DayTrend: Double = 0   // slope
    var anhedonia7DayAvg: Double = 0.5

    // Time-since-last features
    var daysSinceLastEntry: Double = 0      // 0 if daily, normalized 0-1 (cap at 7)
    var daysSinceLastMindfulness: Double = 1 // normalized 0-1 (cap at 7)
    var daysSinceLastExercise: Double = 1

    // Streak features
    var consecutiveEntryDays: Double = 0    // normalized 0-1 (cap at 30)

    static let featureCount = 14
}

// MARK: - Mindfulness Features (12 features)

struct MindfulnessFeatures {
    // Category presence today (8 binary)
    var meditationToday: Double = 0
    var breathingToday: Double = 0
    var yogaToday: Double = 0
    var journalingToday: Double = 0
    var bodyScanToday: Double = 0
    var relaxationToday: Double = 0
    var walkingToday: Double = 0
    var gratitudeToday: Double = 0

    // Aggregated metrics
    var totalPracticesToday: Double = 0        // 0-8 normalized
    var totalMinutesToday: Double = 0          // normalized (cap at 120)
    var practiceVariety7Day: Double = 0        // unique categories in week / 8
    var averageDailyPractices: Double = 0      // 7-day rolling average

    static let featureCount = 12
}

// MARK: - Self-Care Features (6 features)

struct SelfCareFeatures {
    // Time-of-day completion rates
    var morningCompletionRate: Double = 0      // practices done / total morning practices
    var afternoonCompletionRate: Double = 0
    var eveningCompletionRate: Double = 0

    // Overall metrics
    var totalCompletionRate: Double = 0        // all completed / all active
    var consistencyScore7Day: Double = 0       // days with any completion / 7
    var timeOfDayBalance: Double = 0           // 1 - variance of completion across times

    static let featureCount = 6
}

// MARK: - Lifestyle Features (4 features)

struct LifestyleFeatures {
    var sleepHoursNormalized: Double = 0.5     // (hours - 4) / 8, clamped 0-1
    var sleepQualityNormalized: Double = 0.5   // rating / 5
    var exerciseMinutesNormalized: Double = 0  // min(minutes, 120) / 120
    var daylightMinutesNormalized: Double = 0  // min(minutes, 180) / 180

    static let featureCount = 4
}

// MARK: - Interaction Features (9 features)

struct InteractionFeatures {
    // Sleep interactions
    var sleepMedicationInteraction: Double = 0   // sleepHours * sleepAidActive
    var sleepExerciseInteraction: Double = 0     // sleepHours * exerciseMinutes (normalized)
    var sleepAnxietyInteraction: Double = 0      // sleepQuality * (1 - anxiety/4)

    // Exercise interactions
    var exerciseMoodLag: Double = 0              // yesterday's exercise * today's mood
    var exerciseDaylightInteraction: Double = 0  // exercise * daylight (normalized)

    // Mindfulness interactions
    var mindfulnessAnxietyReduction: Double = 0  // mindfulness practice when anxious
    var mindfulnessConsistencyBonus: Double = 0  // mindfulness streak * mood

    // Medication interactions
    var medicationSleepInteraction: Double = 0   // antidepressant * sleep quality
    var medicationAdherenceMood: Double = 0      // adherence rate * mood trend

    static let featureCount = 9
}

// MARK: - Total Feature Count

extension MLFeatureVector {
    static var totalFeatureCount: Int {
        EmotionFeatures.featureCount +
        MedicationFeatures.featureCount +
        TemporalFeatures.featureCount +
        MindfulnessFeatures.featureCount +
        SelfCareFeatures.featureCount +
        LifestyleFeatures.featureCount +
        InteractionFeatures.featureCount
    }

    func toArray() -> [Double] {
        var features: [Double] = []

        // Emotions
        features.append(contentsOf: [
            emotions.positiveCount, emotions.negativeCount, emotions.neutralCount,
            emotions.emotionalIntensity, emotions.valenceBalance,
            emotions.hasHopeless, emotions.hasAnxious, emotions.hasOverwhelmed,
            emotions.hasNumb, emotions.hasCalm, emotions.hasEnergetic
        ])

        // Medications
        features.append(contentsOf: [
            medications.antidepressantActive, medications.anxiolyticActive,
            medications.moodStabilizerActive, medications.stimulantActive,
            medications.supplementActive, medications.ssriActive, medications.snriActive,
            medications.benzodiazepineActive, medications.antipsychoticActive,
            medications.medicationAdherenceRate, medications.daysSinceLastDose,
            medications.totalActiveMedications, medications.hasPRNMedication,
            medications.averageDailyDoses, medications.daysSinceLastMedChange,
            medications.isInTransitionPeriod, medications.recentChangeType,
            medications.stabilizationScore
        ])

        // Temporal
        features.append(contentsOf: [
            temporal.dayOfWeekSin, temporal.dayOfWeekCos, temporal.isWeekend,
            temporal.hourOfDaySin, temporal.hourOfDayCos,
            temporal.mood7DayAvg, temporal.mood7DayTrend,
            temporal.anxiety7DayAvg, temporal.anxiety7DayTrend, temporal.anhedonia7DayAvg,
            temporal.daysSinceLastEntry, temporal.daysSinceLastMindfulness,
            temporal.daysSinceLastExercise, temporal.consecutiveEntryDays
        ])

        // Mindfulness
        features.append(contentsOf: [
            mindfulness.meditationToday, mindfulness.breathingToday,
            mindfulness.yogaToday, mindfulness.journalingToday,
            mindfulness.bodyScanToday, mindfulness.relaxationToday,
            mindfulness.walkingToday, mindfulness.gratitudeToday,
            mindfulness.totalPracticesToday, mindfulness.totalMinutesToday,
            mindfulness.practiceVariety7Day, mindfulness.averageDailyPractices
        ])

        // Self-Care
        features.append(contentsOf: [
            selfCare.morningCompletionRate, selfCare.afternoonCompletionRate,
            selfCare.eveningCompletionRate, selfCare.totalCompletionRate,
            selfCare.consistencyScore7Day, selfCare.timeOfDayBalance
        ])

        // Lifestyle
        features.append(contentsOf: [
            lifestyle.sleepHoursNormalized, lifestyle.sleepQualityNormalized,
            lifestyle.exerciseMinutesNormalized, lifestyle.daylightMinutesNormalized
        ])

        // Interactions
        features.append(contentsOf: [
            interactions.sleepMedicationInteraction, interactions.sleepExerciseInteraction,
            interactions.sleepAnxietyInteraction, interactions.exerciseMoodLag,
            interactions.exerciseDaylightInteraction, interactions.mindfulnessAnxietyReduction,
            interactions.mindfulnessConsistencyBonus, interactions.medicationSleepInteraction,
            interactions.medicationAdherenceMood
        ])

        return features
    }
}

// MARK: - ML Analysis Results

struct MoodPrediction {
    let level: MoodLevel
    let confidence: Double
    let contributingFactors: [(name: String, impact: Double)]
}

struct ForecastPoint: Identifiable {
    let id = UUID()
    let date: Date
    let predictedScore: Double      // 0-1 normalized score
    let confidenceInterval: Double  // +/- range

    var predictedMood: Double { predictedScore }
    var confidenceLow: Double { max(0, predictedScore - confidenceInterval) }
    var confidenceHigh: Double { min(1, predictedScore + confidenceInterval) }
}

enum PatternType: String, CaseIterable {
    case weekly = "weekly"
    case medicationEffect = "medication_effect"
    case substanceTrigger = "substance_trigger"
    case sleepCorrelation = "sleep_correlation"
    case exerciseBenefit = "exercise_benefit"
    case mindfulnessImpact = "mindfulness_impact"
    case seasonalTrend = "seasonal_trend"
}

struct DetectedPattern: Identifiable {
    let id = UUID()
    let type: PatternType
    let description: String
    let strength: Double       // 0-1
    let confidence: Double     // 0-1
    let actionable: Bool
    let recommendation: String?
}

struct SimilarDay: Identifiable {
    let id = UUID()
    let entryId: UUID
    let date: Date
    let similarity: Double     // 0-1
    let mood: MoodLevel
    let keyFactors: [String]
}

// MARK: - Medication Regimen Events

enum MedChangeType: String {
    case started
    case stopped
    case dosageChange
    case resumed
}

struct MedicationRegimenEvent {
    let date: Date
    let type: MedChangeType
    let medicationName: String
    let medicationCategory: MedicationCategory?
    let previousDosage: String?
    let newDosage: String?
}

// MARK: - Analysis Mode

enum AnalysisMode: String, CaseIterable {
    case statisticalOnly = "statistical_only"
    case basicML = "basic_ml"
    case hybridBalanced = "hybrid_balanced"
    case mlPrimary = "ml_primary"

    var displayName: String {
        switch self {
        case .statisticalOnly: return "Building Baseline"
        case .basicML: return "ML Enhanced"
        case .hybridBalanced: return "AI Analysis"
        case .mlPrimary: return "Personalized AI"
        }
    }

    var icon: String {
        switch self {
        case .statisticalOnly: return "chart.bar"
        case .basicML: return "cpu"
        case .hybridBalanced: return "brain"
        case .mlPrimary: return "brain.head.profile"
        }
    }

    var statisticalWeight: Double {
        switch self {
        case .statisticalOnly: return 1.0
        case .basicML: return 0.8
        case .hybridBalanced: return 0.5
        case .mlPrimary: return 0.3
        }
    }

    var mlWeight: Double {
        switch self {
        case .statisticalOnly: return 0.0
        case .basicML: return 0.2
        case .hybridBalanced: return 0.5
        case .mlPrimary: return 0.7
        }
    }

    static func from(entryCount: Int) -> AnalysisMode {
        switch entryCount {
        case 0..<30: return .statisticalOnly
        case 30..<90: return .basicML
        case 90..<180: return .hybridBalanced
        default: return .mlPrimary
        }
    }
}

// MARK: - Confidence Metrics

struct ConfidenceMetrics {
    let statisticalConfidence: Double
    let mlConfidence: Double
    let dataQuality: Double
    let blendWeights: BlendWeights

    struct BlendWeights {
        let statistical: Double
        let ml: Double
    }

    var overallConfidence: Double {
        blendWeights.statistical * statisticalConfidence +
        blendWeights.ml * mlConfidence
    }
}

//
//  MLDataExtractor.swift
//  NeuralPath
//
//  SwiftData query coordination for ML feature extraction
//

import Foundation
import SwiftData

enum MLError: Error, LocalizedError {
    case insufficientData(have: Int, need: Int)
    case invalidFeatureValue(feature: String, value: Double)
    case modelContextMissing
    case extractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .insufficientData(let have, let need):
            return "Insufficient data: have \(have) entries, need \(need)"
        case .invalidFeatureValue(let feature, let value):
            return "Invalid feature value for \(feature): \(value)"
        case .modelContextMissing:
            return "Model context is not available"
        case .extractionFailed(let reason):
            return "Feature extraction failed: \(reason)"
        }
    }
}

@MainActor
@Observable
class MLDataExtractor {
    private let modelContext: ModelContext

    // Transformers
    private let emotionTransformer = EmotionTransformer()
    private let medicationTransformer = MedicationTransformer()
    private let temporalTransformer = TemporalTransformer()
    private let mindfulnessTransformer = MindfulnessTransformer()
    private let selfCareTransformer = SelfCareTransformer()
    private let lifestyleTransformer = LifestyleTransformer()
    private let interactionTransformer = InteractionTransformer()
    private let missingDataHandler = MissingDataHandler()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Training Data Extraction

    func extractTrainingData(minEntries: Int = 30) async throws -> [MLFeatureVector] {
        // Fetch all valid entries
        let entriesFetch = FetchDescriptor<SymptomEntry>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let allEntries = try modelContext.fetch(entriesFetch)
        let entries = missingDataHandler.filterValidEntries(allEntries)

        guard entries.count >= minEntries else {
            throw MLError.insufficientData(have: entries.count, need: minEntries)
        }

        // Fetch supporting data
        let medications = try modelContext.fetch(FetchDescriptor<UserMedication>())
        let medLogs = try modelContext.fetch(FetchDescriptor<MedicationLog>())
        let mindfulnessLogs = try modelContext.fetch(FetchDescriptor<MindfulnessLog>())
        let mindfulnessPractices = try modelContext.fetch(FetchDescriptor<UserMindfulness>())
        let selfCareLogs = try modelContext.fetch(FetchDescriptor<SelfCareLog>())
        let selfCarePractices = try modelContext.fetch(FetchDescriptor<UserSelfCare>())

        // Detect medication regimen changes
        let oldestDate = entries.first?.timestamp ?? Date()
        let regimenEvents = medicationTransformer.detectRegimenChanges(
            medications: medications,
            since: oldestDate
        )

        // Transform each entry
        var vectors: [MLFeatureVector] = []

        for (index, entry) in entries.enumerated() {
            let historicalEntries = Array(entries.prefix(index))
            let entryDate = entry.timestamp ?? Date()

            let vector = try extractFeatures(
                for: entry,
                historicalEntries: historicalEntries,
                allMedications: medications,
                medicationLogs: medLogs,
                regimenEvents: regimenEvents,
                mindfulnessLogs: mindfulnessLogs,
                mindfulnessPractices: mindfulnessPractices,
                selfCareLogs: selfCareLogs,
                selfCarePractices: selfCarePractices,
                date: entryDate,
                includeTargets: true
            )

            vectors.append(vector)
        }

        return vectors
    }

    // MARK: - Single Entry Feature Extraction

    func extractFeaturesForEntry(_ entry: SymptomEntry) async throws -> MLFeatureVector {
        let entryDate = entry.timestamp ?? Date()

        // Fetch all entries and filter in memory (SwiftData doesn't support force unwrap in predicates)
        let entriesFetch = FetchDescriptor<SymptomEntry>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let allEntries = try modelContext.fetch(entriesFetch)
        let historicalEntries = allEntries.filter { e in
            guard let ts = e.timestamp else { return false }
            return ts < entryDate
        }

        // Fetch supporting data
        let medications = try modelContext.fetch(FetchDescriptor<UserMedication>())
        let medLogs = try modelContext.fetch(FetchDescriptor<MedicationLog>())
        let mindfulnessLogs = try modelContext.fetch(FetchDescriptor<MindfulnessLog>())
        let mindfulnessPractices = try modelContext.fetch(FetchDescriptor<UserMindfulness>())
        let selfCareLogs = try modelContext.fetch(FetchDescriptor<SelfCareLog>())
        let selfCarePractices = try modelContext.fetch(FetchDescriptor<UserSelfCare>())

        // Detect medication regimen changes
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: entryDate)!
        let regimenEvents = medicationTransformer.detectRegimenChanges(
            medications: medications,
            since: threeMonthsAgo
        )

        return try extractFeatures(
            for: entry,
            historicalEntries: historicalEntries,
            allMedications: medications,
            medicationLogs: medLogs,
            regimenEvents: regimenEvents,
            mindfulnessLogs: mindfulnessLogs,
            mindfulnessPractices: mindfulnessPractices,
            selfCareLogs: selfCareLogs,
            selfCarePractices: selfCarePractices,
            date: entryDate,
            includeTargets: false
        )
    }

    // MARK: - Core Feature Extraction

    private func extractFeatures(
        for entry: SymptomEntry,
        historicalEntries: [SymptomEntry],
        allMedications: [UserMedication],
        medicationLogs: [MedicationLog],
        regimenEvents: [MedicationRegimenEvent],
        mindfulnessLogs: [MindfulnessLog],
        mindfulnessPractices: [UserMindfulness],
        selfCareLogs: [SelfCareLog],
        selfCarePractices: [UserSelfCare],
        date: Date,
        includeTargets: Bool
    ) throws -> MLFeatureVector {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        // Filter logs for today
        let todayMedLogs = medicationLogs.filter { log in
            guard let logDate = log.timestamp else { return false }
            return logDate >= dayStart && logDate < dayEnd
        }

        let todayMindfulnessLogs = mindfulnessLogs.filter { log in
            guard let logDate = log.timestamp else { return false }
            return logDate >= dayStart && logDate < dayEnd
        }

        let todaySelfCareLogs = selfCareLogs.filter { log in
            guard let logDate = log.timestamp else { return false }
            return logDate >= dayStart && logDate < dayEnd
        }

        // Get active medications for the date
        let activeMedications = allMedications.filter { med in
            guard med.isActive == true else { return false }
            if let start = med.startDate, start > date { return false }
            if let end = med.endDate, end < date { return false }
            return true
        }

        // Transform features
        let emotionFeatures = emotionTransformer.transform(entry.emotions)

        let medicationFeatures = medicationTransformer.transform(
            activeMedications: activeMedications,
            logs: todayMedLogs,
            forDate: date,
            regimenEvents: regimenEvents.filter { $0.date <= date }
        )

        let temporalFeatures = temporalTransformer.transform(
            entry: entry,
            historicalEntries: historicalEntries,
            mindfulnessLogs: mindfulnessLogs.filter { ($0.timestamp ?? .distantPast) < date }
        )

        let mindfulnessFeatures = mindfulnessTransformer.transform(
            todayLogs: todayMindfulnessLogs,
            practices: mindfulnessPractices,
            historicalLogs: mindfulnessLogs.filter { ($0.timestamp ?? .distantPast) < date },
            forDate: date
        )

        let selfCareFeatures = selfCareTransformer.transform(
            todayLogs: todaySelfCareLogs,
            practices: selfCarePractices,
            historicalLogs: selfCareLogs.filter { ($0.timestamp ?? .distantPast) < date },
            forDate: date
        )

        let lifestyleFeatures = lifestyleTransformer.transform(entry: entry)

        let interactionFeatures = interactionTransformer.transform(
            entry: entry,
            previousEntry: historicalEntries.last,
            medications: medicationFeatures,
            mindfulness: mindfulnessFeatures
        )

        // Build feature vector
        var vector = MLFeatureVector(
            emotions: emotionFeatures,
            medications: medicationFeatures,
            temporal: temporalFeatures,
            mindfulness: mindfulnessFeatures,
            selfCare: selfCareFeatures,
            lifestyle: lifestyleFeatures,
            interactions: interactionFeatures,
            entryId: entry.id ?? UUID(),
            timestamp: date
        )

        // Add target variables if requested
        if includeTargets {
            vector.targetMood = Double(entry.moodLevel?.rawValue ?? 3) / 5.0
            vector.targetAnxiety = Double(entry.anxietyLevel?.rawValue ?? 2) / 4.0
            vector.targetAnhedonia = Double(entry.anhedoniaLevel?.rawValue ?? 2) / 4.0
            vector.targetComposite = calculateCompositeTarget(entry: entry)
        }

        return vector
    }

    private func calculateCompositeTarget(entry: SymptomEntry) -> Double {
        let mood = Double(entry.moodLevel?.rawValue ?? 3) / 5.0
        let anxiety = Double(entry.anxietyLevel?.rawValue ?? 2) / 4.0
        let anhedonia = Double(entry.anhedoniaLevel?.rawValue ?? 2) / 4.0

        // Higher composite = better mental health
        // Mood contributes positively, anxiety and anhedonia contribute negatively
        return mood * 0.4 + (1 - anxiety) * 0.3 + (1 - anhedonia) * 0.3
    }

    // MARK: - Data Quality Assessment

    func assessDataQuality() async throws -> DataQualityAssessment {
        let entriesFetch = FetchDescriptor<SymptomEntry>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let allEntries = try modelContext.fetch(entriesFetch)
        let validEntries = missingDataHandler.filterValidEntries(allEntries)

        let entriesWithEmotions = validEntries.filter { !$0.emotions.isEmpty }
        let entriesWithMedications = validEntries.filter { !($0.medications?.isEmpty ?? true) }

        let mindfulnessLogs = try modelContext.fetch(FetchDescriptor<MindfulnessLog>())
        let selfCareLogs = try modelContext.fetch(FetchDescriptor<SelfCareLog>())

        // Calculate data span
        var dataSpanDays = 0
        var longestGap = 0

        if let first = validEntries.first?.timestamp,
           let last = validEntries.last?.timestamp {
            dataSpanDays = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0
        }

        // Calculate longest gap
        for i in 1..<validEntries.count {
            if let prev = validEntries[i-1].timestamp,
               let curr = validEntries[i].timestamp {
                let gap = Calendar.current.dateComponents([.day], from: prev, to: curr).day ?? 0
                longestGap = max(longestGap, gap)
            }
        }

        // Average entries per week
        let weeksOfData = max(1, dataSpanDays / 7)
        let averageEntriesPerWeek = Double(validEntries.count) / Double(weeksOfData)

        return DataQualityAssessment(
            totalEntries: validEntries.count,
            entriesWithMood: validEntries.count,
            entriesWithEmotions: entriesWithEmotions.count,
            entriesWithMedications: entriesWithMedications.count,
            entriesWithMindfulness: mindfulnessLogs.count > 0 ? validEntries.count : 0,
            entriesWithSelfCare: selfCareLogs.count > 0 ? validEntries.count : 0,
            averageEntriesPerWeek: averageEntriesPerWeek,
            longestGap: longestGap,
            dataSpanDays: dataSpanDays
        )
    }

    // MARK: - Entry Count

    func getValidEntryCount() throws -> Int {
        let entriesFetch = FetchDescriptor<SymptomEntry>()
        let allEntries = try modelContext.fetch(entriesFetch)
        return missingDataHandler.filterValidEntries(allEntries).count
    }

    func getAnalysisMode() throws -> AnalysisMode {
        let count = try getValidEntryCount()
        return AnalysisMode.from(entryCount: count)
    }
}

// MARK: - Data Quality Assessment

struct DataQualityAssessment {
    var totalEntries: Int
    var entriesWithMood: Int
    var entriesWithEmotions: Int
    var entriesWithMedications: Int
    var entriesWithMindfulness: Int
    var entriesWithSelfCare: Int
    var averageEntriesPerWeek: Double
    var longestGap: Int  // days between entries
    var dataSpanDays: Int

    var qualityScore: Double {
        let completenessScore = Double(entriesWithEmotions) / Double(max(1, totalEntries))
        let consistencyScore = min(1.0, averageEntriesPerWeek / 7.0)
        let gapPenalty = longestGap > 7 ? 0.2 : 0.0
        return max(0, (completenessScore * 0.4 + consistencyScore * 0.5 - gapPenalty)) * 100
    }

    var analysisCapabilities: Set<AnalysisCapability> {
        var capabilities: Set<AnalysisCapability> = []

        if totalEntries >= 7 { capabilities.insert(.basicStatistics) }
        if totalEntries >= 14 { capabilities.insert(.basicCorrelation) }
        if totalEntries >= 21 { capabilities.insert(.trendAnalysis) }
        if totalEntries >= 30 { capabilities.insert(.basicML) }
        if totalEntries >= 90 { capabilities.insert(.hybridAnalysis) }
        if totalEntries >= 180 { capabilities.insert(.personalizedML) }

        return capabilities
    }

    var nextMilestone: (capability: AnalysisCapability, entriesNeeded: Int)? {
        let milestones: [(AnalysisCapability, Int)] = [
            (.basicStatistics, 7),
            (.basicCorrelation, 14),
            (.trendAnalysis, 21),
            (.basicML, 30),
            (.hybridAnalysis, 90),
            (.personalizedML, 180)
        ]

        for (capability, needed) in milestones {
            if totalEntries < needed {
                return (capability, needed - totalEntries)
            }
        }
        return nil
    }
}

enum AnalysisCapability: String, CaseIterable {
    case basicStatistics = "basic_statistics"
    case basicCorrelation = "basic_correlation"
    case trendAnalysis = "trend_analysis"
    case basicML = "basic_ml"
    case hybridAnalysis = "hybrid_analysis"
    case personalizedML = "personalized_ml"

    var displayName: String {
        switch self {
        case .basicStatistics: return "Basic Statistics"
        case .basicCorrelation: return "Factor Correlations"
        case .trendAnalysis: return "Trend Analysis"
        case .basicML: return "ML Predictions"
        case .hybridAnalysis: return "AI Analysis"
        case .personalizedML: return "Personalized AI"
        }
    }

    var entriesRequired: Int {
        switch self {
        case .basicStatistics: return 7
        case .basicCorrelation: return 14
        case .trendAnalysis: return 21
        case .basicML: return 30
        case .hybridAnalysis: return 90
        case .personalizedML: return 180
        }
    }
}

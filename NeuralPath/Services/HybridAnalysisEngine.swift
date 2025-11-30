//
//  HybridAnalysisEngine.swift
//  NeuralPath
//
//  Main orchestrator for hybrid statistical + ML analysis
//

import Foundation
import SwiftData

@MainActor
@Observable
class HybridAnalysisEngine {

    // MARK: - Dependencies

    private let statisticalAnalyzer: SimpleStatisticalAnalyzer
    private let mlEngine: MLAnalysisEngine
    private let blender: AnalysisBlender
    private var dataExtractor: MLDataExtractor?
    private let modelManager = MLModelManager.shared

    // MARK: - State

    var isAnalyzing = false
    var lastAnalysis: HybridAnalysis?
    var analysisError: Error?

    // MARK: - Data Thresholds

    struct DataThresholds {
        static let statisticalOnly = 7
        static let basicML = 30
        static let hybridBalanced = 90
        static let mlPrimary = 180
    }

    // MARK: - Initialization

    init() {
        self.statisticalAnalyzer = SimpleStatisticalAnalyzer()
        self.mlEngine = MLAnalysisEngine()
        self.blender = AnalysisBlender()
    }

    func configure(with modelContext: ModelContext) {
        self.dataExtractor = MLDataExtractor(modelContext: modelContext)
    }

    // MARK: - Main Analysis

    func analyze(
        entries: [SymptomEntry],
        timeRange: TimeRange = .month
    ) async throws -> HybridAnalysis {
        isAnalyzing = true
        analysisError = nil

        defer { isAnalyzing = false }

        guard !entries.isEmpty else {
            throw MLError.insufficientData(have: 0, need: DataThresholds.statisticalOnly)
        }

        // Determine analysis mode based on entry count
        let mode = AnalysisMode.from(entryCount: entries.count)

        // Always run statistical analysis
        guard let statisticalResult = statisticalAnalyzer.analyzeAllFactors(
            entries: entries
        ) else {
            throw MLError.insufficientData(have: entries.count, need: DataThresholds.statisticalOnly)
        }

        // Run ML analysis if we have enough data
        var mlResult: MLAnalysisResult?

        if mode != .statisticalOnly && modelManager.isMLEnabled {
            do {
                mlResult = try await runMLAnalysis(entries: entries, mode: mode)
            } catch {
                print("ML analysis failed, falling back to statistical: \(error)")
                // Continue with statistical-only
            }
        }

        // Blend results
        let hybridAnalysis = blender.blend(
            statistical: statisticalResult,
            ml: mlResult,
            mode: mode,
            entryCount: entries.count
        )

        lastAnalysis = hybridAnalysis
        return hybridAnalysis
    }

    private func runMLAnalysis(
        entries: [SymptomEntry],
        mode: AnalysisMode
    ) async throws -> MLAnalysisResult {
        guard let extractor = dataExtractor else {
            throw MLError.modelContextMissing
        }

        // Ensure models are trained
        if modelManager.shouldRetrain() {
            let trainingData = try await extractor.extractTrainingData(
                minEntries: DataThresholds.basicML
            )
            try await modelManager.trainModels(with: trainingData)
            try await mlEngine.trainPatternMatcher(data: trainingData)
        }

        // Extract features for the most recent entry
        guard let latestEntry = entries.last else {
            throw MLError.insufficientData(have: 0, need: 1)
        }

        let features = try await extractor.extractFeaturesForEntry(latestEntry)

        // Run full ML analysis
        return await mlEngine.analyzeAll(features: features, entries: entries)
    }

    // MARK: - Quick Analysis

    func quickAnalyze(entry: SymptomEntry) async throws -> QuickAnalysis {
        guard let extractor = dataExtractor else {
            throw MLError.modelContextMissing
        }

        let features = try await extractor.extractFeaturesForEntry(entry)

        // Get prediction
        let prediction = await mlEngine.predictTomorrowMood(features: features)

        // Get similar days
        let similarDays = await mlEngine.findSimilarDays(features: features, count: 3)

        return QuickAnalysis(
            prediction: prediction,
            similarDays: similarDays,
            dataQuality: try await extractor.assessDataQuality()
        )
    }

    // MARK: - Data Quality

    func getDataQuality() async throws -> DataQualityAssessment {
        guard let extractor = dataExtractor else {
            throw MLError.modelContextMissing
        }
        return try await extractor.assessDataQuality()
    }

    func getCurrentMode() throws -> AnalysisMode {
        guard let extractor = dataExtractor else {
            throw MLError.modelContextMissing
        }
        return try extractor.getAnalysisMode()
    }

    // MARK: - Insights Generation

    func generateInsights(from analysis: HybridAnalysis) -> [HybridInsight] {
        var insights: [HybridInsight] = []

        // Add prediction insight
        if let prediction = analysis.predictions?.prediction {
            insights.append(HybridInsight(
                id: UUID(),
                title: "Tomorrow's Outlook",
                description: "Based on today's factors, your mood tomorrow is predicted to be \(prediction.level.displayName.lowercased())",
                icon: "sun.horizon",
                isMLDerived: true,
                confidence: prediction.confidence,
                category: .prediction
            ))
        }

        // Add pattern insights
        for pattern in analysis.patterns ?? [] {
            insights.append(HybridInsight(
                id: UUID(),
                title: patternTitle(for: pattern.type),
                description: pattern.description,
                icon: patternIcon(for: pattern.type),
                isMLDerived: true,
                confidence: pattern.confidence,
                category: .pattern,
                recommendation: pattern.recommendation
            ))
        }

        // Add statistical insights
        if let trend = analysis.trends {
            let trendInsight = generateTrendInsight(from: trend)
            insights.append(trendInsight)
        }

        // Add factor insights
        let topFactors = analysis.factorImpacts.prefix(3)
        for factor in topFactors {
            insights.append(HybridInsight(
                id: UUID(),
                title: "\(factor.factor) Impact",
                description: factorDescription(factor),
                icon: factorIcon(for: factor.factor),
                isMLDerived: false,
                confidence: factor.confidence,
                category: .factor
            ))
        }

        return insights
    }

    private func patternTitle(for type: PatternType) -> String {
        switch type {
        case .weekly: return "Weekly Pattern"
        case .medicationEffect: return "Medication Effect"
        case .substanceTrigger: return "Substance Trigger"
        case .sleepCorrelation: return "Sleep Impact"
        case .exerciseBenefit: return "Exercise Benefit"
        case .mindfulnessImpact: return "Mindfulness Impact"
        case .seasonalTrend: return "Seasonal Trend"
        }
    }

    private func patternIcon(for type: PatternType) -> String {
        switch type {
        case .weekly: return "calendar"
        case .medicationEffect: return "pills"
        case .substanceTrigger: return "drop.triangle"
        case .sleepCorrelation: return "moon.zzz"
        case .exerciseBenefit: return "figure.run"
        case .mindfulnessImpact: return "brain.head.profile"
        case .seasonalTrend: return "leaf"
        }
    }

    private func generateTrendInsight(from trend: TrendAnalysis) -> HybridInsight {
        let direction: String
        let icon: String

        switch trend.direction {
        case .improving:
            direction = "improving"
            icon = "arrow.up.right"
        case .worsening:
            direction = "declining"
            icon = "arrow.down.right"
        case .stable:
            direction = "stable"
            icon = "arrow.right"
        }

        return HybridInsight(
            id: UUID(),
            title: "Overall Trend",
            description: "Your mental health is \(direction) over the past \(trend.period)",
            icon: icon,
            isMLDerived: false,
            confidence: trend.confidence,
            category: .trend
        )
    }

    private func factorDescription(_ factor: FactorImpact) -> String {
        let impact = factor.impact
        let direction = impact >= 0 ? "positive" : "negative"
        let strength: String

        switch abs(impact) {
        case 0..<0.2: strength = "slight"
        case 0.2..<0.4: strength = "moderate"
        case 0.4..<0.6: strength = "significant"
        default: strength = "strong"
        }

        return "\(factor.factor) has a \(strength) \(direction) impact on your mood"
    }

    private func factorIcon(for factor: String) -> String {
        switch factor.lowercased() {
        case let f where f.contains("sleep"): return "moon.zzz"
        case let f where f.contains("exercise"): return "figure.run"
        case let f where f.contains("medication"): return "pills"
        case let f where f.contains("substance"): return "drop.triangle"
        case let f where f.contains("daylight"): return "sun.max"
        case let f where f.contains("mindfulness"): return "brain.head.profile"
        default: return "chart.bar"
        }
    }
}

// MARK: - Supporting Types

struct HybridAnalysis {
    let healthScore: Double
    let trends: TrendAnalysis?
    let factorImpacts: [FactorImpact]
    let predictions: MLAnalysisResult?
    let patterns: [DetectedPattern]?
    let forecast: [ForecastPoint]?
    let insights: [String]
    let recommendations: [String]
    let mode: AnalysisMode
    let confidence: ConfidenceMetrics
    let dataQuality: DataQualityAssessment?
}

struct QuickAnalysis {
    let prediction: MoodPrediction?
    let similarDays: [SimilarDay]
    let dataQuality: DataQualityAssessment
}

struct HybridInsight: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let isMLDerived: Bool
    let confidence: Double
    let category: InsightCategory
    var recommendation: String?

    enum InsightCategory {
        case prediction
        case pattern
        case trend
        case factor
        case recommendation
    }
}

// MARK: - Trend Analysis Types

struct TrendAnalysis {
    let direction: TrendDirection
    let slope: Double
    let confidence: Double
    let period: String
}

enum TrendDirection {
    case improving
    case worsening
    case stable
}

// MARK: - Factor Impact

struct FactorImpact {
    let factor: String
    let impact: Double      // -1 to 1
    let confidence: Double  // 0 to 1
    let trend: TrendDirection
}


//
//  AnalysisBlender.swift
//  NeuralPath
//
//  Blends statistical and ML analysis results
//

import Foundation

struct AnalysisBlender {

    // MARK: - Main Blending

    func blend(
        statistical: SimpleStatisticalAnalyzer.ComprehensiveAnalysis,
        ml: MLAnalysisResult?,
        mode: AnalysisMode,
        entryCount: Int
    ) -> HybridAnalysis {

        // Calculate blended health score
        let blendedScore = calculateBlendedScore(
            statScore: statistical.overallHealthScore,
            statConfidence: statistical.calculatedConfidence,
            mlScore: ml?.calculateHealthScore(),
            mlConfidence: ml?.confidence ?? 0,
            mode: mode
        )

        // Blend factor impacts
        let blendedFactors = blendFactorImpacts(
            statistical: statistical.allFactors,
            ml: ml?.extractFactorImpacts() ?? [],
            mode: mode
        )

        // Combine insights
        let combinedInsights = combineInsights(
            statistical: statistical.keyInsights,
            ml: ml?.generateInsights() ?? []
        )

        // Combine recommendations
        let combinedRecommendations = combineRecommendations(
            statistical: statistical.recommendations,
            ml: ml?.patterns.compactMap(\.recommendation) ?? []
        )

        // Calculate confidence metrics
        let confidenceMetrics = calculateConfidenceMetrics(
            statistical: statistical,
            ml: ml,
            mode: mode,
            entryCount: entryCount
        )

        // Build trend analysis
        let trendAnalysis = buildTrendAnalysis(from: statistical)

        return HybridAnalysis(
            healthScore: blendedScore,
            trends: trendAnalysis,
            factorImpacts: blendedFactors,
            predictions: ml,
            patterns: ml?.patterns,
            forecast: ml?.forecast,
            insights: combinedInsights,
            recommendations: combinedRecommendations,
            mode: mode,
            confidence: confidenceMetrics,
            dataQuality: nil // Set by caller if needed
        )
    }

    // MARK: - Score Blending

    func calculateBlendedScore(
        statScore: Double,
        statConfidence: Double,
        mlScore: Double?,
        mlConfidence: Double,
        mode: AnalysisMode
    ) -> Double {
        guard let ml = mlScore, mode != .statisticalOnly else {
            return statScore
        }

        // Get base weights from mode
        var statWeight = mode.statisticalWeight
        var mlWeight = mode.mlWeight

        // Adjust by confidence
        let totalConfidence = statConfidence + mlConfidence
        if totalConfidence > 0 {
            let confAdjustment = 0.2 // Max 20% shift based on confidence
            let confDiff = (mlConfidence - statConfidence) / totalConfidence

            statWeight -= confDiff * confAdjustment
            mlWeight += confDiff * confAdjustment

            // Ensure weights stay reasonable
            statWeight = max(0.1, min(0.9, statWeight))
            mlWeight = max(0.1, min(0.9, mlWeight))
        }

        // Normalize weights
        let total = statWeight + mlWeight
        statWeight /= total
        mlWeight /= total

        return (statScore * statWeight) + (ml * mlWeight)
    }

    // MARK: - Factor Impact Blending

    private func blendFactorImpacts(
        statistical: [SimpleStatisticalAnalyzer.FactorImpact],
        ml: [FactorImpact],
        mode: AnalysisMode
    ) -> [FactorImpact] {

        var blendedFactors: [String: FactorImpact] = [:]

        // Add statistical factors
        for statFactor in statistical {
            blendedFactors[statFactor.name] = FactorImpact(
                factor: statFactor.name,
                impact: statFactor.impactScore,
                confidence: statFactor.confidence,
                trend: statFactor.trendDirection
            )
        }

        // Blend with ML factors
        if mode != .statisticalOnly {
            for mlFactor in ml {
                if let existing = blendedFactors[mlFactor.factor] {
                    // Blend impacts
                    let statWeight = mode.statisticalWeight
                    let mlWeight = mode.mlWeight
                    let blendedImpact = (existing.impact * statWeight + mlFactor.impact * mlWeight)
                    let blendedConfidence = (existing.confidence * statWeight + mlFactor.confidence * mlWeight)

                    blendedFactors[mlFactor.factor] = FactorImpact(
                        factor: mlFactor.factor,
                        impact: blendedImpact,
                        confidence: blendedConfidence,
                        trend: mlFactor.trend // Prefer ML trend
                    )
                } else {
                    // Add new ML-only factor with reduced weight
                    blendedFactors[mlFactor.factor] = FactorImpact(
                        factor: mlFactor.factor,
                        impact: mlFactor.impact * mode.mlWeight,
                        confidence: mlFactor.confidence * mode.mlWeight,
                        trend: mlFactor.trend
                    )
                }
            }
        }

        // Sort by absolute impact
        return blendedFactors.values
            .sorted { abs($0.impact) > abs($1.impact) }
    }

    // MARK: - Insights Combination

    private func combineInsights(statistical: [String], ml: [String]) -> [String] {
        var combined: [String] = []

        // Prioritize unique insights
        var seen = Set<String>()

        // Add ML insights first (more personalized)
        for insight in ml {
            let normalized = insight.lowercased()
            if !seen.contains(normalized) {
                combined.append(insight)
                seen.insert(normalized)
            }
        }

        // Add statistical insights
        for insight in statistical {
            let normalized = insight.lowercased()
            if !seen.contains(normalized) {
                combined.append(insight)
                seen.insert(normalized)
            }
        }

        // Limit to top 5
        return Array(combined.prefix(5))
    }

    // MARK: - Recommendations Combination

    private func combineRecommendations(statistical: [String], ml: [String]) -> [String] {
        var combined: [String] = []
        var seen = Set<String>()

        // Interleave recommendations
        let maxCount = max(statistical.count, ml.count)

        for i in 0..<maxCount {
            if i < ml.count {
                let rec = ml[i]
                let normalized = rec.lowercased()
                if !seen.contains(normalized) {
                    combined.append(rec)
                    seen.insert(normalized)
                }
            }

            if i < statistical.count {
                let rec = statistical[i]
                let normalized = rec.lowercased()
                if !seen.contains(normalized) {
                    combined.append(rec)
                    seen.insert(normalized)
                }
            }
        }

        // Limit to top 5
        return Array(combined.prefix(5))
    }

    // MARK: - Confidence Metrics

    private func calculateConfidenceMetrics(
        statistical: SimpleStatisticalAnalyzer.ComprehensiveAnalysis,
        ml: MLAnalysisResult?,
        mode: AnalysisMode,
        entryCount: Int
    ) -> ConfidenceMetrics {

        let statConfidence = statistical.calculatedConfidence

        let mlConfidence: Double
        if let ml = ml {
            mlConfidence = ml.confidence
        } else {
            mlConfidence = 0
        }

        // Data quality based on entry count and mode requirements
        let dataQuality: Double
        switch mode {
        case .statisticalOnly:
            dataQuality = min(1.0, Double(entryCount) / 30.0)
        case .basicML:
            dataQuality = min(1.0, Double(entryCount) / 90.0)
        case .hybridBalanced:
            dataQuality = min(1.0, Double(entryCount) / 180.0)
        case .mlPrimary:
            dataQuality = min(1.0, Double(entryCount) / 365.0)
        }

        let blendWeights = ConfidenceMetrics.BlendWeights(
            statistical: mode.statisticalWeight,
            ml: mode.mlWeight
        )

        return ConfidenceMetrics(
            statisticalConfidence: statConfidence,
            mlConfidence: mlConfidence,
            dataQuality: dataQuality,
            blendWeights: blendWeights
        )
    }

    // MARK: - Trend Analysis

    private func buildTrendAnalysis(
        from statistical: SimpleStatisticalAnalyzer.ComprehensiveAnalysis
    ) -> TrendAnalysis? {

        let statTrend = statistical.overallTrend

        let direction: TrendDirection
        switch statTrend.trending {
        case .improving: direction = .improving
        case .worsening: direction = .worsening
        case .stable: direction = .stable
        }

        return TrendAnalysis(
            direction: direction,
            slope: statTrend.slope,
            confidence: statTrend.rSquared,
            period: "recent"
        )
    }
}

// MARK: - MLAnalysisResult Extensions

extension MLAnalysisResult {

    func calculateHealthScore() -> Double {
        // Derive health score from prediction and patterns
        var score = 50.0 // Base score

        // Add prediction influence
        if let prediction = prediction {
            let moodContribution = Double(prediction.level.rawValue) / 5.0 * 40.0
            score += moodContribution - 20.0 // Center around 50
        }

        // Add pattern influence
        let positivePatterns = patterns.filter { $0.strength > 0.5 }.count
        let negativePatterns = patterns.filter { $0.strength < -0.5 }.count
        score += Double(positivePatterns - negativePatterns) * 5.0

        return max(0, min(100, score))
    }

    func extractFactorImpacts() -> [FactorImpact] {
        var impacts: [FactorImpact] = []

        // Extract from patterns
        for pattern in patterns {
            let impact: Double
            switch pattern.type {
            case .sleepCorrelation, .exerciseBenefit, .mindfulnessImpact:
                impact = pattern.strength
            case .substanceTrigger:
                impact = -pattern.strength
            default:
                impact = pattern.strength * 0.5
            }

            impacts.append(FactorImpact(
                factor: pattern.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                impact: impact,
                confidence: pattern.confidence,
                trend: .stable
            ))
        }

        // Extract from prediction contributing factors
        if let prediction = prediction {
            for (name, value) in prediction.contributingFactors {
                impacts.append(FactorImpact(
                    factor: name,
                    impact: value,
                    confidence: prediction.confidence,
                    trend: value > 0 ? .improving : .worsening
                ))
            }
        }

        return impacts
    }

    func generateInsights() -> [String] {
        var insights: [String] = []

        // Prediction insight
        if let prediction = prediction {
            insights.append("Predicted mood for tomorrow: \(prediction.level.displayName)")
        }

        // Pattern insights
        for pattern in patterns.prefix(3) {
            insights.append(pattern.description)
        }

        // Similar days insight
        if !similarDays.isEmpty {
            let avgMood = similarDays.map { Double($0.mood.rawValue) }.reduce(0, +) / Double(similarDays.count)
            insights.append("Similar past days had an average mood of \(String(format: "%.1f", avgMood))")
        }

        return insights
    }
}

// MARK: - Fallback Strategy

enum FallbackStrategy {
    case useStatisticalOnly
    case blendWithReduction
    case showBothWithWarning
    case deferToUserChoice

    static func determine(mlConfidence: Double, dataQuality: Double) -> FallbackStrategy {
        if mlConfidence < 0.3 {
            return .useStatisticalOnly
        }
        if mlConfidence < 0.5 {
            return .blendWithReduction
        }
        if dataQuality < 0.5 {
            return .showBothWithWarning
        }
        return .blendWithReduction
    }
}

// MARK: - SimpleStatisticalAnalyzer Extensions for Hybrid Compatibility

extension SimpleStatisticalAnalyzer.ComprehensiveAnalysis {

    var calculatedConfidence: Double {
        // Calculate confidence based on factor confidences
        let confidences = allFactors.map(\.confidence)
        guard !confidences.isEmpty else { return 0.5 }
        return confidences.reduce(0, +) / Double(confidences.count)
    }

    var trend: TrendAnalysis? {
        TrendAnalysis(
            direction: convertTrendDirection(overallTrend.trending),
            slope: overallTrend.slope,
            confidence: overallTrend.rSquared,
            period: "recent"
        )
    }

    private func convertTrendDirection(_ trending: SimpleStatisticalAnalyzer.TrendAnalysis.Trending) -> TrendDirection {
        switch trending {
        case .improving: return .improving
        case .worsening: return .worsening
        case .stable: return .stable
        }
    }
}

extension SimpleStatisticalAnalyzer.FactorImpact {

    var factor: String { name }
    var impact: Double { impactScore }

    var trendDirection: TrendDirection {
        switch trend {
        case .strongImprovement, .improving: return .improving
        case .worsening, .strongDecline: return .worsening
        case .stable: return .stable
        }
    }
}

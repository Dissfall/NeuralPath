//
//  MLAnalysisComponents.swift
//  NeuralPath
//
//  UI components for ML analysis results
//

import SwiftUI
import Charts

// MARK: - ML Prediction Card

struct MLPredictionCard: View {
    let prediction: MoodPrediction

    var moodColor: Color {
        switch prediction.level {
        case .veryLow: return .red
        case .low: return .orange
        case .moderate: return .blue
        case .good: return .mint
        case .excellent: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tomorrow's Outlook", systemImage: "sun.horizon.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                Spacer()

                ConfidenceBadge(confidence: prediction.confidence)
            }

            HStack(spacing: 16) {
                // Mood prediction circle
                ZStack {
                    Circle()
                        .fill(moodColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Text(prediction.level.emoji)
                        .font(.title)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Predicted: \(prediction.level.displayName)")
                        .font(.subheadline.bold())

                    Text("Based on today's patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Contributing factors
            if !prediction.contributingFactors.isEmpty {
                Divider()

                Text("Key factors:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 6) {
                    ForEach(Array(prediction.contributingFactors.prefix(4).enumerated()), id: \.offset) { _, factor in
                        ContributingFactorChip(name: factor.name, value: factor.impact)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ContributingFactorChip: View {
    let name: String
    let value: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: value > 0 ? "arrow.up" : "arrow.down")
                .font(.caption2)
            Text(name)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(value > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - 7-Day Forecast Chart

struct ForecastChart: View {
    let forecast: [ForecastPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("7-Day Forecast", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundColor(.purple)

            if forecast.isEmpty {
                Text("Not enough data for forecasting")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            } else {
                Chart {
                    ForEach(forecast) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Score", point.predictedScore * 100)
                        )
                        .foregroundStyle(.purple.gradient)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            yStart: .value("Low", max(0, (point.predictedScore - point.confidenceInterval) * 100)),
                            yEnd: .value("High", min(100, (point.predictedScore + point.confidenceInterval) * 100))
                        )
                        .foregroundStyle(.purple.opacity(0.1))
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Pattern Detection Card

struct PatternCard: View {
    let pattern: DetectedPattern

    var patternIcon: String {
        switch pattern.type {
        case .weekly: return "calendar"
        case .medicationEffect: return "pills.fill"
        case .substanceTrigger: return "drop.triangle.fill"
        case .sleepCorrelation: return "moon.zzz.fill"
        case .exerciseBenefit: return "figure.run"
        case .mindfulnessImpact: return "brain.head.profile"
        case .seasonalTrend: return "leaf.fill"
        }
    }

    var patternColor: Color {
        switch pattern.type {
        case .medicationEffect: return .blue
        case .substanceTrigger: return .orange
        case .sleepCorrelation: return .indigo
        case .exerciseBenefit: return .green
        case .mindfulnessImpact: return .teal
        case .weekly: return .purple
        case .seasonalTrend: return .mint
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: patternIcon)
                    .foregroundColor(patternColor)

                Text(pattern.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline.bold())

                Spacer()

                ConfidenceBadge(confidence: pattern.confidence)
            }

            Text(pattern.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let recommendation = pattern.recommendation {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(recommendation)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(patternColor.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PatternsSection: View {
    let patterns: [DetectedPattern]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Detected Patterns", systemImage: "waveform.path.ecg")
                .font(.headline)
                .foregroundColor(.teal)
                .padding(.horizontal)

            ForEach(patterns) { pattern in
                PatternCard(pattern: pattern)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Similar Days Card

struct SimilarDaysCard: View {
    let similarDays: [SimilarDay]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Similar Past Days", systemImage: "calendar.badge.clock")
                .font(.headline)
                .foregroundColor(.cyan)

            if similarDays.isEmpty {
                Text("No similar days found yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(similarDays) { day in
                    HStack {
                        Text(day.date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption.bold())

                        Spacer()

                        Text(day.mood.emoji)
                        Text(day.mood.displayName)
                            .font(.caption)

                        Text("\(Int(day.similarity * 100))% similar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.cyan.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Data Quality Card

struct DataQualityCard: View {
    let quality: DataQualityAssessment

    var qualityColor: Color {
        if quality.qualityScore > 70 { return .green }
        if quality.qualityScore > 40 { return .orange }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Data Quality", systemImage: "chart.bar.doc.horizontal")
                    .font(.headline)

                Spacer()

                Text("\(Int(quality.qualityScore))%")
                    .font(.title3.bold())
                    .foregroundColor(qualityColor)
            }

            // Progress to next milestone
            if let milestone = quality.nextMilestone {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Next: \(milestone.capability.displayName)")
                            .font(.caption.bold())
                        Spacer()
                        Text("\(milestone.entriesNeeded) entries needed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(quality.totalEntries), total: Double(quality.totalEntries + milestone.entriesNeeded))
                        .tint(.blue)
                }
            }

            // Current capabilities
            let capabilities = Array(quality.analysisCapabilities).sorted { $0.entriesRequired < $1.entriesRequired }
            if !capabilities.isEmpty {
                Divider()

                Text("Unlocked features:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 6) {
                    ForEach(capabilities, id: \.self) { capability in
                        Text(capability.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - ML Status Banner

struct MLStatusBanner: View {
    let mode: AnalysisMode
    let modelState: MLModelManager.ModelState

    var statusColor: Color {
        switch modelState {
        case .ready: return .green
        case .initializing: return .orange
        case .needsRetraining: return .yellow
        case .notInitialized: return .gray
        case .error: return .red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(modeDescription)
                .font(.caption)

            Spacer()

            if case .error(let message) = modelState {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
    }

    var modeDescription: String {
        switch mode {
        case .statisticalOnly:
            return "Statistical Analysis"
        case .basicML:
            return "Basic ML Active"
        case .hybridBalanced:
            return "Hybrid AI Analysis"
        case .mlPrimary:
            return "Advanced AI Analysis"
        }
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: Double

    var confidenceLevel: String {
        if confidence > 0.8 { return "High" }
        if confidence > 0.5 { return "Medium" }
        return "Low"
    }

    var color: Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.5 { return .orange }
        return .gray
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption2)
            Text("\(confidenceLevel)")
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.2))
        .cornerRadius(6)
    }
}

// MARK: - Hybrid Insight Card

struct HybridInsightCard: View {
    let insight: HybridInsight

    var categoryColor: Color {
        switch insight.category {
        case .prediction: return .orange
        case .pattern: return .teal
        case .trend: return .purple
        case .factor: return .blue
        case .recommendation: return .green
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundColor(categoryColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline.bold())

                    if insight.isMLDerived {
                        Image(systemName: "cpu")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }

                    Spacer()

                    ConfidenceBadge(confidence: insight.confidence)
                }

                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let recommendation = insight.recommendation {
                    Text(recommendation)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(categoryColor.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
    }
}

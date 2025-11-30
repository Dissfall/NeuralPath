import SwiftUI
import SwiftData
import Charts

struct ComprehensiveAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hybridEngine = HybridAnalysisEngine()
    @State private var analyzer = SimpleStatisticalAnalyzer()
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]
    @State private var hybridAnalysis: HybridAnalysis?
    @State private var statisticalAnalysis: SimpleStatisticalAnalyzer.ComprehensiveAnalysis?
    @State private var isAnalyzing = false
    @State private var selectedTimeRange = AnalysisTimeRange.month
    @State private var showAllFactors = false
    @State private var showMLDetails = false
    @State private var dataQuality: DataQualityAssessment?

    private var modelManager: MLModelManager { MLModelManager.shared }

    enum AnalysisTimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case all = "All Time"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .all: return Int.max
            }
        }
    }

    var filteredEntries: [SymptomEntry] {
        guard selectedTimeRange != .all else { return entries }
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -selectedTimeRange.days,
            to: Date()
        ) ?? Date()
        return entries.filter { ($0.timestamp ?? Date.distantPast) > cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ML Status Banner
                    if modelManager.isMLEnabled {
                        MLStatusBanner(
                            mode: hybridAnalysis?.mode ?? .statisticalOnly,
                            modelState: modelManager.overallState
                        )
                    }

                    // Time range selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(AnalysisTimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) {
                        runAnalysis()
                    }

                    if isAnalyzing {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text(modelManager.isMLEnabled ? "Running AI analysis..." : "Analyzing your data...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let hybrid = hybridAnalysis {
                        // Overall Health Score Card
                        if let statAnalysis = statisticalAnalysis {
                            OverallHealthCard(
                                score: hybrid.healthScore,
                                trend: statAnalysis.overallTrend
                            )
                        }

                        // ML Prediction (if available)
                        if let prediction = hybrid.predictions?.prediction {
                            MLPredictionCard(prediction: prediction)
                        }

                        // 7-Day Forecast (if available)
                        if let forecast = hybrid.forecast, !forecast.isEmpty {
                            ForecastChart(forecast: forecast)
                        }

                        // Detected Patterns (if available)
                        if let patterns = hybrid.patterns, !patterns.isEmpty {
                            PatternsSection(patterns: Array(patterns.prefix(3)))

                            if patterns.count > 3 {
                                Button {
                                    showMLDetails = true
                                } label: {
                                    Label("View All \(patterns.count) Patterns", systemImage: "chevron.right")
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        // Similar Days
                        if let similarDays = hybrid.predictions?.similarDays, !similarDays.isEmpty {
                            SimilarDaysCard(similarDays: similarDays)
                        }

                        // Top Positive Factors
                        let positiveFactors = hybrid.factorImpacts.filter { $0.impact > 0 }.prefix(3)
                        if !positiveFactors.isEmpty, let statAnalysis = statisticalAnalysis {
                            FactorsCard(
                                title: "Top Positive Factors",
                                icon: "star.fill",
                                factors: statAnalysis.topPositiveFactors,
                                color: .green
                            )
                        }

                        // Top Negative Factors
                        let negativeFactors = hybrid.factorImpacts.filter { $0.impact < 0 }.prefix(3)
                        if !negativeFactors.isEmpty, let statAnalysis = statisticalAnalysis {
                            FactorsCard(
                                title: "Top Negative Factors",
                                icon: "exclamationmark.triangle.fill",
                                factors: statAnalysis.topNegativeFactors,
                                color: .orange
                            )
                        }

                        // All Factors (expandable)
                        if let statAnalysis = statisticalAnalysis, showAllFactors && !statAnalysis.allFactors.isEmpty {
                            AllFactorsCard(factors: statAnalysis.allFactors)
                        }

                        Button(action: { withAnimation { showAllFactors.toggle() } }) {
                            Label(
                                showAllFactors ? "Hide All Factors" : "Show All Factors",
                                systemImage: showAllFactors ? "chevron.up" : "chevron.down"
                            )
                        }
                        .buttonStyle(.bordered)

                        // Key Insights (combined)
                        if !hybrid.insights.isEmpty {
                            InsightsCard(insights: hybrid.insights)
                        }

                        // Recommendations (combined)
                        if !hybrid.recommendations.isEmpty {
                            RecommendationsCard(recommendations: hybrid.recommendations)
                        }

                        // Data Quality Card
                        if let quality = dataQuality {
                            DataQualityCard(quality: quality)
                        }

                        // Confidence metrics
                        ConfidenceMetricsView(metrics: hybrid.confidence)

                    } else if let statAnalysis = statisticalAnalysis {
                        // Fallback to pure statistical analysis
                        OverallHealthCard(
                            score: statAnalysis.overallHealthScore,
                            trend: statAnalysis.overallTrend
                        )

                        if !statAnalysis.topPositiveFactors.isEmpty {
                            FactorsCard(
                                title: "Top Positive Factors",
                                icon: "star.fill",
                                factors: statAnalysis.topPositiveFactors,
                                color: .green
                            )
                        }

                        if !statAnalysis.topNegativeFactors.isEmpty {
                            FactorsCard(
                                title: "Top Negative Factors",
                                icon: "exclamationmark.triangle.fill",
                                factors: statAnalysis.topNegativeFactors,
                                color: .orange
                            )
                        }

                        if showAllFactors && !statAnalysis.allFactors.isEmpty {
                            AllFactorsCard(factors: statAnalysis.allFactors)
                        }

                        Button(action: { withAnimation { showAllFactors.toggle() } }) {
                            Label(
                                showAllFactors ? "Hide All Factors" : "Show All Factors",
                                systemImage: showAllFactors ? "chevron.up" : "chevron.down"
                            )
                        }
                        .buttonStyle(.bordered)

                        if !statAnalysis.keyInsights.isEmpty {
                            InsightsCard(insights: statAnalysis.keyInsights)
                        }

                        if !statAnalysis.recommendations.isEmpty {
                            RecommendationsCard(recommendations: statAnalysis.recommendations)
                        }

                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Updated \(statAnalysis.lastUpdated, format: .relative(presentation: .named))")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    } else {
                        // Empty state
                        ContentUnavailableView(
                            "No Analysis Available",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Add at least 7 entries to see analysis")
                        )
                        .frame(minHeight: 300)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Health Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        runAnalysis()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                runAnalysis()
            }
            .sheet(isPresented: $showMLDetails) {
                if let patterns = hybridAnalysis?.patterns {
                    MLDetailsSheet(patterns: patterns)
                }
            }
        }
        .onAppear {
            hybridEngine.configure(with: modelContext)
            if hybridAnalysis == nil && statisticalAnalysis == nil {
                runAnalysis()
            }
        }
    }

    private func runAnalysis() {
        guard filteredEntries.count >= 7 else {
            hybridAnalysis = nil
            statisticalAnalysis = nil
            return
        }

        Task { @MainActor in
            isAnalyzing = true

            // Small delay for better UX
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Always run statistical analysis
            statisticalAnalysis = analyzer.analyzeAllFactors(entries: Array(filteredEntries))

            // Run hybrid analysis if ML is enabled
            if modelManager.isMLEnabled {
                do {
                    hybridAnalysis = try await hybridEngine.analyze(entries: Array(filteredEntries))
                    dataQuality = try await hybridEngine.getDataQuality()
                } catch {
                    hybridAnalysis = nil
                }
            } else {
                hybridAnalysis = nil
            }

            isAnalyzing = false
        }
    }
}

// MARK: - Supporting Views

struct ConfidenceMetricsView: View {
    let metrics: ConfidenceMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Analysis Confidence", systemImage: "gauge.medium")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack {
                    Text("\(Int(metrics.statisticalConfidence * 100))%")
                        .font(.caption.bold())
                    Text("Statistical")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if metrics.mlConfidence > 0 {
                    VStack {
                        Text("\(Int(metrics.mlConfidence * 100))%")
                            .font(.caption.bold())
                        Text("ML")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                VStack {
                    Text("\(Int(metrics.dataQuality * 100))%")
                        .font(.caption.bold())
                    Text("Data Quality")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct MLDetailsSheet: View {
    let patterns: [DetectedPattern]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(patterns) { pattern in
                        PatternCard(pattern: pattern)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Detected Patterns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Component Views

struct OverallHealthCard: View {
    let score: Double
    let trend: SimpleStatisticalAnalyzer.TrendAnalysis

    var scoreColor: Color {
        if score > 70 { return .green }
        if score > 50 { return .blue }
        if score > 30 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 15) {
            Label("Overall Health Score", systemImage: "heart.text.square.fill")
                .font(.headline)

            // Score visualization
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1), value: score)

                VStack {
                    Text("\(Int(score))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("out of 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Trend indicator
            HStack {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                Text(trendText)
                    .font(.subheadline)
            }

            if let days = trend.daysToImprovement {
                Text("Estimated \(days) days to reach good level")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }

    var trendIcon: String {
        switch trend.trending {
        case .improving: return "arrow.up.right"
        case .worsening: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var trendColor: Color {
        switch trend.trending {
        case .improving: return .green
        case .worsening: return .red
        case .stable: return .blue
        }
    }

    var trendText: String {
        switch trend.trending {
        case .improving: return "Improving"
        case .worsening: return "Worsening"
        case .stable: return "Stable"
        }
    }
}

struct FactorsCard: View {
    let title: String
    let icon: String
    let factors: [SimpleStatisticalAnalyzer.FactorImpact]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)

            ForEach(Array(factors.enumerated()), id: \.element.id) { index, factor in
                FactorRow(factor: factor, rank: index + 1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct FactorRow: View {
    let factor: SimpleStatisticalAnalyzer.FactorImpact
    let rank: Int

    var impactColor: Color {
        if factor.impactScore > 0 {
            return factor.impactScore > 0.5 ? .green : .mint
        } else {
            return factor.impactScore < -0.5 ? .red : .orange
        }
    }

    var body: some View {
        HStack {
            // Rank
            Text("\(rank).")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .frame(width: 20)

            // Category icon
            Image(systemName: factor.icon)
                .foregroundColor(factor.category.color)
                .frame(width: 24)

            // Name and detail
            VStack(alignment: .leading, spacing: 2) {
                Text(factor.name)
                    .font(.subheadline.bold())
                Text(factor.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Impact visualization
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: factor.trend.icon)
                        .font(.caption)
                    Text("\(Int(abs(factor.impactScore * 100)))%")
                        .font(.caption.bold())
                }
                .foregroundColor(impactColor)

                // Confidence indicator
                HStack(spacing: 1) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(i < Int(factor.confidence * 5) ? Color.primary.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AllFactorsCard: View {
    let factors: [SimpleStatisticalAnalyzer.FactorImpact]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("All Factors Analysis", systemImage: "chart.bar.xaxis")
                .font(.headline)

            ForEach(Array(factors.enumerated()), id: \.element.id) { index, factor in
                FactorRow(factor: factor, rank: index + 1)
                if index < factors.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct InsightsCard: View {
    let insights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Insights", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.blue)

            ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.blue)
                        .padding(.top, 6)
                    Text(insight)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct RecommendationsCard: View {
    let recommendations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendations", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundColor(.purple)

            ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.top, 2)
                    Text(recommendation)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ComprehensiveAnalysisView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}
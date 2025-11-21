import SwiftUI
import SwiftData
import Charts

struct ComprehensiveAnalysisView: View {
    @State private var analyzer = SimpleStatisticalAnalyzer()
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]
    @State private var analysis: SimpleStatisticalAnalyzer.ComprehensiveAnalysis?
    @State private var isAnalyzing = false
    @State private var selectedTimeRange = TimeRange.month
    @State private var showAllFactors = false

    enum TimeRange: String, CaseIterable {
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
        return entries.filter { $0.timestamp > cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
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
                            Text("Analyzing your data...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let analysis = analysis {
                        // Overall Health Score Card
                        OverallHealthCard(
                            score: analysis.overallHealthScore,
                            trend: analysis.overallTrend
                        )

                        // Top Positive Factors
                        if !analysis.topPositiveFactors.isEmpty {
                            FactorsCard(
                                title: "Top Positive Factors",
                                icon: "star.fill",
                                factors: analysis.topPositiveFactors,
                                color: .green
                            )
                        }

                        // Top Negative Factors
                        if !analysis.topNegativeFactors.isEmpty {
                            FactorsCard(
                                title: "Top Negative Factors",
                                icon: "exclamationmark.triangle.fill",
                                factors: analysis.topNegativeFactors,
                                color: .orange
                            )
                        }

                        // All Factors (expandable)
                        if showAllFactors && !analysis.allFactors.isEmpty {
                            AllFactorsCard(factors: analysis.allFactors)
                        }

                        Button(action: { withAnimation { showAllFactors.toggle() } }) {
                            Label(
                                showAllFactors ? "Hide All Factors" : "Show All Factors",
                                systemImage: showAllFactors ? "chevron.up" : "chevron.down"
                            )
                        }
                        .buttonStyle(.bordered)

                        // Key Insights
                        if !analysis.keyInsights.isEmpty {
                            InsightsCard(insights: analysis.keyInsights)
                        }

                        // Recommendations
                        if !analysis.recommendations.isEmpty {
                            RecommendationsCard(recommendations: analysis.recommendations)
                        }

                        // Last updated
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Updated \(analysis.lastUpdated, format: .relative(presentation: .named))")
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
        }
        .onAppear {
            if analysis == nil {
                runAnalysis()
            }
        }
    }

    private func runAnalysis() {
        guard filteredEntries.count >= 7 else {
            analysis = nil
            return
        }

        Task { @MainActor in
            isAnalyzing = true

            // Small delay for better UX
            try? await Task.sleep(nanoseconds: 500_000_000)

            analysis = analyzer.analyzeAllFactors(entries: Array(filteredEntries))
            isAnalyzing = false
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
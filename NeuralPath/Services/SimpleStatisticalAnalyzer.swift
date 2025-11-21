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
        let beforeEntries = entries.filter { $0.timestamp < startDate }
        let afterEntries = entries.filter {
            $0.timestamp >= startDate &&
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
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        var xValues: [Double] = []  // Days from start
        var yValues: [Double] = []  // Symptom scores

        let startDate = sortedEntries[0].timestamp

        for entry in sortedEntries {
            let daysSinceStart = Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: entry.timestamp
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
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

        for entry in sortedEntries {
            if entry.medications?.contains(where: { $0.name == medication }) ?? false {
                return entry.timestamp
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
        let sortedEntries = allEntries.sorted { $0.timestamp < $1.timestamp }

        for (index, entry) in sortedEntries.enumerated() {
            // Check if this was a substance day
            if substanceDays.contains(where: { $0.id == entry.id }) {
                // Get next day's entry if it exists
                if index + 1 < sortedEntries.count {
                    let nextDay = sortedEntries[index + 1]

                    // Verify it's actually the next day (not same day)
                    let calendar = Calendar.current
                    if calendar.isDate(nextDay.timestamp, inSameDayAs: entry.timestamp) == false {
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
        Set(entries.flatMap { $0.medications ?? [] }.map { $0.name }).sorted()
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
                                    Text(substance.name).tag(substance.name as String?)
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

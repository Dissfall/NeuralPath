import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: \SymptomEntry.timestamp) private var entries: [SymptomEntry]
    @State private var selectedMetric: MetricType = .mood
    @State private var timeRange: TimeRange = .week
    @State private var selectedSubstance: String?
    @State private var comparisonMode: Bool = false
    @State private var primaryMetric: MetricType = .mood
    @State private var secondaryMetric: MetricType = .sleep

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Toggle("Compare Metrics", isOn: $comparisonMode)
                        .padding(.horizontal)

                    if comparisonMode {
                        HStack {
                            Text("Primary:")
                                .foregroundStyle(.secondary)
                            Picker("Primary Metric", selection: $primaryMetric) {
                                ForEach(availableMetricsForComparison, id: \.self) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal)

                        HStack {
                            Text("Secondary:")
                                .foregroundStyle(.secondary)
                            Picker("Secondary Metric", selection: $secondaryMetric) {
                                ForEach(availableMetricsForComparison, id: \.self) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal)
                    } else {
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(MetricType.allCases, id: \.self) { metric in
                                Text(metric.rawValue).tag(metric)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)

                        if selectedMetric == .substances {
                            Picker("Substance", selection: $selectedSubstance) {
                                Text("Select Substance").tag(nil as String?)
                                ForEach(uniqueSubstanceNames, id: \.self) { name in
                                    Text(name).tag(name as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal)
                        }
                    }

                    if filteredEntries.isEmpty {
                        ContentUnavailableView(
                            "No Data Available",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Add some entries to see charts")
                        )
                        .frame(height: 300)
                    } else {
                        if comparisonMode {
                            comparisonChartView
                                .padding()
                        } else {
                            chartView
                                .frame(height: 300)
                                .padding()
                        }

                        statsView
                            .padding()
                    }

                    Spacer()
                }
            }
            .navigationTitle("Charts")
        }
    }

    private var filteredEntries: [SymptomEntry] {
        let startDate = Calendar.current.date(byAdding: timeRange.dateComponent, value: -timeRange.value, to: Date()) ?? Date()
        return entries.filter { ($0.timestamp ?? Date.distantPast) >= startDate }
    }

    private var availableMetricsForComparison: [MetricType] {
        MetricType.allCases.filter { $0 != .substances }
    }

    private func getMetricValues(_ metric: MetricType) -> [Double?] {
        filteredEntries.map { entry in
            switch metric {
            case .mood:
                return entry.moodLevel.map { Double($0.rawValue) }
            case .anxiety:
                return entry.anxietyLevel.map { Double($0.rawValue) }
            case .anhedonia:
                return entry.anhedoniaLevel.map { Double($0.rawValue) }
            case .sleep:
                return entry.sleepHours
            case .timeInDaylight:
                return entry.timeInDaylightMinutes
            case .exercise:
                return entry.exerciseMinutes
            case .substances:
                return nil
            }
        }
    }

    private var correlationCoefficient: Double? {
        let primaryValues = getMetricValues(primaryMetric)
        let secondaryValues = getMetricValues(secondaryMetric)

        let pairs = zip(primaryValues, secondaryValues).compactMap { primary, secondary -> (Double, Double)? in
            guard let p = primary, let s = secondary else { return nil }
            return (p, s)
        }

        guard pairs.count >= 3 else { return nil }

        let n = Double(pairs.count)
        let sumX = pairs.reduce(0.0) { $0 + $1.0 }
        let sumY = pairs.reduce(0.0) { $0 + $1.1 }
        let sumXY = pairs.reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2 = pairs.reduce(0.0) { $0 + $1.0 * $1.0 }
        let sumY2 = pairs.reduce(0.0) { $0 + $1.1 * $1.1 }

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return nil }
        return numerator / denominator
    }

    private func interpretCorrelation(_ r: Double) -> String {
        let absR = abs(r)
        let direction = r >= 0 ? "positive" : "negative"

        if absR < 0.3 {
            return "Weak \(direction) correlation"
        } else if absR < 0.7 {
            return "Moderate \(direction) correlation"
        } else {
            return "Strong \(direction) correlation"
        }
    }

    @ViewBuilder
    private var comparisonChartView: some View {
        VStack(spacing: 12) {
            Text("Primary: \(primaryMetric.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)

            chartForMetric(primaryMetric)
                .frame(height: 250)

            Divider()

            Text("Secondary: \(secondaryMetric.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)

            chartForMetric(secondaryMetric)
                .frame(height: 250)
        }
    }

    @ViewBuilder
    private var chartView: some View {
        switch selectedMetric {
        case .mood:
            moodChart
        case .anxiety:
            anxietyChart
        case .anhedonia:
            anhedoniaChart
        case .sleep:
            sleepChart
        case .timeInDaylight:
            daylightChart
        case .exercise:
            exerciseChart
        case .substances:
            substancesChart
        }
    }

    private var moodChart: some View {
        Chart {
            ForEach(filteredEntries.filter { $0.moodLevel != nil }) { entry in
                LineMark(
                    x: .value("Date", entry.timestamp ?? Date()),
                    y: .value("Mood", entry.moodLevel?.rawValue ?? 0)
                )
                .foregroundStyle(.blue)

                PointMark(
                    x: .value("Date", entry.timestamp ?? Date()),
                    y: .value("Mood", entry.moodLevel?.rawValue ?? 0)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                if let intValue = value.as(Int.self),
                   let mood = MoodLevel(rawValue: intValue) {
                    AxisValueLabel {
                        Text(mood.emoji)
                    }
                }
            }
        }
    }

    private var anxietyChart: some View {
        Chart {
            ForEach(filteredEntries.filter { $0.anxietyLevel != nil }) { entry in
                BarMark(
                    x: .value("Date", entry.timestamp ?? Date(), unit: .day),
                    y: .value("Anxiety", entry.anxietyLevel?.rawValue ?? 0)
                )
                .foregroundStyle(.orange)
            }
        }
        .chartYScale(domain: 0...4)
    }

    private var anhedoniaChart: some View {
        Chart {
            ForEach(filteredEntries.filter { $0.anhedoniaLevel != nil }) { entry in
                LineMark(
                    x: .value("Date", entry.timestamp ?? Date()),
                    y: .value("Anhedonia", entry.anhedoniaLevel?.rawValue ?? 0)
                )
                .foregroundStyle(.purple)

                AreaMark(
                    x: .value("Date", entry.timestamp ?? Date()),
                    y: .value("Anhedonia", entry.anhedoniaLevel?.rawValue ?? 0)
                )
                .foregroundStyle(.purple.opacity(0.2))
            }
        }
        .chartYScale(domain: 0...4)
    }

    private var sleepChart: some View {
        Chart {
            ForEach(filteredEntries.filter { $0.sleepHours != nil }) { entry in
                BarMark(
                    x: .value("Date", entry.timestamp ?? Date(), unit: .day),
                    y: .value("Hours", entry.sleepHours ?? 0)
                )
                .foregroundStyle(.cyan)
            }

            RuleMark(y: .value("Recommended", 8))
                .foregroundStyle(.green.opacity(0.5))
                .lineStyle(StrokeStyle(dash: [5]))
        }
    }

    private var daylightChart: some View {
        Chart {
            ForEach(filteredEntries.filter { $0.timeInDaylightMinutes != nil }) { entry in
                BarMark(
                    x: .value("Date", entry.timestamp ?? Date(), unit: .day),
                    y: .value("Minutes", entry.timeInDaylightMinutes ?? 0)
                )
                .foregroundStyle(.yellow)
            }

            RuleMark(y: .value("Recommended", 120))
                .foregroundStyle(.green.opacity(0.5))
                .lineStyle(StrokeStyle(dash: [5]))
        }
    }

    private var exerciseChart: some View {
        Chart {
            ForEach(filteredEntries.filter { $0.exerciseMinutes != nil }) { entry in
                BarMark(
                    x: .value("Date", entry.timestamp ?? Date(), unit: .day),
                    y: .value("Minutes", entry.exerciseMinutes ?? 0)
                )
                .foregroundStyle(.green)
            }

            RuleMark(y: .value("Goal", 30))
                .foregroundStyle(.green.opacity(0.5))
                .lineStyle(StrokeStyle(dash: [5]))
        }
    }

    private var substancesChart: some View {
        Group {
            if selectedSubstance == nil {
                ContentUnavailableView(
                    "Select a Substance",
                    systemImage: "drop.fill",
                    description: Text("Choose a substance from the menu above")
                )
            } else if filteredSubstances.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "calendar",
                    description: Text("No consumption data for this time period")
                )
            } else {
                Chart {
                    ForEach(filteredSubstances, id: \.substance.id) { item in
                        BarMark(
                            x: .value("Date", item.entry.timestamp ?? Date(), unit: .day),
                            y: .value("Amount", item.substance.amount ?? 0.0)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("\(String(format: "%.0f", amount)) \(substanceUnit)")
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chartForMetric(_ metric: MetricType) -> some View {
        switch metric {
        case .mood:
            moodChart
        case .anxiety:
            anxietyChart
        case .anhedonia:
            anhedoniaChart
        case .sleep:
            sleepChart
        case .timeInDaylight:
            daylightChart
        case .exercise:
            exerciseChart
        case .substances:
            EmptyView()
        }
    }

    private var statsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            if comparisonMode {
                if let correlation = correlationCoefficient {
                    StatRow(
                        label: "Correlation",
                        value: String(format: "%.3f", correlation)
                    )
                    StatRow(
                        label: "Interpretation",
                        value: interpretCorrelation(correlation)
                    )
                } else {
                    Text("Insufficient data for correlation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                switch selectedMetric {
                case .mood:
                    if let avgMood = averageMood {
                        StatRow(label: "Average Mood", value: avgMood.displayName)
                    }
                case .anxiety:
                    if let avgAnxiety = averageAnxiety {
                        StatRow(label: "Average Anxiety", value: String(format: "%.1f/4", avgAnxiety))
                    }
                case .anhedonia:
                    if let avgAnhedonia = averageAnhedonia {
                        StatRow(label: "Average Anhedonia", value: String(format: "%.1f/4", avgAnhedonia))
                    }
                case .sleep:
                    if let avgSleep = averageSleep {
                        StatRow(label: "Average Sleep", value: String(format: "%.1f hours", avgSleep))
                    }
                case .timeInDaylight:
                    if let avgDaylight = averageDaylight {
                        StatRow(label: "Average Daylight", value: String(format: "%.0f minutes", avgDaylight))
                    }
                case .exercise:
                    if let avgExercise = averageExercise {
                        StatRow(label: "Average Exercise", value: String(format: "%.0f minutes", avgExercise))
                    }
                case .substances:
                    if selectedSubstance != nil && !filteredSubstances.isEmpty {
                        StatRow(
                            label: "Total Consumption",
                            value: "\(String(format: "%.1f", totalSubstanceConsumption)) \(substanceUnit)"
                        )
                        StatRow(
                            label: "Average per Entry",
                            value: "\(String(format: "%.1f", averageSubstanceConsumption)) \(substanceUnit)"
                        )
                        StatRow(
                            label: "Frequency",
                            value: "\(filteredSubstances.count) times"
                        )
                    }
                }
            }

            StatRow(label: "Total Entries", value: "\(filteredEntries.count)")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var averageMood: MoodLevel? {
        let moods = filteredEntries.compactMap { $0.moodLevel }
        guard !moods.isEmpty else { return nil }
        let avg = moods.map { $0.rawValue }.reduce(0, +) / moods.count
        return MoodLevel(rawValue: avg)
    }

    private var averageAnxiety: Double? {
        let anxieties = filteredEntries.compactMap { $0.anxietyLevel?.rawValue }
        guard !anxieties.isEmpty else { return nil }
        return Double(anxieties.reduce(0, +)) / Double(anxieties.count)
    }

    private var averageAnhedonia: Double? {
        let levels = filteredEntries.compactMap { $0.anhedoniaLevel?.rawValue }
        guard !levels.isEmpty else { return nil }
        return Double(levels.reduce(0, +)) / Double(levels.count)
    }

    private var averageSleep: Double? {
        let sleepHours = filteredEntries.compactMap { $0.sleepHours }
        guard !sleepHours.isEmpty else { return nil }
        return sleepHours.reduce(0, +) / Double(sleepHours.count)
    }

    private var averageDaylight: Double? {
        let values = filteredEntries.compactMap { $0.timeInDaylightMinutes }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var averageExercise: Double? {
        let values = filteredEntries.compactMap { $0.exerciseMinutes }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var allSubstances: [(substance: Substance, entry: SymptomEntry)] {
        entries.flatMap { entry in
            (entry.substances ?? []).map { (substance: $0, entry: entry) }
        }
    }

    private var uniqueSubstanceNames: [String] {
        let names = Set(allSubstances.compactMap { $0.substance.name })
        return names.sorted()
    }

    private var filteredSubstances: [(substance: Substance, entry: SymptomEntry)] {
        let startDate = Calendar.current.date(
            byAdding: timeRange.dateComponent,
            value: -timeRange.value,
            to: Date()
        ) ?? Date()

        return allSubstances.filter { item in
            guard let selectedName = selectedSubstance else { return false }
            return item.substance.name == selectedName &&
                   (item.entry.timestamp ?? Date.distantPast) >= startDate
        }
    }

    private var totalSubstanceConsumption: Double {
        filteredSubstances.reduce(0) { $0 + ($1.substance.amount ?? 0.0) }
    }

    private var averageSubstanceConsumption: Double {
        guard !filteredSubstances.isEmpty else { return 0 }
        return totalSubstanceConsumption / Double(filteredSubstances.count)
    }

    private var substanceUnit: String {
        guard let first = filteredSubstances.first else { return "" }
        return first.substance.unit?.abbreviation ?? ""
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

enum MetricType: String, CaseIterable {
    case mood = "Mood"
    case anxiety = "Anxiety"
    case anhedonia = "Anhedonia"
    case sleep = "Sleep"
    case timeInDaylight = "Daylight"
    case exercise = "Exercise"
    case substances = "Substances"
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"

    var value: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }

    var dateComponent: Calendar.Component {
        .day
    }
}

#Preview {
    ChartsView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

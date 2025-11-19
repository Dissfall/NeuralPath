import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \SymptomEntry.timestamp) private var entries: [SymptomEntry]
    @State private var mlManager = MLManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !mlManager.isModelLoaded {
                        modelNotLoadedView
                    } else if entries.count < 30 {
                        insufficientDataView
                    } else {
                        insightsContent
                    }
                }
                .padding()
            }
            .navigationTitle("AI Insights")
        }
    }

    @ViewBuilder
    private var insightsContent: some View {
        medicationEffectivenessCard

        aiInsightsCard

        whatIfPredictorCard
    }

    private var modelNotLoadedView: some View {
        ContentUnavailableView(
            "Models Not Loaded",
            systemImage: "brain",
            description: Text("Please add the trained Core ML models to the project")
        )
    }

    private var insufficientDataView: some View {
        ContentUnavailableView(
            "Not Enough Data",
            systemImage: "chart.bar.doc.horizontal",
            description: Text("Record at least 30 entries to generate insights")
        )
    }

    private var medicationEffectivenessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Medication Effectiveness", systemImage: "pills.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            if let effectiveness = mlManager.analyzeMedicationEffectiveness(entries: entries) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Days on Medication")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(effectiveness.daysWithMedication)")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Days without")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(effectiveness.daysWithoutMedication)")
                                .font(.title2)
                                .bold()
                        }
                    }

                    Divider()

                    EffectivenessRow(
                        label: "Mood Improvement",
                        value: effectiveness.moodImprovement,
                        isPositive: effectiveness.moodImprovement > 0
                    )

                    EffectivenessRow(
                        label: "Anxiety Reduction",
                        value: effectiveness.anxietyReduction,
                        isPositive: effectiveness.anxietyReduction > 0
                    )

                    EffectivenessRow(
                        label: "Anhedonia Reduction",
                        value: effectiveness.anhedoniaReduction,
                        isPositive: effectiveness.anhedoniaReduction > 0
                    )

                    HStack {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView(value: effectiveness.confidence)
                            .frame(width: 100)
                        Text("\(Int(effectiveness.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Need at least 10 days with and without medication to analyze")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var aiInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI-Generated Insights", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.purple)

            let insights = mlManager.generateInsights(entries: entries)

            if insights.isEmpty {
                Text("Not enough data to generate insights yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var whatIfPredictorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What-If Predictor", systemImage: "wand.and.stars")
                .font(.headline)
                .foregroundStyle(.orange)

            Text("See how different behaviors might affect your mood")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let latestEntry = entries.last {
                WhatIfPredictor(latestEntry: latestEntry)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EffectivenessRow: View {
    let label: String
    let value: Double
    let isPositive: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(isPositive ? .green : .red)
                Text(String(format: "%.2f", abs(value)))
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(isPositive ? .green : .red)
            }
        }
    }
}

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.impact.icon)
                .foregroundStyle(Color(insight.impact.color))
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .bold()

                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Confidence:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ProgressView(value: insight.confidence)
                        .frame(width: 60)
                    Text("\(Int(insight.confidence * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct WhatIfPredictor: View {
    let latestEntry: SymptomEntry
    @State private var mlManager = MLManager.shared

    @State private var sleepHours: Double = 8.0
    @State private var exerciseMinutes: Double = 30.0
    @State private var daylightMinutes: Double = 120.0
    @State private var takeMedication: Bool = true
    @State private var substanceAmount: Double = 0.0

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sleep Hours")
                    Spacer()
                    Text(String(format: "%.1f", sleepHours))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $sleepHours, in: 4...10, step: 0.5)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Exercise (minutes)")
                    Spacer()
                    Text(String(format: "%.0f", exerciseMinutes))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $exerciseMinutes, in: 0...120, step: 15)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daylight (minutes)")
                    Spacer()
                    Text(String(format: "%.0f", daylightMinutes))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $daylightMinutes, in: 0...300, step: 30)
            }

            Toggle("Take Medication", isOn: $takeMedication)

            Divider()

            if let predictedMood = mlManager.predictMood(
                sleepHours: sleepHours,
                sleepQuality: latestEntry.sleepQualityRating ?? 3,
                daylightMinutes: daylightMinutes,
                exerciseMinutes: exerciseMinutes,
                medicationTaken: takeMedication,
                substanceAmount: substanceAmount,
                dayOfWeek: Calendar.current.component(.weekday, from: Date()),
                previousDaySleep: latestEntry.sleepHours ?? 7.0,
                previousDayMood: latestEntry.moodLevel?.rawValue ?? 3
            ) {
                VStack(spacing: 8) {
                    Text("Predicted Mood")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= Int(predictedMood.rounded()) ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                        }
                    }

                    Text(String(format: "%.1f / 5.0", predictedMood))
                        .font(.title2)
                        .bold()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

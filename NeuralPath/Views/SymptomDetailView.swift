import SwiftUI
import SwiftData

struct SymptomDetailView: View {
    let entry: SymptomEntry

    var body: some View {
        List {
            Section("Date & Time") {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(entry.timestamp, style: .date)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Time")
                    Spacer()
                    Text(entry.timestamp, style: .time)
                        .foregroundStyle(.secondary)
                }
            }

            if let mood = entry.moodLevel {
                Section("Mood") {
                    HStack {
                        Text(mood.emoji)
                            .font(.title)
                        Text(mood.displayName)
                            .font(.headline)
                    }
                }
            }

            if let anxiety = entry.anxietyLevel {
                Section("Anxiety") {
                    HStack {
                        Text("Level")
                        Spacer()
                        Text(anxiety.displayName)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }

            if let anhedonia = entry.anhedoniaLevel {
                Section("Anhedonia") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Level")
                            Spacer()
                            Text(anhedonia.displayName)
                        }
                        .font(.headline)

                        Text(anhedonia.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if entry.sleepHours != nil || entry.sleepQualityRating != nil {
                Section("Sleep") {
                    if let hours = entry.sleepHours {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(String(format: "%.1f", hours)) hours")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let quality = entry.sleepQualityRating {
                        HStack {
                            Text("Quality")
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= quality ? "star.fill" : "star")
                                        .foregroundStyle(star <= quality ? .yellow : .gray)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }

            if let medications = entry.medications, !medications.isEmpty {
                Section("Medications") {
                    ForEach(medications) { medication in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(medication.name)
                                    .font(.headline)
                                Spacer()
                                if medication.taken {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            Text(medication.dosage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !medication.notes.isEmpty {
                                Text(medication.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !entry.notes.isEmpty {
                Section("Notes") {
                    Text(entry.notes)
                }
            }
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SymptomDetailView(entry: SymptomEntry(
            timestamp: Date(),
            moodLevel: .good,
            anxietyLevel: .mild,
            anhedoniaLevel: .moderate,
            sleepQualityRating: 4,
            sleepHours: 7.5,
            notes: "Feeling better today after good sleep"
        ))
    }
}

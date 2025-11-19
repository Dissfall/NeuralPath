import SwiftUI
import SwiftData

struct SymptomDetailView: View {
    let entry: SymptomEntry

    @Query private var allEntries: [SymptomEntry]

    private var freshEntry: SymptomEntry? {
        allEntries.first { $0.id == entry.id }
    }

    var body: some View {
        let displayEntry = freshEntry ?? entry
        List {
            Section("Date & Time") {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(displayEntry.timestamp, style: .date)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Time")
                    Spacer()
                    Text(displayEntry.timestamp, style: .time)
                        .foregroundStyle(.secondary)
                }
            }

            if let mood = displayEntry.moodLevel {
                Section("Mood") {
                    HStack {
                        Text(mood.emoji)
                            .font(.title)
                        Text(mood.displayName)
                            .font(.headline)
                    }
                }
            }

            if let anxiety = displayEntry.anxietyLevel {
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

            if let anhedonia = displayEntry.anhedoniaLevel {
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

            if displayEntry.sleepHours != nil || displayEntry.sleepQualityRating != nil {
                Section("Sleep") {
                    if let hours = displayEntry.sleepHours {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(String(format: "%.1f", hours)) hours")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let quality = displayEntry.sleepQualityRating {
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

            if let medications = displayEntry.medications, !medications.isEmpty {
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
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
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

            if let substances = displayEntry.substances, !substances.isEmpty {
                Section("Substances") {
                    ForEach(substances) { substance in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(substance.name)
                                .font(.headline)
                            HStack {
                                Text("Amount")
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", substance.amount)) \(substance.unit.abbreviation)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !substance.notes.isEmpty {
                                Text(substance.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !displayEntry.notes.isEmpty {
                Section("Notes") {
                    Text(displayEntry.notes)
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

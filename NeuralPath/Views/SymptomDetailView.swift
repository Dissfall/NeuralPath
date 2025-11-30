import SwiftUI
import SwiftData

struct SymptomDetailView: View {
    let entry: SymptomEntry

    @Query private var allEntries: [SymptomEntry]
    @Query private var allMindfulnessLogs: [MindfulnessLog]
    @Query private var allSelfCareLogs: [SelfCareLog]
    @State private var showingEditSheet = false

    private var freshEntry: SymptomEntry? {
        allEntries.first { $0.id == entry.id }
    }

    private var mindfulnessLogsForDay: [MindfulnessLog] {
        guard let entryDate = (freshEntry ?? entry).timestamp else { return [] }
        return allMindfulnessLogs.filter { log in
            guard let logDate = log.timestamp else { return false }
            return Calendar.current.isDate(logDate, inSameDayAs: entryDate)
        }.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    private var selfCareLogsForDay: [SelfCareLog] {
        guard let entryDate = (freshEntry ?? entry).timestamp else { return [] }
        return allSelfCareLogs.filter { log in
            guard let logDate = log.timestamp else { return false }
            return Calendar.current.isDate(logDate, inSameDayAs: entryDate)
        }.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    var body: some View {
        let displayEntry = freshEntry ?? entry
        List {
            Section("Date & Time") {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(displayEntry.timestamp ?? Date(), style: .date)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Time")
                    Spacer()
                    Text(displayEntry.timestamp ?? Date(), style: .time)
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

            if !displayEntry.emotions.isEmpty {
                Section("Feelings") {
                    WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(displayEntry.emotions) { emotion in
                            Text(emotion.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(emotion.color.opacity(0.2))
                                .foregroundStyle(emotion.color)
                                .clipShape(Capsule())
                        }
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

            if displayEntry.timeInDaylightMinutes != nil || displayEntry.exerciseMinutes != nil {
                Section("Activity") {
                    if let daylight = displayEntry.timeInDaylightMinutes {
                        HStack {
                            Text("Time in Daylight")
                            Spacer()
                            Text("\(String(format: "%.0f", daylight)) minutes")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let exercise = displayEntry.exerciseMinutes {
                        HStack {
                            Text("Exercise")
                            Spacer()
                            Text("\(String(format: "%.0f", exercise)) minutes")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let medications = displayEntry.medications, !medications.isEmpty {
                Section("Medications") {
                    ForEach(medications) { medication in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(medication.name ?? "")
                                    .font(.headline)
                                Spacer()
                                if medication.taken == true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            Text(medication.dosage ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let notes = medication.notes, !notes.isEmpty {
                                Text(notes)
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
                            Text(substance.name ?? "")
                                .font(.headline)
                            HStack {
                                Text("Amount")
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", substance.amount ?? 0.0)) \(substance.unit?.abbreviation ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let notes = substance.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !mindfulnessLogsForDay.isEmpty {
                Section("Mindfulness") {
                    ForEach(mindfulnessLogsForDay) { log in
                        HStack {
                            if let category = log.userMindfulness?.category {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                                    .frame(width: 24)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.practiceName ?? "")
                                    .font(.subheadline)
                                if let time = log.timestamp {
                                    Text(time, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            if !selfCareLogsForDay.isEmpty {
                Section("Self-Care") {
                    ForEach(SelfCareTimeOfDay.allCases) { timeOfDay in
                        let logsForTime = selfCareLogsForDay.filter { $0.timeOfDay == timeOfDay }
                        if !logsForTime.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(timeOfDay.displayName, systemImage: timeOfDay.icon)
                                    .font(.caption)
                                    .foregroundStyle(timeOfDay.color)
                                ForEach(logsForTime) { log in
                                    HStack {
                                        Text(log.practiceName ?? "")
                                            .font(.subheadline)
                                        Spacer()
                                        if let time = log.timestamp {
                                            Text(time, style: .time)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if let notes = displayEntry.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let displayEntry = freshEntry {
                AddSymptomView(entryToEdit: displayEntry)
            }
        }
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

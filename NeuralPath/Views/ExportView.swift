import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.timestamp) private var entries: [SymptomEntry]

    @State private var exportFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var fileURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Export Format")
                }

                Section {
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(entries.count)")
                            .foregroundStyle(.secondary)
                    }

                    if let oldest = entries.first?.timestamp {
                        HStack {
                            Text("Date Range")
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(oldest, style: .date)
                                Text("to")
                                Text(Date(), style: .date)
                            }
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("Data Summary")
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(entries.isEmpty)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = fileURL {
                    ShareSheet(items: [fileURL])
                }
            }
        }
    }

    private func exportData() {
        switch exportFormat {
        case .csv:
            exportCSV()
        case .json:
            exportJSON()
        }
    }

    private func exportCSV() {
        var csv = "Date,Time,Mood,Anxiety,Anhedonia,Sleep Hours,Sleep Quality,Notes,Medications\n"

        for entry in entries {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short

            let date = dateFormatter.string(from: entry.timestamp)
            let time = timeFormatter.string(from: entry.timestamp)
            let mood = entry.moodLevel?.displayName ?? ""
            let anxiety = entry.anxietyLevel?.displayName ?? ""
            let anhedonia = entry.anhedoniaLevel?.displayName ?? ""
            let sleepHours = entry.sleepHours.map { String(format: "%.1f", $0) } ?? ""
            let sleepQuality = entry.sleepQualityRating.map { String($0) } ?? ""
            let notes = entry.notes.replacingOccurrences(of: "\"", with: "\"\"")
            let medications = entry.medications?.map { "\($0.name) (\($0.dosage))" }.joined(separator: "; ") ?? ""

            csv += "\"\(date)\",\"\(time)\",\"\(mood)\",\"\(anxiety)\",\"\(anhedonia)\",\"\(sleepHours)\",\"\(sleepQuality)\",\"\(notes)\",\"\(medications)\"\n"
        }

        saveAndShare(data: csv, filename: "neuralpath_export.csv")
    }

    private func exportJSON() {
        let exportData = entries.map { entry in
            ExportEntry(
                timestamp: entry.timestamp,
                mood: entry.moodLevel?.displayName,
                anxiety: entry.anxietyLevel?.displayName,
                anhedonia: entry.anhedoniaLevel?.displayName,
                sleepHours: entry.sleepHours,
                sleepQuality: entry.sleepQualityRating,
                notes: entry.notes,
                medications: entry.medications?.map { med in
                    ExportMedication(
                        name: med.name,
                        dosage: med.dosage,
                        taken: med.taken
                    )
                }
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let jsonData = try? encoder.encode(exportData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            saveAndShare(data: jsonString, filename: "neuralpath_export.json")
        }
    }

    private func saveAndShare(data: String, filename: String) {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
            self.fileURL = fileURL
            showingShareSheet = true
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}

struct ExportEntry: Codable {
    let timestamp: Date
    let mood: String?
    let anxiety: String?
    let anhedonia: String?
    let sleepHours: Double?
    let sleepQuality: Int?
    let notes: String
    let medications: [ExportMedication]?
}

struct ExportMedication: Codable {
    let name: String
    let dosage: String
    let taken: Bool
}

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

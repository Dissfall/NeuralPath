//
//  ArchiveView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        SymptomDetailView(entry: entry)
                    } label: {
                        SymptomEntryRow(entry: entry)
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Your symptom entries will appear here")
                    )
                }
            }
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

#Preview {
    ArchiveView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

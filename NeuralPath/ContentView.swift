//
//  ContentView.swift
//  NeuralPath
//
//  Created by Goša Lukyanau on 16/11/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.timestamp, order: .reverse) private var entries: [SymptomEntry]
    @State private var showingAddEntry = false
    @State private var showingSettings = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            entriesView
                .tabItem {
                    Label("Entries", systemImage: "list.bullet")
                }
                .tag(0)

            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.xyaxis.line")
                }
                .tag(1)
        }
    }

    private var entriesView: some View {
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
            .navigationTitle("NeuralPath")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddSymptomView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Yet",
                        systemImage: "heart.text.square",
                        description: Text("Tap + to add your first symptom entry")
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

struct SymptomEntryRow: View {
    let entry: SymptomEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.timestamp, style: .date)
                    .font(.headline)
                Spacer()
                Text(entry.timestamp, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if let mood = entry.moodLevel {
                    Label(mood.emoji, systemImage: "face.smiling")
                        .labelStyle(.titleOnly)
                }
                if let anxiety = entry.anxietyLevel {
                    Label(anxiety.displayName, systemImage: "brain.head.profile")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
                if let anhedonia = entry.anhedoniaLevel {
                    Label("Anhedonia: \(anhedonia.displayName.prefix(4))", systemImage: "sparkles")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

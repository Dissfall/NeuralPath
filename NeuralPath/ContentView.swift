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
    @State private var showingLogMedication = false
    @State private var showingLogSubstance = false
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

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "brain")
                }
                .tag(2)
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
                    Menu {
                        Button {
                            showingLogMedication = true
                        } label: {
                            Label("Log Medication", systemImage: "pills")
                        }

                        Button {
                            showingLogSubstance = true
                        } label: {
                            Label("Log Substance", systemImage: "drop.triangle")
                        }

                        Divider()

                        Button {
                            showingAddEntry = true
                        } label: {
                            Label("Add Full Entry", systemImage: "plus.circle")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
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
            .sheet(isPresented: $showingLogMedication) {
                QuickLogMedicationView()
            }
            .sheet(isPresented: $showingLogSubstance) {
                QuickLogSubstanceView()
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

#Preview {
    ContentView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

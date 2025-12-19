//
//  ContentView.swift
//  NeuralPath
//
//  Created by Goša Lukyanau on 16/11/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)

            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.xyaxis.line")
                }
                .tag(1)

            ComprehensiveAnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "brain")
                }
                .tag(2)

            PracticeTabView()
                .tabItem {
                    Label("Practice", systemImage: "figure.mind.and.body")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}

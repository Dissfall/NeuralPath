//
//  PracticeCatalogView.swift
//  NeuralPath
//

import SwiftUI

struct PracticeCatalogView: View {
    let latestEntry: SymptomEntry?
    let onStartPractice: (GuidedPractice) -> Void

    @State private var selectedCategory: GuidedPracticeCategory?

    private var suggestedPractices: [GuidedPractice] {
        PracticeSuggestionEngine.suggestPractices(
            latestEntry: latestEntry,
            timeOfDay: Date()
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Suggestions section
                if !suggestedPractices.isEmpty {
                    suggestionsSection
                }

                // Category sections
                ForEach(GuidedPracticeCategory.allCases) { category in
                    categorySection(category)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Suggested for You")
                    .font(.headline)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestedPractices) { practice in
                        PracticeCard(
                            practice: practice,
                            style: .compact,
                            onTap: { onStartPractice(practice) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Category Section

    private func categorySection(_ category: GuidedPracticeCategory) -> some View {
        let practices = GuidedPracticeDatabase.practices(for: category)
        guard !practices.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // Category header
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.displayName)
                            .font(.headline)
                        Text(category.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                // Practice cards
                VStack(spacing: 8) {
                    ForEach(practices) { practice in
                        PracticeCard(
                            practice: practice,
                            style: .full,
                            onTap: { onStartPractice(practice) }
                        )
                        .padding(.horizontal)
                    }
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        PracticeCatalogView(
            latestEntry: nil,
            onStartPractice: { _ in }
        )
        .navigationTitle("Practice")
    }
}

//
//  PracticeCatalogView.swift
//  NeuralPath
//

import SwiftUI

struct PracticeCatalogView: View {
    let latestEntry: SymptomEntry?
    let onStartPractice: (GuidedPractice) -> Void

    @State private var selectedTags: Set<PracticeTag> = []

    private var suggestedPractices: [GuidedPractice] {
        PracticeSuggestionEngine.suggestPractices(
            latestEntry: latestEntry,
            timeOfDay: Date()
        )
    }

    private var isFiltering: Bool {
        !selectedTags.isEmpty
    }

    private var filteredPractices: [GuidedPractice] {
        GuidedPracticeDatabase.allPractices.filter { $0.hasAllTags(from: selectedTags) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Tag filter bar
                tagFilterBar

                if isFiltering {
                    // Show filtered results
                    filteredSection
                } else {
                    // Suggestions section
                    if !suggestedPractices.isEmpty {
                        suggestionsSection
                    }

                    // Category sections
                    ForEach(GuidedPracticeCategory.allCases) { category in
                        categorySection(category)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Tag Filter Bar

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PracticeTag.allCases) { tag in
                    tagFilterChip(tag)
                }
            }
            .padding(.horizontal)
        }
    }

    private func tagFilterChip(_ tag: PracticeTag) -> some View {
        let isSelected = selectedTags.contains(tag)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedTags.remove(tag)
                } else {
                    selectedTags.insert(tag)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tag.icon)
                Text(tag.displayName)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? .white : tag.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? tag.color : tag.color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtered Section

    private var filteredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Matching Practices")
                    .font(.headline)
                Text("(\(filteredPractices.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if filteredPractices.isEmpty {
                ContentUnavailableView(
                    "No Matches",
                    systemImage: "magnifyingglass",
                    description: Text("No practices match the selected tags")
                )
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredPractices) { practice in
                        PracticeCard(
                            practice: practice,
                            style: .full,
                            onTap: { onStartPractice(practice) }
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
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

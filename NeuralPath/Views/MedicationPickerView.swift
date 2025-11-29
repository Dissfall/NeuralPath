//
//  MedicationPickerView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI

struct MedicationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: MedicationCategory?

    let onSelect: (MedicationInfo) -> Void
    let onCustom: () -> Void

    private var filteredMedications: [MedicationInfo] {
        var results = MedicationDatabase.search(searchText)
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        return results.sorted { $0.name < $1.name }
    }

    private var antidepressantCategories: [MedicationCategory] {
        [.ssri, .snri, .tca, .tetracyclic, .maoi, .ndri, .nassa, .sari, .sms, .melatonergic, .atypicalAntidepressant]
    }

    private var otherCategories: [MedicationCategory] {
        MedicationCategory.allCases.filter { !antidepressantCategories.contains($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }

                            ForEach(antidepressantCategories, id: \.self) { category in
                                CategoryChip(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }

                            Divider()
                                .frame(height: 20)

                            ForEach(otherCategories, id: \.self) { category in
                                CategoryChip(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                Section {
                    Button {
                        onCustom()
                    } label: {
                        Label("Add Custom Medication", systemImage: "plus.circle")
                    }
                }

                Section {
                    if filteredMedications.isEmpty {
                        ContentUnavailableView {
                            Label("No Medications Found", systemImage: "pills")
                        } description: {
                            Text("Try a different search term or add a custom medication")
                        }
                    } else {
                        ForEach(filteredMedications) { med in
                            MedicationDatabaseRow(medication: med) {
                                onSelect(med)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Medications")
                        Spacer()
                        Text("\(filteredMedications.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by name or brand...")
            .navigationTitle("Select Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Medication Database Row

struct MedicationDatabaseRow: View {
    let medication: MedicationInfo
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: medication.category.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(.body)

                    if !medication.aliases.isEmpty {
                        Text(medication.aliases.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(medication.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MedicationPickerView(
        onSelect: { _ in },
        onCustom: { }
    )
}

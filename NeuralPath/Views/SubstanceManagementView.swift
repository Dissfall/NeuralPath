//
//  SubstanceManagementView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct SubstanceManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserSubstance> { $0.isActive }, sort: \UserSubstance.name) private var substances: [UserSubstance]

    @State private var showingAddSubstance = false

    var body: some View {
        List {
            if substances.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Substances",
                        systemImage: "drop.triangle",
                        description: Text("Add substances to track your consumption patterns")
                    )
                }
            } else {
                Section {
                    ForEach(substances) { substance in
                        NavigationLink {
                            AddUserSubstanceView(substance: substance)
                        } label: {
                            SubstanceRow(substance: substance)
                        }
                    }
                    .onDelete(perform: deleteSubstances)
                } header: {
                    Text("Active Substances")
                } footer: {
                    if substances.count == 1 {
                        Text("1 active substance")
                    } else {
                        Text("\(substances.count) active substances")
                    }
                }
            }
        }
        .navigationTitle("Manage Substances")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSubstance = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSubstance) {
            AddUserSubstanceView()
        }
    }

    private func deleteSubstances(at offsets: IndexSet) {
        for index in offsets {
            let substance = substances[index]
            substance.isActive = false
        }
    }
}

struct SubstanceRow: View {
    let substance: UserSubstance

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.triangle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(substance.name)
                    .font(.headline)

                if let unit = substance.defaultUnit {
                    Text("Default unit: \(unit.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SubstanceManagementView()
            .modelContainer(for: UserSubstance.self)
    }
}

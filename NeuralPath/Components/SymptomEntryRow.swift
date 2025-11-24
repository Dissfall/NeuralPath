//
//  SymptomEntryRow.swift
//  NeuralPath
//
//  Created by Goša Lukyanau on 19/11/2025.
//

import SwiftUI

struct SymptomEntryRow: View {
    let entry: SymptomEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.timestamp ?? Date(), style: .date)
                    .font(.headline)
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
                    Label(anhedonia.displayName, systemImage: "sparkles")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            if let substances = entry.substances, !substances.isEmpty {
                WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(substances) { substance in
                        Label(substance.name ?? "", systemImage: "drop.triangle")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let coffee = Substance(name: "Coffee", amount: 1, unit: .cups)
    let cigarettes = Substance(name: "Energy Drink", amount: 1, unit: .cups)
    let tea = Substance(name: "Herbal Tea", amount: 1, unit: .cups)

    let entry = SymptomEntry(anxietyLevel: .extreme, anhedoniaLevel: .extreme, substances: [coffee, cigarettes, tea])
    
    List {
        NavigationLink {
            SymptomDetailView(entry: entry)
        } label: {
            SymptomEntryRow(entry: entry)
        }
    }
}

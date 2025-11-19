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
                Text(entry.timestamp, style: .date)
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
                ForEach(entry.substances ?? []) { substance in
                    Label(substance.name, systemImage: "drop.triangle")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
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
    let coffee = Substance(name: "Coffee", amount: 1, unit: .cups)
    let cigarettes = Substance(name: "Cigarettes", amount: 1, unit: .cigarettes)
    
    let entry = SymptomEntry(anxietyLevel: .extreme, anhedoniaLevel: .extreme, substances: [coffee, cigarettes])
    
    SymptomEntryRow(entry: entry)
}

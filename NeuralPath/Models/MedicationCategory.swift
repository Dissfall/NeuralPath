//
//  MedicationCategory.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation

enum MedicationCategory: String, Codable, CaseIterable {
    case ssri = "SSRI"
    case snri = "SNRI"
    case benzodiazepine = "Benzodiazepine"
    case antipsychotic = "Antipsychotic"
    case moodStabilizer = "Mood Stabilizer"
    case stimulant = "Stimulant"
    case sleepAid = "Sleep Aid"
    case anticonvulsant = "Anticonvulsant"
    case other = "Other"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .ssri, .snri:
            return "brain.head.profile"
        case .benzodiazepine:
            return "wind"
        case .antipsychotic:
            return "brain"
        case .moodStabilizer:
            return "chart.line.uptrend.xyaxis"
        case .stimulant:
            return "bolt.fill"
        case .sleepAid:
            return "moon.fill"
        case .anticonvulsant:
            return "waveform.path.ecg"
        case .other:
            return "pills.fill"
        }
    }
}

//
//  MedicationFrequency.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation

enum MedicationFrequency: String, Codable, CaseIterable {
    case onceDaily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case threeTimesDaily = "Three Times Daily"
    case fourTimesDaily = "Four Times Daily"
    case weekly = "Weekly"
    case asNeeded = "As Needed"
    case everyOtherDay = "Every Other Day"

    var displayName: String {
        rawValue
    }

    var shortName: String {
        switch self {
        case .onceDaily:
            return "1x/day"
        case .twiceDaily:
            return "2x/day"
        case .threeTimesDaily:
            return "3x/day"
        case .fourTimesDaily:
            return "4x/day"
        case .weekly:
            return "Weekly"
        case .asNeeded:
            return "PRN"
        case .everyOtherDay:
            return "QOD"
        }
    }
}

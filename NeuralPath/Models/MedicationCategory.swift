//
//  MedicationCategory.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation

enum MedicationCategory: String, Codable, CaseIterable {
    // Antidepressants
    case ssri = "SSRI"
    case snri = "SNRI"
    case tca = "TCA"
    case tetracyclic = "Tetracyclic"
    case maoi = "MAOI"
    case ndri = "NDRI"
    case nassa = "NaSSA"
    case sari = "SARI"
    case sms = "SMS"
    case melatonergic = "Melatonergic"
    case atypicalAntidepressant = "Atypical Antidepressant"

    // Anxiolytics & Sedatives
    case benzodiazepine = "Benzodiazepine"
    case buspirone = "Buspirone"
    case sleepAid = "Sleep Aid"

    // Antipsychotics & Mood Stabilizers
    case antipsychotic = "Antipsychotic"
    case moodStabilizer = "Mood Stabilizer"
    case anticonvulsant = "Anticonvulsant"
    case lithium = "Lithium"

    // ADHD & Stimulants
    case stimulant = "Stimulant"
    case nonStimulantADHD = "Non-Stimulant ADHD"

    // Other Psychiatric
    case betaBlocker = "Beta Blocker"
    case antihistamine = "Antihistamine"

    // Pain & Physical
    case opioid = "Opioid"
    case nsaid = "NSAID"
    case muscleRelaxant = "Muscle Relaxant"

    // Hormones & Supplements
    case thyroid = "Thyroid"
    case hormone = "Hormone"
    case supplement = "Supplement"

    // General
    case cardiovascular = "Cardiovascular"
    case diabetes = "Diabetes"
    case other = "Other"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .ssri, .snri, .tca, .tetracyclic, .maoi, .ndri, .nassa, .sari, .sms, .melatonergic, .atypicalAntidepressant:
            return "brain.head.profile"
        case .benzodiazepine, .buspirone:
            return "wind"
        case .antipsychotic:
            return "brain"
        case .moodStabilizer, .lithium:
            return "chart.line.uptrend.xyaxis"
        case .stimulant, .nonStimulantADHD:
            return "bolt.fill"
        case .sleepAid:
            return "moon.fill"
        case .anticonvulsant:
            return "waveform.path.ecg"
        case .betaBlocker, .cardiovascular:
            return "heart.fill"
        case .antihistamine:
            return "aqi.medium"
        case .opioid, .nsaid, .muscleRelaxant:
            return "cross.case.fill"
        case .thyroid:
            return "waveform.path"
        case .hormone:
            return "figure.stand"
        case .supplement:
            return "leaf.fill"
        case .diabetes:
            return "drop.fill"
        case .other:
            return "pills.fill"
        }
    }
}

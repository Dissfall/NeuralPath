//
//  MindfulnessCategory.swift
//  NeuralPath
//

import Foundation

enum MindfulnessCategory: String, Codable, CaseIterable, Identifiable {
    case meditation
    case breathing
    case yoga
    case journaling
    case bodyScan
    case relaxation
    case walking
    case gratitude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meditation: return "Meditation"
        case .breathing: return "Breathing Exercises"
        case .yoga: return "Yoga"
        case .journaling: return "Journaling"
        case .bodyScan: return "Body Scan"
        case .relaxation: return "Progressive Relaxation"
        case .walking: return "Mindful Walking"
        case .gratitude: return "Gratitude Practice"
        }
    }

    var icon: String {
        switch self {
        case .meditation: return "brain.head.profile"
        case .breathing: return "wind"
        case .yoga: return "figure.yoga"
        case .journaling: return "pencil.and.scribble"
        case .bodyScan: return "figure.stand"
        case .relaxation: return "bed.double.fill"
        case .walking: return "figure.walk"
        case .gratitude: return "heart.fill"
        }
    }
}

//
//  MindfulnessCategory.swift
//  NeuralPath
//

import Foundation
import SwiftUI

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
        case .meditation: return String(localized: "Meditation")
        case .breathing: return String(localized: "Breathing Exercises")
        case .yoga: return String(localized: "Yoga")
        case .journaling: return String(localized: "Journaling")
        case .bodyScan: return String(localized: "Body Scan")
        case .relaxation: return String(localized: "Progressive Relaxation")
        case .walking: return String(localized: "Mindful Walking")
        case .gratitude: return String(localized: "Gratitude Practice")
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

    var color: Color {
        switch self {
        case .meditation: return .purple
        case .breathing: return .cyan
        case .yoga: return .orange
        case .journaling: return .blue
        case .bodyScan: return .teal
        case .relaxation: return .indigo
        case .walking: return .green
        case .gratitude: return .pink
        }
    }
}

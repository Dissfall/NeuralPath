//
//  SelfCareTimeOfDay.swift
//  NeuralPath
//

import SwiftUI

enum SelfCareTimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .indigo
        }
    }

    var defaultReminderHour: Int {
        switch self {
        case .morning: return 7
        case .afternoon: return 12
        case .evening: return 20
        }
    }

    var completionMessage: String {
        switch self {
        case .morning: return "You've completed your morning self-care. Great start to the day!"
        case .afternoon: return "You've completed your afternoon self-care. Keep it up!"
        case .evening: return "You've completed your evening self-care. Well done today!"
        }
    }
}

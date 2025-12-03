//
//  MedicationTimeOfDay.swift
//  NeuralPath
//

import SwiftUI

enum MedicationTimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening
    case night
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        case .custom: return "Custom Time"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        case .custom: return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .indigo
        case .night: return .purple
        case .custom: return .blue
        }
    }

    var defaultReminderHour: Int {
        switch self {
        case .morning: return 8
        case .afternoon: return 13
        case .evening: return 20
        case .night: return 22
        case .custom: return 8
        }
    }

    /// Cases that can be scheduled as grouped reminders (excludes custom)
    static var scheduledCases: [MedicationTimeOfDay] {
        [.morning, .afternoon, .evening, .night]
    }
}

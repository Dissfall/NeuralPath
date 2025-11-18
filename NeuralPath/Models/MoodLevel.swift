import Foundation
import HealthKit

enum MoodLevel: Int, Codable, CaseIterable {
    case veryLow = 1
    case low = 2
    case moderate = 3
    case good = 4
    case excellent = 5

    var displayName: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    var emoji: String {
        switch self {
        case .veryLow: return "😞"
        case .low: return "😕"
        case .moderate: return "😐"
        case .good: return "🙂"
        case .excellent: return "😊"
        }
    }

    @available(iOS 18.0, *)
    var stateOfMindValence: Double {
        switch self {
        case .veryLow: return -0.8
        case .low: return -0.4
        case .moderate: return 0.0
        case .good: return 0.5
        case .excellent: return 0.9
        }
    }

    @available(iOS 18.0, *)
    var stateOfMindLabels: [HKStateOfMind.Label] {
        switch self {
        case .veryLow: return [.sad, .worried]
        case .low: return [.sad, .anxious]
        case .moderate: return [.calm]
        case .good: return [.happy, .content]
        case .excellent: return [.happy, .joyful, .grateful]
        }
    }

    @available(iOS 18.0, *)
    static func from(valence: Double) -> MoodLevel {
        switch valence {
        case -1.0 ..< -0.6: return .veryLow
        case -0.6 ..< -0.2: return .low
        case -0.2 ..< 0.3: return .moderate
        case 0.3 ..< 0.7: return .good
        default: return .excellent
        }
    }
}

import Foundation

enum AnhedoniaLevel: Int, Codable, CaseIterable {
    case none = 0
    case mild = 1
    case moderate = 2
    case severe = 3
    case extreme = 4

    var displayName: String {
        switch self {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .extreme: return "Extreme"
        }
    }

    var description: String {
        switch self {
        case .none: return "Able to enjoy usual activities"
        case .mild: return "Activities feel less rewarding than usual"
        case .moderate: return "Struggling to find joy in most activities"
        case .severe: return "Very little pleasure from anything"
        case .extreme: return "No pleasure or interest in any activities"
        }
    }
}

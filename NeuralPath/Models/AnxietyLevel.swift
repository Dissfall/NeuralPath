import Foundation

enum AnxietyLevel: Int, Codable, CaseIterable {
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

    var color: String {
        switch self {
        case .none: return "green"
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .severe: return "red"
        case .extreme: return "purple"
        }
    }
}

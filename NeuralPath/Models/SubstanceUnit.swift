import Foundation

enum SubstanceUnit: Int, Codable, CaseIterable {
    case milliliters = 0
    case ounces = 1
    case milligrams = 2
    case grams = 3
    case cups = 4
    case drinks = 5
    case cigarettes = 6
    case other = 7

    var displayName: String {
        switch self {
        case .milliliters:
            return "Milliliters"
        case .ounces:
            return "Ounces"
        case .milligrams:
            return "Milligrams"
        case .grams:
            return "Grams"
        case .cups:
            return "Cups"
        case .drinks:
            return "Drinks"
        case .cigarettes:
            return "Cigarettes"
        case .other:
            return "Other"
        }
    }

    var abbreviation: String {
        switch self {
        case .milliliters:
            return "ml"
        case .ounces:
            return "oz"
        case .milligrams:
            return "mg"
        case .grams:
            return "g"
        case .cups:
            return "cups"
        case .drinks:
            return "drinks"
        case .cigarettes:
            return "cigs"
        case .other:
            return ""
        }
    }
}

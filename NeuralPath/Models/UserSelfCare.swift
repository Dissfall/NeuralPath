//
//  UserSelfCare.swift
//  NeuralPath
//

import Foundation
import SwiftData

@Model
final class UserSelfCare {
    var id: UUID?
    var name: String?
    var timeOfDayRaw: String?
    var notes: String?
    var isActive: Bool?
    var createdDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \SelfCareLog.userSelfCare)
    var logs: [SelfCareLog]?

    var timeOfDay: SelfCareTimeOfDay {
        get {
            SelfCareTimeOfDay(rawValue: timeOfDayRaw ?? "morning") ?? .morning
        }
        set {
            timeOfDayRaw = newValue.rawValue
        }
    }

    init(
        id: UUID? = UUID(),
        name: String? = "",
        timeOfDay: SelfCareTimeOfDay = .morning,
        notes: String? = "",
        isActive: Bool? = true,
        createdDate: Date? = Date()
    ) {
        self.id = id
        self.name = name
        self.timeOfDayRaw = timeOfDay.rawValue
        self.notes = notes
        self.isActive = isActive
        self.createdDate = createdDate
    }
}

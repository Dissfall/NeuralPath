//
//  SelfCareLog.swift
//  NeuralPath
//

import Foundation
import SwiftData

@Model
final class SelfCareLog {
    var id: UUID?
    var userSelfCare: UserSelfCare?
    var practiceName: String?
    var timeOfDayRaw: String?
    var timestamp: Date?
    var notes: String?

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
        userSelfCare: UserSelfCare? = nil,
        practiceName: String? = "",
        timeOfDay: SelfCareTimeOfDay = .morning,
        timestamp: Date? = Date(),
        notes: String? = ""
    ) {
        self.id = id
        self.userSelfCare = userSelfCare
        self.practiceName = practiceName
        self.timeOfDayRaw = timeOfDay.rawValue
        self.timestamp = timestamp
        self.notes = notes
    }
}

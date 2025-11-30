//
//  UserMindfulness.swift
//  NeuralPath
//

import Foundation
import SwiftData

@Model
final class UserMindfulness {
    var id: UUID?
    var name: String?
    var category: MindfulnessCategory?
    var durationMinutes: Int?
    var notes: String?
    var isActive: Bool?
    var createdDate: Date?
    var reminderTime: Date?
    var reminderEnabled: Bool?

    @Relationship(deleteRule: .cascade, inverse: \MindfulnessLog.userMindfulness)
    var logs: [MindfulnessLog]?

    init(
        id: UUID? = UUID(),
        name: String? = "",
        category: MindfulnessCategory? = nil,
        durationMinutes: Int? = nil,
        notes: String? = "",
        isActive: Bool? = true,
        createdDate: Date? = Date(),
        reminderTime: Date? = nil,
        reminderEnabled: Bool? = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isActive = isActive
        self.createdDate = createdDate
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
    }
}

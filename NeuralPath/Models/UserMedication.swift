//
//  UserMedication.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class UserMedication {
    var id: UUID?
    var name: String?
    var dosage: String?
    var category: MedicationCategory?
    var frequency: MedicationFrequency?
    var notes: String?
    var isActive: Bool?
    var createdDate: Date?
    var startDate: Date?
    var endDate: Date?
    var reminderTime: Date?
    var reminderEnabled: Bool?

    @Relationship(deleteRule: .cascade, inverse: \MedicationLog.userMedication)
    var logs: [MedicationLog]?

    init(
        id: UUID? = UUID(),
        name: String? = "",
        dosage: String? = "",
        category: MedicationCategory? = nil,
        frequency: MedicationFrequency? = MedicationFrequency.onceDaily,
        notes: String? = "",
        isActive: Bool? = true,
        createdDate: Date? = Date(),
        startDate: Date? = nil,
        endDate: Date? = nil,
        reminderTime: Date? = nil,
        reminderEnabled: Bool? = false
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.category = category
        self.frequency = frequency
        self.notes = notes
        self.isActive = isActive
        self.createdDate = createdDate
        self.startDate = startDate
        self.endDate = endDate
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
    }
}

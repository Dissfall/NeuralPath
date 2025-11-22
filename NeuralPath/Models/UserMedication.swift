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
    var id: UUID = UUID()
    var name: String = ""
    var dosage: String = ""
    var category: MedicationCategory?
    var frequency: MedicationFrequency = MedicationFrequency.onceDaily
    var notes: String = ""
    var isActive: Bool = true
    var createdDate: Date = Date()
    var startDate: Date?
    var endDate: Date?

    @Relationship(deleteRule: .cascade)
    var logs: [MedicationLog]?

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String = "",
        category: MedicationCategory? = nil,
        frequency: MedicationFrequency = MedicationFrequency.onceDaily,
        notes: String = "",
        isActive: Bool = true,
        createdDate: Date = Date(),
        startDate: Date? = nil,
        endDate: Date? = nil
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
    }
}

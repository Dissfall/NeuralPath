//
//  MedicationLog.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class MedicationLog {
    var id: UUID = UUID()

    @Relationship(inverse: \UserMedication.logs)
    var userMedication: UserMedication?

    var medicationName: String = ""
    var timestamp: Date = Date()
    var notes: String = ""

    init(
        id: UUID = UUID(),
        userMedication: UserMedication? = nil,
        medicationName: String = "",
        timestamp: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.userMedication = userMedication
        self.medicationName = medicationName
        self.timestamp = timestamp
        self.notes = notes
    }
}

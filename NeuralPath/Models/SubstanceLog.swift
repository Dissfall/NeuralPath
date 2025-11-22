//
//  SubstanceLog.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class SubstanceLog {
    var id: UUID = UUID()

    @Relationship(inverse: \UserSubstance.logs)
    var userSubstance: UserSubstance?

    var substanceName: String = ""
    var amount: Double = 0.0
    var unit: SubstanceUnit = SubstanceUnit.other
    var timestamp: Date = Date()
    var notes: String = ""

    init(
        id: UUID = UUID(),
        userSubstance: UserSubstance? = nil,
        substanceName: String = "",
        amount: Double = 0.0,
        unit: SubstanceUnit = SubstanceUnit.other,
        timestamp: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.userSubstance = userSubstance
        self.substanceName = substanceName
        self.amount = amount
        self.unit = unit
        self.timestamp = timestamp
        self.notes = notes
    }
}

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
    var id: UUID
    var userSubstance: UserSubstance?
    var substanceName: String
    var amount: Double
    var unit: SubstanceUnit
    var timestamp: Date
    var notes: String

    init(
        id: UUID = UUID(),
        userSubstance: UserSubstance? = nil,
        substanceName: String,
        amount: Double,
        unit: SubstanceUnit,
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

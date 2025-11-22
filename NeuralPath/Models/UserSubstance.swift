//
//  UserSubstance.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class UserSubstance {
    var id: UUID = UUID()
    var name: String = ""
    var defaultUnit: SubstanceUnit?
    var notes: String = ""
    var isActive: Bool = true
    var createdDate: Date = Date()

    @Relationship(deleteRule: .cascade)
    var logs: [SubstanceLog]?

    init(
        id: UUID = UUID(),
        name: String,
        defaultUnit: SubstanceUnit? = nil,
        notes: String = "",
        isActive: Bool = true,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.defaultUnit = defaultUnit
        self.notes = notes
        self.isActive = isActive
        self.createdDate = createdDate
    }
}

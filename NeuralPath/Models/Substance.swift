import Foundation
import SwiftData

@Model
final class Substance {
    var id: UUID = UUID()
    var name: String = ""
    var amount: Double = 0.0
    var unit: SubstanceUnit = SubstanceUnit.other
    var timestamp: Date = Date()
    var notes: String = ""

    var symptomEntry: SymptomEntry?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        unit: SubstanceUnit,
        timestamp: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.timestamp = timestamp
        self.notes = notes
    }
}

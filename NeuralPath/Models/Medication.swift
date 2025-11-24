import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID?
    var name: String?
    var dosage: String?
    var timestamp: Date?
    var taken: Bool?
    var notes: String?

    var symptomEntry: SymptomEntry?

    init(
        id: UUID? = UUID(),
        name: String? = "",
        dosage: String? = "",
        timestamp: Date? = Date(),
        taken: Bool? = false,
        notes: String? = ""
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.timestamp = timestamp
        self.taken = taken
        self.notes = notes
    }
}

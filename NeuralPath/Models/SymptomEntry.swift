import Foundation
import SwiftData

@Model
final class SymptomEntry {
    var id: UUID
    var timestamp: Date
    var moodLevel: MoodLevel?
    var anxietyLevel: AnxietyLevel?
    var anhedoniaLevel: AnhedoniaLevel?
    var sleepQualityRating: Int?
    var sleepHours: Double?
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \Medication.symptomEntry)
    var medications: [Medication]?

    @Relationship(deleteRule: .cascade, inverse: \Substance.symptomEntry)
    var substances: [Substance]?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        moodLevel: MoodLevel? = nil,
        anxietyLevel: AnxietyLevel? = nil,
        anhedoniaLevel: AnhedoniaLevel? = nil,
        sleepQualityRating: Int? = nil,
        sleepHours: Double? = nil,
        notes: String = "",
        medications: [Medication]? = nil,
        substances: [Substance]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.moodLevel = moodLevel
        self.anxietyLevel = anxietyLevel
        self.anhedoniaLevel = anhedoniaLevel
        self.sleepQualityRating = sleepQualityRating
        self.sleepHours = sleepHours
        self.notes = notes
        self.medications = medications
        self.substances = substances
    }
}

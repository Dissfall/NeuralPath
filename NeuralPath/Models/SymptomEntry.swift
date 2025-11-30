import Foundation
import SwiftData

@Model
final class SymptomEntry {
    var id: UUID?
    var timestamp: Date?
    var moodLevel: MoodLevel?
    var anxietyLevel: AnxietyLevel?
    var anhedoniaLevel: AnhedoniaLevel?
    var sleepQualityRating: Int?
    var sleepHours: Double?
    var timeInDaylightMinutes: Double?
    var exerciseMinutes: Double?
    var notes: String?
    var selectedEmotions: [String]?

    @Relationship(deleteRule: .cascade, inverse: \Medication.symptomEntry)
    var medications: [Medication]?

    @Relationship(deleteRule: .cascade, inverse: \Substance.symptomEntry)
    var substances: [Substance]?

    init(
        id: UUID? = UUID(),
        timestamp: Date? = Date(),
        moodLevel: MoodLevel? = nil,
        anxietyLevel: AnxietyLevel? = nil,
        anhedoniaLevel: AnhedoniaLevel? = nil,
        sleepQualityRating: Int? = nil,
        sleepHours: Double? = nil,
        timeInDaylightMinutes: Double? = nil,
        exerciseMinutes: Double? = nil,
        notes: String? = "",
        medications: [Medication]? = nil,
        substances: [Substance]? = nil,
        selectedEmotions: [String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.moodLevel = moodLevel
        self.anxietyLevel = anxietyLevel
        self.anhedoniaLevel = anhedoniaLevel
        self.sleepQualityRating = sleepQualityRating
        self.sleepHours = sleepHours
        self.timeInDaylightMinutes = timeInDaylightMinutes
        self.exerciseMinutes = exerciseMinutes
        self.notes = notes
        self.medications = medications
        self.substances = substances
        self.selectedEmotions = selectedEmotions
    }

    var emotions: [Emotion] {
        get {
            selectedEmotions?.compactMap { Emotion(rawValue: $0) } ?? []
        }
        set {
            selectedEmotions = newValue.map { $0.rawValue }
        }
    }
}

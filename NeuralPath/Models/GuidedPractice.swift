//
//  GuidedPractice.swift
//  NeuralPath
//

import Foundation
import SwiftUI

// MARK: - Practice Category

enum GuidedPracticeCategory: String, CaseIterable, Identifiable {
    case breathing
    case grounding
    case emotional
    case micro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breathing: return "Breathing"
        case .grounding: return "Grounding"
        case .emotional: return "Emotional"
        case .micro: return "Quick Reset"
        }
    }

    var icon: String {
        switch self {
        case .breathing: return "wind"
        case .grounding: return "hand.point.down.fill"
        case .emotional: return "heart.fill"
        case .micro: return "sparkle"
        }
    }

    var color: Color {
        switch self {
        case .breathing: return .cyan
        case .grounding: return .teal
        case .emotional: return .pink
        case .micro: return .purple
        }
    }

    var description: String {
        switch self {
        case .breathing: return "Calm your nervous system"
        case .grounding: return "Return to the present moment"
        case .emotional: return "Process and regulate emotions"
        case .micro: return "Under 1 minute practices"
        }
    }
}

// MARK: - Animation Types

enum PracticeAnimation: String {
    case breatheIn
    case breatheOut
    case hold
    case count
    case notice
    case relax
    case bodyRegion
    case sensory
    case none
}

// MARK: - Haptic Styles

enum PracticeHaptic {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case none

    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .soft: return .soft
        case .rigid: return .rigid
        case .none: return nil
        }
    }
}

// MARK: - Body Region (for body scan)

enum BodyRegion: String, CaseIterable {
    case feet
    case legs
    case hips
    case torso
    case arms
    case head

    var displayName: String {
        switch self {
        case .feet: return "Feet"
        case .legs: return "Legs"
        case .hips: return "Hips & Lower Back"
        case .torso: return "Chest & Stomach"
        case .arms: return "Arms & Hands"
        case .head: return "Neck & Head"
        }
    }
}

// MARK: - Sensory Type (for 5-4-3-2-1)

enum SensoryType: String, CaseIterable {
    case see
    case feel
    case hear
    case smell
    case taste

    var icon: String {
        switch self {
        case .see: return "eye"
        case .feel: return "hand.raised"
        case .hear: return "ear"
        case .smell: return "nose"
        case .taste: return "mouth"
        }
    }

    var count: Int {
        switch self {
        case .see: return 5
        case .feel: return 4
        case .hear: return 3
        case .smell: return 2
        case .taste: return 1
        }
    }

    var instruction: String {
        switch self {
        case .see: return "Notice 5 things you can see"
        case .feel: return "Notice 4 things you can feel"
        case .hear: return "Notice 3 things you can hear"
        case .smell: return "Notice 2 things you can smell"
        case .taste: return "Notice 1 thing you can taste"
        }
    }
}

// MARK: - Practice Step

struct PracticeStep: Identifiable {
    let id: UUID
    let instruction: String
    let durationSeconds: Int?
    let animationType: PracticeAnimation
    let hapticStyle: PracticeHaptic
    let bodyRegion: BodyRegion?
    let sensoryType: SensoryType?

    init(
        id: UUID = UUID(),
        instruction: String,
        durationSeconds: Int? = nil,
        animationType: PracticeAnimation = .none,
        hapticStyle: PracticeHaptic = .none,
        bodyRegion: BodyRegion? = nil,
        sensoryType: SensoryType? = nil
    ) {
        self.id = id
        self.instruction = instruction
        self.durationSeconds = durationSeconds
        self.animationType = animationType
        self.hapticStyle = hapticStyle
        self.bodyRegion = bodyRegion
        self.sensoryType = sensoryType
    }
}

// MARK: - Practice Tag

enum PracticeTag: String, CaseIterable, Identifiable, Hashable {
    case anxietyRelief
    case moodBoost
    case morning
    case evening
    case quick

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anxietyRelief: return "Anxiety Relief"
        case .moodBoost: return "Mood Boost"
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .quick: return "Quick"
        }
    }

    var icon: String {
        switch self {
        case .anxietyRelief: return "brain.head.profile"
        case .moodBoost: return "sun.max"
        case .morning: return "sunrise"
        case .evening: return "moon.stars"
        case .quick: return "bolt"
        }
    }

    var color: Color {
        switch self {
        case .anxietyRelief: return .orange
        case .moodBoost: return .yellow
        case .morning: return .orange
        case .evening: return .indigo
        case .quick: return .purple
        }
    }
}

// MARK: - Suggestion Context

struct SuggestionContext {
    let forAnxiety: Bool
    let forLowMood: Bool
    let forMorning: Bool
    let forEvening: Bool
    let forQuickBreak: Bool

    init(
        forAnxiety: Bool = false,
        forLowMood: Bool = false,
        forMorning: Bool = false,
        forEvening: Bool = false,
        forQuickBreak: Bool = false
    ) {
        self.forAnxiety = forAnxiety
        self.forLowMood = forLowMood
        self.forMorning = forMorning
        self.forEvening = forEvening
        self.forQuickBreak = forQuickBreak
    }

    var tags: [PracticeTag] {
        var result: [PracticeTag] = []
        if forAnxiety { result.append(.anxietyRelief) }
        if forLowMood { result.append(.moodBoost) }
        if forMorning { result.append(.morning) }
        if forEvening { result.append(.evening) }
        if forQuickBreak { result.append(.quick) }
        return result
    }
}

// MARK: - Guided Practice

struct GuidedPractice: Identifiable {
    let id: String
    let name: String
    let category: GuidedPracticeCategory
    let mindfulnessCategory: MindfulnessCategory
    let description: String
    let benefit: String
    let totalDurationSeconds: Int
    let steps: [PracticeStep]
    let suggestedFor: SuggestionContext

    var formattedDuration: String {
        if totalDurationSeconds < 60 {
            return "\(totalDurationSeconds)s"
        } else {
            let minutes = totalDurationSeconds / 60
            let seconds = totalDurationSeconds % 60
            if seconds == 0 {
                return "\(minutes) min"
            } else {
                return "\(minutes)m \(seconds)s"
            }
        }
    }

    var timedStepsCount: Int {
        steps.filter { $0.durationSeconds != nil }.count
    }

    var tags: [PracticeTag] {
        suggestedFor.tags
    }

    func hasTag(_ tag: PracticeTag) -> Bool {
        tags.contains(tag)
    }

    func hasAllTags(from selectedTags: Set<PracticeTag>) -> Bool {
        selectedTags.isSubset(of: Set(tags))
    }
}

// MARK: - Guided Practice Log Metadata

struct GuidedPracticeLogMetadata: Codable {
    let guided: Bool
    let practiceId: String
    let completed: Bool
    let stepsCompleted: Int?
    let totalSteps: Int?

    init(practiceId: String, completed: Bool, stepsCompleted: Int? = nil, totalSteps: Int? = nil) {
        self.guided = true
        self.practiceId = practiceId
        self.completed = completed
        self.stepsCompleted = stepsCompleted
        self.totalSteps = totalSteps
    }

    func toJSON() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func from(json: String) -> GuidedPracticeLogMetadata? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GuidedPracticeLogMetadata.self, from: data)
    }
}

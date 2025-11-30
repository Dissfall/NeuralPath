//
//  Emotion.swift
//  NeuralPath
//

import SwiftUI

enum EmotionValence: String, Codable, CaseIterable {
    case positive
    case negative
    case neutral

    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .orange
        case .neutral: return .gray
        }
    }
}

enum Emotion: String, Codable, CaseIterable, Identifiable {
    // Positive
    case happy
    case grateful
    case calm
    case hopeful
    case confident
    case energetic
    case content
    case excited
    case peaceful
    case proud

    // Negative
    case sad
    case anxious
    case angry
    case frustrated
    case overwhelmed
    case lonely
    case irritable
    case hopeless
    case guilty
    case ashamed

    // Neutral
    case tired
    case restless
    case numb
    case confused
    case distracted
    case bored
    case indifferent
    case reflective

    var id: String { rawValue }

    var valence: EmotionValence {
        switch self {
        case .happy, .grateful, .calm, .hopeful, .confident, .energetic, .content, .excited, .peaceful, .proud:
            return .positive
        case .sad, .anxious, .angry, .frustrated, .overwhelmed, .lonely, .irritable, .hopeless, .guilty, .ashamed:
            return .negative
        case .tired, .restless, .numb, .confused, .distracted, .bored, .indifferent, .reflective:
            return .neutral
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        valence.color
    }

    static var positiveEmotions: [Emotion] {
        allCases.filter { $0.valence == .positive }
    }

    static var negativeEmotions: [Emotion] {
        allCases.filter { $0.valence == .negative }
    }

    static var neutralEmotions: [Emotion] {
        allCases.filter { $0.valence == .neutral }
    }
}

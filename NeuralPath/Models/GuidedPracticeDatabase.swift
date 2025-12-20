//
//  GuidedPracticeDatabase.swift
//  NeuralPath
//

import Foundation

enum GuidedPracticeDatabase {

    // MARK: - All Practices

    static let allPractices: [GuidedPractice] = [
        // Breathing
        boxBreathing,
        physiologicalSigh,
        fourSevenEightBreathing,
        // Grounding
        fiveFourThreeTwoOne,
        bodyCheckIn,
        // Emotional
        selfCompassionBreak,
        rainPractice,
        // Micro
        oneMindfulBreath,
        noticingPractice,
        gentleMovement
    ]

    // MARK: - Query Methods

    static func practices(for category: GuidedPracticeCategory) -> [GuidedPractice] {
        allPractices.filter { $0.category == category }
    }

    static func practice(byId id: String) -> GuidedPractice? {
        allPractices.first { $0.id == id }
    }

    static func quickPractices(maxDuration: Int = 120) -> [GuidedPractice] {
        allPractices.filter { $0.totalDurationSeconds <= maxDuration }
    }

    // MARK: - Breathing Practices

    static let boxBreathing = GuidedPractice(
        id: "box_breathing",
        name: String(localized: "Box Breathing"),
        category: .breathing,
        mindfulnessCategory: .breathing,
        description: String(localized: "A calming technique using equal-length inhales, holds, exhales, and holds. Used by Navy SEALs to stay calm under pressure."),
        benefit: String(localized: "Activates the parasympathetic nervous system to reduce stress and anxiety"),
        totalDurationSeconds: 180,
        steps: boxBreathingSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: false,
            forMorning: true,
            forEvening: true,
            forQuickBreak: true
        )
    )

    static let physiologicalSigh = GuidedPractice(
        id: "physiological_sigh",
        name: String(localized: "Physiological Sigh"),
        category: .breathing,
        mindfulnessCategory: .breathing,
        description: String(localized: "A science-backed technique: two quick inhales through the nose, then a long exhale through the mouth. The fastest known way to calm your nervous system."),
        benefit: String(localized: "Rapidly reduces stress in under a minute"),
        totalDurationSeconds: 60,
        steps: physiologicalSighSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: false,
            forMorning: false,
            forEvening: false,
            forQuickBreak: true
        )
    )

    static let fourSevenEightBreathing = GuidedPractice(
        id: "four_seven_eight",
        name: String(localized: "4-7-8 Breathing"),
        category: .breathing,
        mindfulnessCategory: .breathing,
        description: String(localized: "Developed by Dr. Andrew Weil, this asymmetric breathing pattern promotes deep relaxation and can help with falling asleep."),
        benefit: String(localized: "Promotes deep relaxation and better sleep"),
        totalDurationSeconds: 120,
        steps: fourSevenEightSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: false,
            forMorning: false,
            forEvening: true,
            forQuickBreak: false
        )
    )

    // MARK: - Grounding Practices

    static let fiveFourThreeTwoOne = GuidedPractice(
        id: "five_four_three_two_one",
        name: String(localized: "5-4-3-2-1 Grounding"),
        category: .grounding,
        mindfulnessCategory: .bodyScan,
        description: String(localized: "A sensory awareness exercise that helps bring you back to the present moment by engaging all five senses."),
        benefit: String(localized: "Interrupts anxious thoughts and grounds you in the present"),
        totalDurationSeconds: 180,
        steps: fiveFourThreeTwoOneSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: false,
            forMorning: false,
            forEvening: false,
            forQuickBreak: false
        )
    )

    static let bodyCheckIn = GuidedPractice(
        id: "body_check_in",
        name: String(localized: "Body Check-In"),
        category: .grounding,
        mindfulnessCategory: .bodyScan,
        description: String(localized: "A simplified body scan where you notice sensations in different body regions without trying to change anything."),
        benefit: String(localized: "Increases body awareness and releases held tension"),
        totalDurationSeconds: 180,
        steps: bodyCheckInSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: true,
            forMorning: true,
            forEvening: true,
            forQuickBreak: false
        )
    )

    // MARK: - Emotional Practices

    static let selfCompassionBreak = GuidedPractice(
        id: "self_compassion_break",
        name: String(localized: "Self-Compassion Break"),
        category: .emotional,
        mindfulnessCategory: .meditation,
        description: String(localized: "Based on Kristin Neff's research, this practice helps you respond to difficulty with kindness rather than self-criticism."),
        benefit: String(localized: "Reduces self-criticism and builds emotional resilience"),
        totalDurationSeconds: 300,
        steps: selfCompassionBreakSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: false,
            forLowMood: true,
            forMorning: false,
            forEvening: true,
            forQuickBreak: false
        )
    )

    static let rainPractice = GuidedPractice(
        id: "rain_practice",
        name: String(localized: "RAIN Practice"),
        category: .emotional,
        mindfulnessCategory: .meditation,
        description: String(localized: "A four-step process for working with difficult emotions: Recognize, Allow, Investigate, and Nurture."),
        benefit: String(localized: "Transforms your relationship with difficult emotions"),
        totalDurationSeconds: 300,
        steps: rainPracticeSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: true,
            forMorning: false,
            forEvening: true,
            forQuickBreak: false
        )
    )

    // MARK: - Micro Practices

    static let oneMindfulBreath = GuidedPractice(
        id: "one_mindful_breath",
        name: String(localized: "One Mindful Breath"),
        category: .micro,
        mindfulnessCategory: .breathing,
        description: String(localized: "For moments when even 2 minutes feels like too much. Just one single, fully present breath."),
        benefit: String(localized: "A tiny reset that takes almost no time"),
        totalDurationSeconds: 30,
        steps: oneMindfulBreathSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: true,
            forMorning: true,
            forEvening: true,
            forQuickBreak: true
        )
    )

    static let noticingPractice = GuidedPractice(
        id: "noticing_practice",
        name: String(localized: "Noticing Practice"),
        category: .micro,
        mindfulnessCategory: .gratitude,
        description: String(localized: "A simple prompt to pause and appreciate something small in your current moment."),
        benefit: String(localized: "Shifts attention toward the positive"),
        totalDurationSeconds: 45,
        steps: noticingPracticeSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: false,
            forLowMood: true,
            forMorning: true,
            forEvening: false,
            forQuickBreak: true
        )
    )

    static let gentleMovement = GuidedPractice(
        id: "gentle_movement",
        name: String(localized: "Gentle Movement"),
        category: .micro,
        mindfulnessCategory: .yoga,
        description: String(localized: "Simple shoulder rolls to release physical tension. Perfect when you've been sitting too long."),
        benefit: String(localized: "Releases physical tension quickly"),
        totalDurationSeconds: 45,
        steps: gentleMovementSteps(),
        suggestedFor: SuggestionContext(
            forAnxiety: true,
            forLowMood: false,
            forMorning: true,
            forEvening: false,
            forQuickBreak: true
        )
    )

    // MARK: - Step Generators

    private static func boxBreathingSteps() -> [PracticeStep] {
        var steps: [PracticeStep] = []

        // Intro
        steps.append(PracticeStep(
            instruction: String(localized: "Find a comfortable position. We'll breathe in a box pattern: in, hold, out, hold."),
            durationSeconds: 5,
            animationType: .none,
            hapticStyle: .soft
        ))

        // 4 cycles of box breathing
        for cycle in 1...4 {
            steps.append(PracticeStep(
                instruction: String(localized: "Breathe in slowly..."),
                durationSeconds: 4,
                animationType: .breatheIn,
                hapticStyle: .light
            ))
            steps.append(PracticeStep(
                instruction: String(localized: "Hold..."),
                durationSeconds: 4,
                animationType: .hold,
                hapticStyle: .none
            ))
            steps.append(PracticeStep(
                instruction: String(localized: "Breathe out slowly..."),
                durationSeconds: 4,
                animationType: .breatheOut,
                hapticStyle: .light
            ))
            steps.append(PracticeStep(
                instruction: cycle < 4 ? String(localized: "Hold...") : String(localized: "Hold... Last cycle."),
                durationSeconds: 4,
                animationType: .hold,
                hapticStyle: .none
            ))
        }

        // Outro
        steps.append(PracticeStep(
            instruction: String(localized: "Return to natural breathing. Notice how you feel."),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .medium
        ))

        return steps
    }

    private static func physiologicalSighSteps() -> [PracticeStep] {
        var steps: [PracticeStep] = []

        steps.append(PracticeStep(
            instruction: String(localized: "We'll do 3 physiological sighs. This is the fastest way to calm your nervous system."),
            durationSeconds: 5,
            animationType: .none,
            hapticStyle: .soft
        ))

        for sigh in 1...3 {
            steps.append(PracticeStep(
                instruction: String(localized: "Quick inhale through nose..."),
                durationSeconds: 1,
                animationType: .breatheIn,
                hapticStyle: .light
            ))
            steps.append(PracticeStep(
                instruction: String(localized: "Second quick inhale..."),
                durationSeconds: 1,
                animationType: .breatheIn,
                hapticStyle: .light
            ))
            steps.append(PracticeStep(
                instruction: String(localized: "Long exhale through mouth..."),
                durationSeconds: 6,
                animationType: .breatheOut,
                hapticStyle: .medium
            ))

            if sigh < 3 {
                steps.append(PracticeStep(
                    instruction: String(localized: "Pause..."),
                    durationSeconds: 3,
                    animationType: .hold,
                    hapticStyle: .none
                ))
            }
        }

        steps.append(PracticeStep(
            instruction: String(localized: "Notice the calm spreading through your body."),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .soft
        ))

        return steps
    }

    private static func fourSevenEightSteps() -> [PracticeStep] {
        var steps: [PracticeStep] = []

        steps.append(PracticeStep(
            instruction: String(localized: "Place the tip of your tongue behind your upper front teeth. We'll breathe in a 4-7-8 pattern."),
            durationSeconds: 6,
            animationType: .none,
            hapticStyle: .soft
        ))

        // 3 cycles
        for cycle in 1...3 {
            steps.append(PracticeStep(
                instruction: String(localized: "Breathe in quietly through your nose..."),
                durationSeconds: 4,
                animationType: .breatheIn,
                hapticStyle: .light
            ))
            steps.append(PracticeStep(
                instruction: String(localized: "Hold your breath..."),
                durationSeconds: 7,
                animationType: .hold,
                hapticStyle: .none
            ))
            steps.append(PracticeStep(
                instruction: String(localized: "Exhale completely through your mouth..."),
                durationSeconds: 8,
                animationType: .breatheOut,
                hapticStyle: .medium
            ))

            if cycle < 3 {
                steps.append(PracticeStep(
                    instruction: String(localized: "Pause before the next cycle..."),
                    durationSeconds: 2,
                    animationType: .none,
                    hapticStyle: .none
                ))
            }
        }

        steps.append(PracticeStep(
            instruction: String(localized: "Let your breathing return to normal. Feel the deep relaxation."),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .soft
        ))

        return steps
    }

    private static func fiveFourThreeTwoOneSteps() -> [PracticeStep] {
        var steps: [PracticeStep] = []

        steps.append(PracticeStep(
            instruction: String(localized: "Let's ground ourselves using your five senses. Take a moment to look around."),
            durationSeconds: 5,
            animationType: .none,
            hapticStyle: .soft
        ))

        for sense in SensoryType.allCases {
            steps.append(PracticeStep(
                instruction: sense.instruction,
                durationSeconds: nil,
                animationType: .sensory,
                hapticStyle: .light,
                sensoryType: sense
            ))
        }

        steps.append(PracticeStep(
            instruction: String(localized: "Take a deep breath. You are here, in this moment."),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .medium
        ))

        return steps
    }

    private static func bodyCheckInSteps() -> [PracticeStep] {
        var steps: [PracticeStep] = []

        steps.append(PracticeStep(
            instruction: String(localized: "Get comfortable. We'll briefly check in with different parts of your body."),
            durationSeconds: 5,
            animationType: .none,
            hapticStyle: .soft
        ))

        for region in BodyRegion.allCases {
            steps.append(PracticeStep(
                instruction: String(localized: "Bring attention to your \(region.displayName.lowercased()). Notice any sensations without trying to change anything."),
                durationSeconds: 20,
                animationType: .bodyRegion,
                hapticStyle: .light,
                bodyRegion: region
            ))
        }

        steps.append(PracticeStep(
            instruction: String(localized: "Now sense your body as a whole. Thank yourself for taking this time."),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .medium
        ))

        return steps
    }

    private static func selfCompassionBreakSteps() -> [PracticeStep] {
        var steps: [PracticeStep] = []

        steps.append(PracticeStep(
            instruction: String(localized: "Think of a situation that's causing you stress. Hold it gently in your awareness."),
            durationSeconds: 10,
            animationType: .none,
            hapticStyle: .soft
        ))

        // Step 1: Mindfulness
        steps.append(PracticeStep(
            instruction: String(localized: "Say to yourself: \"This is a moment of difficulty.\""),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .light
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "Acknowledge what you're feeling without judgment. This is real, and it's hard."),
            durationSeconds: 15,
            animationType: .notice,
            hapticStyle: .none
        ))

        // Step 2: Common Humanity
        steps.append(PracticeStep(
            instruction: String(localized: "Say to yourself: \"Difficulty is part of being human.\""),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .light
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "You're not alone in this. Everyone struggles. This is part of our shared human experience."),
            durationSeconds: 15,
            animationType: .notice,
            hapticStyle: .none
        ))

        // Step 3: Self-Kindness
        steps.append(PracticeStep(
            instruction: String(localized: "Say to yourself: \"May I be kind to myself.\""),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .light
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "What would you say to a good friend in this situation? Can you offer yourself the same kindness?"),
            durationSeconds: nil,
            animationType: .notice,
            hapticStyle: .none
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "Place your hand on your heart if it feels right. Feel the warmth of your own compassion."),
            durationSeconds: 20,
            animationType: .relax,
            hapticStyle: .soft
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "When you're ready, take a deep breath and return to your day."),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .medium
        ))

        return steps
    }

    private static func rainPracticeSteps() -> [PracticeStep] {
        var steps: [PracticeStep] = []

        steps.append(PracticeStep(
            instruction: String(localized: "RAIN is a four-step practice for working with difficult emotions. Let's begin."),
            durationSeconds: 5,
            animationType: .none,
            hapticStyle: .soft
        ))

        // R - Recognize
        steps.append(PracticeStep(
            instruction: String(localized: "R — Recognize: What am I feeling right now?"),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .light
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "Simply name what's present. Anxiety? Sadness? Frustration? There's no wrong answer."),
            durationSeconds: 20,
            animationType: .notice,
            hapticStyle: .none
        ))

        // A - Allow
        steps.append(PracticeStep(
            instruction: String(localized: "A — Allow: Can I let this feeling be here?"),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .light
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "You don't have to like it or want it. Just let it exist without pushing it away."),
            durationSeconds: 20,
            animationType: .notice,
            hapticStyle: .none
        ))

        // I - Investigate
        steps.append(PracticeStep(
            instruction: String(localized: "I — Investigate: Where do I feel this in my body?"),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .light
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "With curiosity, notice physical sensations. Tightness? Heaviness? Where exactly?"),
            durationSeconds: 25,
            animationType: .notice,
            hapticStyle: .none
        ))

        // N - Nurture
        steps.append(PracticeStep(
            instruction: String(localized: "N — Nurture: What do I need right now?"),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .light
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "Offer yourself what you need. Perhaps words of comfort, or simply the intention to be kind."),
            durationSeconds: 25,
            animationType: .relax,
            hapticStyle: .soft
        ))

        steps.append(PracticeStep(
            instruction: String(localized: "Rest here for a moment. You've done important work."),
            durationSeconds: nil,
            animationType: .none,
            hapticStyle: .medium
        ))

        return steps
    }

    private static func oneMindfulBreathSteps() -> [PracticeStep] {
        [
            PracticeStep(
                instruction: String(localized: "Just one breath. That's all."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .soft
            ),
            PracticeStep(
                instruction: String(localized: "Breathe in deeply..."),
                durationSeconds: 5,
                animationType: .breatheIn,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "And let it go..."),
                durationSeconds: 7,
                animationType: .breatheOut,
                hapticStyle: .medium
            ),
            PracticeStep(
                instruction: String(localized: "You did it. That's enough."),
                durationSeconds: nil,
                animationType: .none,
                hapticStyle: .soft
            )
        ]
    }

    private static func noticingPracticeSteps() -> [PracticeStep] {
        [
            PracticeStep(
                instruction: String(localized: "Pause."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .soft
            ),
            PracticeStep(
                instruction: String(localized: "What's one thing you can appreciate about this moment — however small?"),
                durationSeconds: nil,
                animationType: .notice,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "Let that feeling of appreciation settle in your body for a moment."),
                durationSeconds: 10,
                animationType: .relax,
                hapticStyle: .soft
            ),
            PracticeStep(
                instruction: String(localized: "Carry this with you."),
                durationSeconds: nil,
                animationType: .none,
                hapticStyle: .medium
            )
        ]
    }

    private static func gentleMovementSteps() -> [PracticeStep] {
        [
            PracticeStep(
                instruction: String(localized: "Let's release some tension. Sit or stand comfortably."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .soft
            ),
            PracticeStep(
                instruction: String(localized: "Roll your shoulders backward slowly... 1..."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "2..."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "3..."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "Now roll them forward... 1..."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "2..."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "3..."),
                durationSeconds: 3,
                animationType: .none,
                hapticStyle: .light
            ),
            PracticeStep(
                instruction: String(localized: "Take a breath. Notice how your shoulders feel now."),
                durationSeconds: nil,
                animationType: .none,
                hapticStyle: .medium
            )
        ]
    }
}

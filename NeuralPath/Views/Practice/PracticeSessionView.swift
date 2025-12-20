//
//  PracticeSessionView.swift
//  NeuralPath
//

import SwiftUI

struct PracticeSessionView: View {
    let practice: GuidedPractice
    let userMindfulness: [UserMindfulness]
    let onComplete: (Bool, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentStepIndex = 0
    @State private var isStepActive = false
    @State private var hasStarted = false
    @State private var showExitConfirmation = false
    @State private var showCompletion = false
    @State private var stepTimer: Timer?
    @State private var showContinueButton = false

    private var currentStep: PracticeStep {
        practice.steps[currentStepIndex]
    }

    private var isLastStep: Bool {
        currentStepIndex == practice.steps.count - 1
    }

    private var isPracticeInLibrary: Bool {
        userMindfulness.contains { $0.name == practice.name }
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            if showCompletion {
                PracticeCompletionView(
                    practice: practice,
                    isPracticeInLibrary: isPracticeInLibrary,
                    onDone: {
                        onComplete(true, practice.steps.count)
                        dismiss()
                    },
                    onAddToLibrary: {
                        // Will be handled by parent
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                sessionContent
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showCompletion)
        .confirmationDialog(
            "End Practice?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("End & Log Progress") {
                onComplete(false, currentStepIndex)
                dismiss()
            }
            Button("Exit Without Saving", role: .destructive) {
                dismiss()
            }
            Button("Continue Practice", role: .cancel) {}
        } message: {
            Text("You showed up. That matters.")
        }
        .onAppear {
            // Don't auto-start - wait for user to tap "Begin"
        }
        .onDisappear {
            stepTimer?.invalidate()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                practice.category.color.opacity(0.1),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Session Content

    private var sessionContent: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding()

            Spacer()

            // Animation area
            animationView
                .frame(height: 280)

            Spacer()

            // Instruction
            instructionText
                .padding(.horizontal, 32)

            Spacer()

            // Progress and controls
            progressSection
                .padding()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                showExitConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(practice.name)
                    .font(.subheadline.weight(.semibold))
                Text(practice.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    // MARK: - Animation View

    @ViewBuilder
    private var animationView: some View {
        switch currentStep.animationType {
        case .breatheIn, .breatheOut, .hold:
            AnimatedBreathingCircle(
                animation: currentStep.animationType,
                color: practice.category.color,
                isActive: isStepActive
            )

        case .bodyRegion:
            if let region = currentStep.bodyRegion {
                BodyScanOverlay(
                    highlightedRegion: region,
                    color: practice.category.color
                )
            }

        case .sensory:
            if let sense = currentStep.sensoryType {
                SensoryCard(
                    sensoryType: sense,
                    color: practice.category.color
                )
            }

        case .count:
            if let duration = currentStep.durationSeconds {
                AnimatedCountdown(
                    totalSeconds: duration,
                    color: practice.category.color,
                    isActive: isStepActive,
                    onComplete: {}
                )
                .scaleEffect(2)
            }

        case .notice, .relax:
            noticeRelaxAnimation

        case .none:
            EmptyView()
        }
    }

    private var noticeRelaxAnimation: some View {
        Circle()
            .fill(practice.category.color.opacity(0.15))
            .frame(width: 150, height: 150)
            .overlay {
                Image(systemName: currentStep.animationType == .notice ? "eye" : "leaf")
                    .font(.system(size: 50))
                    .foregroundStyle(practice.category.color)
            }
            .scaleEffect(isStepActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isStepActive)
    }

    // MARK: - Instruction

    private var instructionText: some View {
        Text(currentStep.instruction)
            .font(.title3)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress indicator
            PracticeStepIndicator(
                currentStep: currentStepIndex,
                totalSteps: practice.steps.count,
                color: practice.category.color
            )

            // Show Begin button for first step before starting
            if currentStepIndex == 0 && !hasStarted {
                beginButton
            } else if let duration = currentStep.durationSeconds {
                // Timer for timed steps
                AnimatedCountdown(
                    totalSeconds: duration,
                    color: practice.category.color,
                    isActive: isStepActive,
                    onComplete: advanceToNextStep
                )
            } else {
                tapToContinueButton
                    .opacity(showContinueButton ? 1 : 0)
                    .disabled(!showContinueButton)
            }

            PracticeProgressText(
                currentStep: currentStepIndex,
                totalSteps: practice.steps.count
            )
        }
    }

    private var beginButton: some View {
        Button {
            hasStarted = true
            startCurrentStep()
        } label: {
            Text("Begin")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Capsule().fill(practice.category.color))
        }
    }

    private var tapToContinueButton: some View {
        Button {
            advanceToNextStep()
        } label: {
            Text("Tap to continue")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(practice.category.color))
        }
    }

    // MARK: - Step Control

    private func startCurrentStep() {
        isStepActive = true
        triggerHaptic()

        if currentStep.durationSeconds == nil {
            // Progressive reveal: hide button initially, show after delay
            let stepIndexWhenStarted = currentStepIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Only show button if still on the same step
                guard currentStepIndex == stepIndexWhenStarted else { return }
                withAnimation(.easeIn(duration: 0.5)) {
                    showContinueButton = true
                }
            }
        }
    }

    private func advanceToNextStep() {
        // Prevent double-advancement from Timer + AnimatedCountdown both firing
        guard isStepActive else { return }

        stepTimer?.invalidate()
        isStepActive = false
        showContinueButton = false

        if isLastStep {
            withAnimation {
                showCompletion = true
            }
        } else {
            currentStepIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                startCurrentStep()
            }
        }
    }

    private func triggerHaptic() {
        guard let style = currentStep.hapticStyle.feedbackStyle else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    PracticeSessionView(
        practice: GuidedPracticeDatabase.boxBreathing,
        userMindfulness: [],
        onComplete: { _, _ in }
    )
}

import SwiftUI

struct StepProgressIndicator: View {
    let currentStep: EntryStep
    var allowTapping: Bool = true
    var onStepTap: ((EntryStep) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EntryStep.allCases) { step in
                HStack(spacing: 0) {
                    // Step circle with icon
                    stepCircle(for: step)
                        .onTapGesture {
                            if allowTapping {
                                onStepTap?(step)
                            }
                        }

                    // Connector line (except after last step)
                    if step.rawValue < EntryStep.allCases.count - 1 {
                        Rectangle()
                            .fill(connectorColor(after: step))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }

    @ViewBuilder
    private func stepCircle(for step: EntryStep) -> some View {
        ZStack {
            Circle()
                .fill(circleColor(for: step))
                .frame(width: 32, height: 32)

            Image(systemName: step.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(iconColor(for: step))
        }
    }

    private func circleColor(for step: EntryStep) -> Color {
        if step == currentStep {
            return .blue
        } else if step.rawValue < currentStep.rawValue {
            return .blue.opacity(0.15)
        } else {
            return Color(.systemGray5)
        }
    }

    private func iconColor(for step: EntryStep) -> Color {
        if step == currentStep {
            return .white
        } else if step.rawValue < currentStep.rawValue {
            return .blue
        } else {
            return .secondary
        }
    }

    private func connectorColor(after step: EntryStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return .blue.opacity(0.3)
        } else {
            return Color(.systemGray5)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        StepProgressIndicator(currentStep: .coreFeelings)
        StepProgressIndicator(currentStep: .physicalHealth)
        StepProgressIndicator(currentStep: .medications)
        StepProgressIndicator(currentStep: .wellness)
        StepProgressIndicator(currentStep: .review)
    }
    .padding()
}

//
//  PracticeStepIndicator.swift
//  NeuralPath
//

import SwiftUI

struct PracticeStepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? color : color.opacity(0.2))
                    .frame(width: index == currentStep ? 24 : 8, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

struct PracticeProgressText: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        Text("\(currentStep + 1) of \(totalSteps)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}

#Preview {
    VStack(spacing: 40) {
        PracticeStepIndicator(currentStep: 0, totalSteps: 10, color: .cyan)
        PracticeStepIndicator(currentStep: 5, totalSteps: 10, color: .cyan)
        PracticeStepIndicator(currentStep: 9, totalSteps: 10, color: .cyan)

        PracticeProgressText(currentStep: 2, totalSteps: 12)
    }
    .padding()
}

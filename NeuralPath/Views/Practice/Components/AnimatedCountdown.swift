//
//  AnimatedCountdown.swift
//  NeuralPath
//

import SwiftUI

struct AnimatedCountdown: View {
    let totalSeconds: Int
    let color: Color
    let isActive: Bool
    let onComplete: () -> Void

    @State private var remainingSeconds: Int
    @State private var progress: Double = 1.0
    @State private var startTime: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(totalSeconds: Int, color: Color, isActive: Bool, onComplete: @escaping () -> Void) {
        self.totalSeconds = totalSeconds
        self.color = color
        self.isActive = isActive
        self.onComplete = onComplete
        self._remainingSeconds = State(initialValue: totalSeconds)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: 60, height: 60)

            // Progress ring - continuous animation
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))

            // Time display
            Text("\(remainingSeconds)")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .onAppear {
            if isActive {
                startCountdown()
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                startCountdown()
            } else {
                resetCountdown()
            }
        }
    }

    private func startCountdown() {
        remainingSeconds = totalSeconds
        progress = 1.0
        startTime = Date()

        // Animate progress ring smoothly to 0 over the total duration
        if !reduceMotion {
            withAnimation(.linear(duration: Double(totalSeconds))) {
                progress = 0
            }
        }

        // Update the displayed number each second
        scheduleNumberUpdates()
    }

    private func resetCountdown() {
        remainingSeconds = totalSeconds
        progress = 1.0
        startTime = nil
    }

    private func scheduleNumberUpdates() {
        for second in 1...totalSeconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(second)) { [self] in
                guard isActive, startTime != nil else { return }

                let newValue = totalSeconds - second
                withAnimation(.easeInOut(duration: 0.15)) {
                    remainingSeconds = newValue
                }

                if newValue == 0 {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AnimatedCountdown(
            totalSeconds: 4,
            color: .cyan,
            isActive: true,
            onComplete: {}
        )

        AnimatedCountdown(
            totalSeconds: 7,
            color: .pink,
            isActive: true,
            onComplete: {}
        )
    }
    .padding()
}

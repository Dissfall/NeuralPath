//
//  AnimatedBreathingCircle.swift
//  NeuralPath
//

import SwiftUI

struct AnimatedBreathingCircle: View {
    let animation: PracticeAnimation
    let color: Color
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scale: CGFloat = 1.0
    @State private var innerOpacity: Double = 0.3
    @State private var outerOpacity: Double = 0.15

    private let baseSize: CGFloat = 200
    private let minScale: CGFloat = 0.6
    private let maxScale: CGFloat = 1.4

    var body: some View {
        ZStack {
            if reduceMotion {
                staticIndicator
            } else {
                animatedCircle
            }
        }
        .onChange(of: animation) { _, newAnimation in
            animateForType(newAnimation)
        }
        .onChange(of: isActive) { _, active in
            if active {
                animateForType(animation)
            }
            // Don't reset when isActive becomes false - preserve scale between steps
        }
        .onAppear {
            if isActive {
                animateForType(animation)
            }
        }
    }

    // MARK: - Animated View

    private var animatedCircle: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.3), color.opacity(0)],
                        center: .center,
                        startRadius: baseSize * 0.3 * scale,
                        endRadius: baseSize * 0.7 * scale
                    )
                )
                .frame(width: baseSize * 1.5, height: baseSize * 1.5)
                .scaleEffect(scale)
                .opacity(outerOpacity)

            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.8), color.opacity(0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize * 0.5
                    )
                )
                .frame(width: baseSize, height: baseSize)
                .scaleEffect(scale)
                .opacity(innerOpacity + 0.5)

            // Inner highlight
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: baseSize * 0.4, height: baseSize * 0.4)
                .scaleEffect(scale)
                .blur(radius: 10)

            // Center dot for focus
            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Static Fallback (Reduced Motion)

    private var staticIndicator: some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(color, lineWidth: 4)
                .frame(width: baseSize * 0.6, height: baseSize * 0.6)
                .overlay {
                    animationIcon
                        .font(.system(size: 40))
                        .foregroundStyle(color)
                }

            Text(animationLabel)
                .font(.headline)
                .foregroundStyle(color)
        }
    }

    private var animationIcon: some View {
        Group {
            switch animation {
            case .breatheIn:
                Image(systemName: "arrow.up.circle")
            case .breatheOut:
                Image(systemName: "arrow.down.circle")
            case .hold:
                Image(systemName: "pause.circle")
            default:
                Image(systemName: "circle")
            }
        }
    }

    private var animationLabel: String {
        switch animation {
        case .breatheIn: return "Breathe In"
        case .breatheOut: return "Breathe Out"
        case .hold: return "Hold"
        case .count: return "Count"
        case .notice: return "Notice"
        case .relax: return "Relax"
        default: return ""
        }
    }

    // MARK: - Animation Control

    private func animateForType(_ type: PracticeAnimation) {
        guard isActive else { return }

        switch type {
        case .breatheIn:
            animateBreatheIn()
        case .breatheOut:
            animateBreatheOut()
        case .hold:
            animateHold()
        case .notice, .relax:
            animateGentle()
        default:
            resetAnimation()
        }
    }

    private func animateBreatheIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            innerOpacity = 0.4
            outerOpacity = 0.2
        }
        withAnimation(.easeIn(duration: 4)) {
            scale = maxScale
        }
    }

    private func animateBreatheOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            innerOpacity = 0.3
            outerOpacity = 0.15
        }
        withAnimation(.easeOut(duration: 4)) {
            scale = minScale
        }
    }

    private func animateHold() {
        // Don't touch scale - let it stay at current size
        // Just do subtle opacity pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            innerOpacity = 0.45
        }
    }

    private func animateGentle() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            innerOpacity = 0.5
        }
    }

    private func resetAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            innerOpacity = 0.3
            outerOpacity = 0.15
        }
    }
}

// MARK: - Preview

#Preview("Breathe In") {
    AnimatedBreathingCircle(
        animation: .breatheIn,
        color: .cyan,
        isActive: true
    )
    .padding()
    .background(.black)
}

#Preview("Breathe Out") {
    AnimatedBreathingCircle(
        animation: .breatheOut,
        color: .cyan,
        isActive: true
    )
    .padding()
    .background(.black)
}

#Preview("Hold") {
    AnimatedBreathingCircle(
        animation: .hold,
        color: .cyan,
        isActive: true
    )
    .padding()
    .background(.black)
}

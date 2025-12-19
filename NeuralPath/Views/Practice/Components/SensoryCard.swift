//
//  SensoryCard.swift
//  NeuralPath
//

import SwiftUI

struct SensoryCard: View {
    let sensoryType: SensoryType
    let color: Color

    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            // Sense icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: sensoryType.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(color)
                    .scaleEffect(iconScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    iconScale = 1.1
                }
            }

            // Count badge
            HStack(spacing: 4) {
                Text("\(sensoryType.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                Text(sensoryType == .taste ? "thing" : "things")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Instruction
            Text(sensoryType.instruction)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 40) {
        SensoryCard(sensoryType: .see, color: .teal)
        SensoryCard(sensoryType: .feel, color: .teal)
        SensoryCard(sensoryType: .taste, color: .teal)
    }
}

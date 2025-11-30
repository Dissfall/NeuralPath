//
//  EmotionCloudSelector.swift
//  NeuralPath
//

import SwiftUI

struct EmotionCloudSelector: View {
    @Binding var selectedEmotions: Set<Emotion>

    var body: some View {
        WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(Emotion.allCases) { emotion in
                EmotionChip(
                    emotion: emotion,
                    isSelected: selectedEmotions.contains(emotion),
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedEmotions.contains(emotion) {
                                selectedEmotions.remove(emotion)
                            } else {
                                selectedEmotions.insert(emotion)
                            }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            }
        }
    }
}

struct EmotionChip: View {
    let emotion: Emotion
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                Text(emotion.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(emotion.color.opacity(isSelected ? 0.3 : 0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(emotion.color.opacity(isSelected ? 0.6 : 0), lineWidth: 1.5)
            )
            .foregroundStyle(emotion.color)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: Set<Emotion> = [.happy, .calm]

        var body: some View {
            VStack {
                EmotionCloudSelector(selectedEmotions: $selected)
                    .padding()

                Divider()

                Text("Selected: \(selected.map { $0.displayName }.joined(separator: ", "))")
                    .font(.caption)
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}

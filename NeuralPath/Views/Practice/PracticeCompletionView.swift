//
//  PracticeCompletionView.swift
//  NeuralPath
//

import SwiftUI

struct PracticeCompletionView: View {
    let practice: GuidedPractice
    let isPracticeInLibrary: Bool
    let onDone: () -> Void
    let onAddToLibrary: () -> Void

    @State private var showCheckmark = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(practice.category.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showCheckmark ? 1 : 0.5)
                    .opacity(showCheckmark ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(practice.category.color)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .opacity(showCheckmark ? 1 : 0)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showCheckmark)

            // Message
            VStack(spacing: 12) {
                Text("Well done")
                    .font(.title.weight(.semibold))

                Text("You completed \(practice.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(practice.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(practice.category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(practice.category.color.opacity(0.15))
                    )
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                if !isPracticeInLibrary {
                    Button {
                        onAddToLibrary()
                        onDone()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add to Library")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(practice.category.color)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(practice.category.color, lineWidth: 1)
                        )
                    }
                }

                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(practice.category.color)
                        )
                }
            }
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)

            Spacer()
                .frame(height: 40)
        }
        .onAppear {
            triggerSuccessHaptic()
            withAnimation {
                showCheckmark = true
            }
            showContent = true
        }
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    PracticeCompletionView(
        practice: GuidedPracticeDatabase.boxBreathing,
        isPracticeInLibrary: false,
        onDone: {},
        onAddToLibrary: {}
    )
}

#Preview("In Library") {
    PracticeCompletionView(
        practice: GuidedPracticeDatabase.boxBreathing,
        isPracticeInLibrary: true,
        onDone: {},
        onAddToLibrary: {}
    )
}

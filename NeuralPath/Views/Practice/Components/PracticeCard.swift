//
//  PracticeCard.swift
//  NeuralPath
//

import SwiftUI

struct PracticeCard: View {
    let practice: GuidedPractice
    let style: CardStyle
    let onTap: () -> Void

    enum CardStyle {
        case compact  // For horizontal scroll suggestions
        case full     // For vertical list
    }

    var body: some View {
        Button(action: onTap) {
            Group {
                switch style {
                case .compact:
                    compactCard
                case .full:
                    fullCard
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Compact Style (Suggestions)

    private var compactCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: practice.category.icon)
                    .font(.title2)
                    .foregroundStyle(practice.category.color)
                Spacer()
                durationBadge
            }

            Text(practice.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(practice.benefit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(width: 160, height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(practice.category.color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Full Style (List)

    private var fullCard: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(practice.category.color.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: practice.category.icon)
                        .font(.title3)
                        .foregroundStyle(practice.category.color)
                }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(practice.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    durationBadge
                }

                Text(practice.benefit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Duration Badge

    private var durationBadge: some View {
        Text(practice.formattedDuration)
            .font(.caption2.weight(.medium))
            .foregroundStyle(practice.category.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(practice.category.color.opacity(0.15))
            )
    }
}

#Preview("Compact") {
    HStack {
        PracticeCard(
            practice: GuidedPracticeDatabase.boxBreathing,
            style: .compact,
            onTap: {}
        )
        PracticeCard(
            practice: GuidedPracticeDatabase.oneMindfulBreath,
            style: .compact,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Full") {
    VStack {
        PracticeCard(
            practice: GuidedPracticeDatabase.boxBreathing,
            style: .full,
            onTap: {}
        )
        PracticeCard(
            practice: GuidedPracticeDatabase.selfCompassionBreak,
            style: .full,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

//
//  TimelineComponents.swift
//  NeuralPath
//

import SwiftUI

// MARK: - Time Block

enum TimeBlock: String, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .indigo
        }
    }

    var defaultTime: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch self {
        case .morning:
            return calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today
        case .afternoon:
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today) ?? today
        case .evening:
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today
        }
    }

    static func from(hour: Int) -> TimeBlock {
        switch hour {
        case 5..<12: return .morning
        case 12..<18: return .afternoon
        default: return .evening
        }
    }

    static func from(date: Date) -> TimeBlock {
        let hour = Calendar.current.component(.hour, from: date)
        return from(hour: hour)
    }
}

// MARK: - Timeline Item Type

enum TimelineItemType {
    case scheduledMedication(UserMedication)
    case prnMedication(MedicationLog)
    case substance(SubstanceLog)
    case mindfulness(MindfulnessLog)
    case scheduledSelfCare(UserSelfCare)
    case loggedSelfCare(SelfCareLog)
}

// MARK: - Timeline Item

struct TimelineItem: Identifiable {
    let id: String
    let type: TimelineItemType
    let name: String
    let time: Date
    let plannedTime: Date?
    let isCompleted: Bool
    let subtitle: String?

    var effectiveTime: Date {
        time
    }

    var timeBlock: TimeBlock {
        TimeBlock.from(date: effectiveTime)
    }

    var icon: String {
        switch type {
        case .scheduledMedication, .prnMedication:
            return "pills.fill"
        case .substance:
            return "drop.triangle.fill"
        case .mindfulness:
            return "brain.head.profile"
        case .scheduledSelfCare, .loggedSelfCare:
            return "heart.fill"
        }
    }

    var color: Color {
        switch type {
        case .scheduledMedication, .prnMedication:
            return .blue
        case .substance:
            return .purple
        case .mindfulness:
            return .teal
        case .scheduledSelfCare, .loggedSelfCare:
            return .pink
        }
    }

    var isPRN: Bool {
        if case .prnMedication = type { return true }
        return false
    }
}

// MARK: - Time Block Section

struct TimeBlockSection: Identifiable {
    let block: TimeBlock
    let items: [TimelineItem]

    var id: String { block.rawValue }
}

// MARK: - Time Block Header

struct TimeBlockHeader: View {
    let block: TimeBlock
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: block.icon)
                .foregroundStyle(block.color)

            Text(block.displayName)
                .font(.headline)

            Spacer()

            if totalCount > 0 {
                Text("\(completedCount)/\(totalCount)")
                    .font(.subheadline)
                    .foregroundStyle(completedCount == totalCount ? .green : .secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Timeline Item Row

struct TimelineItemRow: View {
    let item: TimelineItem
    let onTap: () -> Void

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion indicator
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .font(.title3)

                // Icon
                Image(systemName: item.icon)
                    .foregroundStyle(item.color)
                    .font(.subheadline)
                    .frame(width: 20)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        if item.isPRN {
                            Text("PRN")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Time
                VStack(alignment: .trailing, spacing: 2) {
                    if item.isCompleted {
                        Text(timeFormatter.string(from: item.time))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let planned = item.plannedTime {
                        Text(timeFormatter.string(from: planned))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("planned")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Finish Day Button

struct FinishDayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                Text("Finish Day")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Add Item FAB

struct AddItemFAB: View {
    let userSubstances: [UserSubstance]
    let userMindfulness: [UserMindfulness]
    let userSelfCare: [UserSelfCare]
    let prnMedications: [UserMedication]
    let onLogSubstance: (UserSubstance) -> Void
    let onLogMindfulness: (UserMindfulness) -> Void
    let onLogSelfCare: (UserSelfCare) -> Void
    let onLogPRN: (UserMedication) -> Void

    var body: some View {
        Menu {
            if !userSubstances.isEmpty {
                Menu {
                    ForEach(userSubstances) { substance in
                        Button {
                            onLogSubstance(substance)
                        } label: {
                            Label(substance.name ?? "Unknown", systemImage: "drop.triangle")
                        }
                    }
                } label: {
                    Label("Substance", systemImage: "drop.triangle.fill")
                }
            }

            if !userMindfulness.isEmpty {
                Menu {
                    ForEach(userMindfulness) { practice in
                        Button {
                            onLogMindfulness(practice)
                        } label: {
                            Label(practice.name ?? "Unknown", systemImage: practice.category?.icon ?? "brain.head.profile")
                        }
                    }
                } label: {
                    Label("Mindfulness", systemImage: "brain.head.profile")
                }
            }

            if !userSelfCare.isEmpty {
                Menu {
                    ForEach(userSelfCare) { practice in
                        Button {
                            onLogSelfCare(practice)
                        } label: {
                            Label(practice.name ?? "Unknown", systemImage: practice.timeOfDay.icon)
                        }
                    }
                } label: {
                    Label("Self-Care", systemImage: "heart.fill")
                }
            }

            if !prnMedications.isEmpty {
                Menu {
                    ForEach(prnMedications) { medication in
                        Button {
                            onLogPRN(medication)
                        } label: {
                            Label(medication.name ?? "Unknown", systemImage: "pills")
                        }
                    }
                } label: {
                    Label("As-Needed Medication", systemImage: "pills.fill")
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.blue))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Empty Timeline View

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Your day starts here")
                .font(.headline)

            Text("Use the + button to log activities")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview("Time Block Header") {
    VStack {
        TimeBlockHeader(block: .morning, completedCount: 2, totalCount: 3)
        TimeBlockHeader(block: .afternoon, completedCount: 1, totalCount: 1)
        TimeBlockHeader(block: .evening, completedCount: 0, totalCount: 2)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Finish Day Button") {
    FinishDayButton(action: {})
        .padding()
}

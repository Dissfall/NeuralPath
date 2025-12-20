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

// MARK: - Swipe Action

struct SwipeAction: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
}

// MARK: - Swipeable Timeline Item Row

struct SwipeableTimelineItemRow: View {
    let item: TimelineItem
    let onTap: () -> Void
    let swipeActions: [SwipeAction]

    @State private var offset: CGFloat = 0
    @State private var isShowingActions = false
    @State private var activeButtonSpacing: CGFloat = 0
    @GestureState private var isDragging = false

    private let actionButtonWidth: CGFloat = 56
    private let buttonSpacing: CGFloat = 8
    private let cardToButtonsGap: CGFloat = 10

    private var totalActionsWidth: CGFloat {
        CGFloat(swipeActions.count) * (actionButtonWidth + buttonSpacing)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe action buttons - only visible when swiping
            if offset < 0 || isShowingActions {
                GlassEffectContainer {
                    HStack(spacing: activeButtonSpacing) {
                        ForEach(swipeActions) { action in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    offset = 0
                                    isShowingActions = false
                                    activeButtonSpacing = 0
                                }
                                action.action()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: action.icon)
                                        .font(.body.weight(.medium))
                                    Text(action.label)
                                        .font(.caption2)
                                }
                                .foregroundStyle(.white)
                                .frame(width: actionButtonWidth, height: 60)
                            }
                            .glassEffect(.clear.tint(action.color).interactive(), in: RoundedRectangle(cornerRadius: 16, style: .circular))
                        }
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }

            // Main content
            TimelineItemRowContent(item: item)
                .onTapGesture {
                    if isShowingActions {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                            isShowingActions = false
                            activeButtonSpacing = 0
                        }
                    } else {
                        onTap()
                    }
                }
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            // Only respond to horizontal swipes
                            let horizontalAmount = abs(value.translation.width)
                            let verticalAmount = abs(value.translation.height)

                            guard horizontalAmount > verticalAmount else { return }

                            let translation = value.translation.width
                            if translation < 0 {
                                offset = max(translation, -totalActionsWidth - 10)
                            } else if isShowingActions {
                                offset = min(-totalActionsWidth + translation, 0)
                            } else if translation > 0 && offset < 0 {
                                offset = min(offset + translation, 0)
                            }
                            
                            activeButtonSpacing = -offset / buttonSpacing
                        }
                        .onEnded { value in
                            let horizontalAmount = abs(value.translation.width)
                            let verticalAmount = abs(value.translation.height)

                            withAnimation(.spring(response: 0.3)) {
                                if horizontalAmount > verticalAmount && value.translation.width < -50 {
                                    offset = -totalActionsWidth
                                    isShowingActions = true
                                    activeButtonSpacing = buttonSpacing
                                } else {
                                    offset = 0
                                    isShowingActions = false
                                    activeButtonSpacing = 0
                                }
                            }
                        }
                )
        }
        .padding(.horizontal)
        .padding(.vertical, 3)
    }
}

// MARK: - Timeline Item Row Content

private struct TimelineItemRowContent: View {
    let item: TimelineItem

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator with colored background
            ZStack {
                Circle()
                    .fill(item.isCompleted ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)

                if (item.isCompleted) {
                    Image(systemName: item.isCompleted ? "checkmark" : item.icon)
                        .foregroundStyle(item.isCompleted ? .green : item.color)
                        .font(.subheadline.weight(.semibold))
                }
            }
            
            Image(systemName: item.icon)
                .foregroundStyle(item.color)
                .font(.subheadline.weight(.semibold))
                .background {
                    Circle()
                        .fill(item.color.opacity(0.1))
                        .frame(width: 36, height: 36)
                }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    if item.isPRN {
                        Text("PRN")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
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

            // Time badge
            Text(timeText)
                .font(.caption.weight(.medium))
                .foregroundStyle(item.isCompleted ? .secondary : .tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.isCompleted ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1.5)
        )
    }

    private var timeText: String {
        if item.isCompleted {
            return timeFormatter.string(from: item.time)
        } else if let planned = item.plannedTime {
            return timeFormatter.string(from: planned)
        } else {
            return "planned"
        }
    }
}

// MARK: - Simple Timeline Item Row (no swipe)

struct TimelineItemRow: View {
    let item: TimelineItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            TimelineItemRowContent(item: item)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 3)
    }
}

// MARK: - Finish Day Button

struct FinishDayButton: View {
    let action: () -> Void

    var body: some View {
        VStack {
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
            }
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .buttonStyle(.borderless)
            .glassEffect(.clear.interactive())
        }
        .padding()
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
                .foregroundColor(.white)
        }
        .padding()
        .glassEffect(.clear.interactive())
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

// MARK: - Previews

private enum PreviewHelpers {
    static func time(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    static var sampleMedication: UserMedication {
        UserMedication(name: "Sertraline", dosage: "50mg", category: .ssri, frequency: .onceDaily)
    }

    static var sampleMedicationLog: MedicationLog {
        MedicationLog(userMedication: nil, medicationName: "Ibuprofen", timestamp: time(hour: 14, minute: 30))
    }

    static var sampleSubstanceLog: SubstanceLog {
        SubstanceLog(userSubstance: nil, substanceName: "Coffee", amount: 2, unit: .cups, timestamp: time(hour: 7, minute: 45))
    }

    static var sampleMindfulnessLog: MindfulnessLog {
        MindfulnessLog(userMindfulness: nil, practiceName: "Morning Meditation", timestamp: time(hour: 7))
    }

    static var sampleSelfCare: UserSelfCare {
        UserSelfCare(name: "Morning Stretch", timeOfDay: .morning)
    }

    static var sampleSelfCareLog: SelfCareLog {
        SelfCareLog(userSelfCare: nil, practiceName: "Evening Journal", timeOfDay: .evening, timestamp: time(hour: 21))
    }

    static var completedMedicationItem: TimelineItem {
        TimelineItem(
            id: "med_1",
            type: .scheduledMedication(sampleMedication),
            name: "Sertraline",
            time: time(hour: 8, minute: 30),
            plannedTime: time(hour: 8),
            isCompleted: true,
            subtitle: "50mg"
        )
    }

    static var pendingMedicationItem: TimelineItem {
        TimelineItem(
            id: "med_2",
            type: .scheduledMedication(sampleMedication),
            name: "Vitamin D",
            time: time(hour: 9),
            plannedTime: time(hour: 9),
            isCompleted: false,
            subtitle: "1000 IU"
        )
    }

    static var prnMedicationItem: TimelineItem {
        TimelineItem(
            id: "prn_1",
            type: .prnMedication(sampleMedicationLog),
            name: "Ibuprofen",
            time: time(hour: 14, minute: 30),
            plannedTime: nil,
            isCompleted: true,
            subtitle: nil
        )
    }

    static var substanceItem: TimelineItem {
        TimelineItem(
            id: "sub_1",
            type: .substance(sampleSubstanceLog),
            name: "Coffee",
            time: time(hour: 7, minute: 45),
            plannedTime: nil,
            isCompleted: true,
            subtitle: "2 cups"
        )
    }

    static var mindfulnessItem: TimelineItem {
        TimelineItem(
            id: "mind_1",
            type: .mindfulness(sampleMindfulnessLog),
            name: "Morning Meditation",
            time: time(hour: 7),
            plannedTime: nil,
            isCompleted: true,
            subtitle: "Guided"
        )
    }

    static var selfCareItem: TimelineItem {
        TimelineItem(
            id: "selfcare_1",
            type: .loggedSelfCare(sampleSelfCareLog),
            name: "Evening Journal",
            time: time(hour: 21),
            plannedTime: time(hour: 21),
            isCompleted: true,
            subtitle: "Evening"
        )
    }

    static var medicationSwipeActions: [SwipeAction] {
        [
            SwipeAction(icon: "arrow.uturn.backward", label: "Undo", color: .orange, action: {}),
            SwipeAction(icon: "clock", label: "Time", color: .blue, action: {})
        ]
    }

    static var substanceSwipeActions: [SwipeAction] {
        [
            SwipeAction(icon: "number", label: "Amount", color: .purple, action: {}),
            SwipeAction(icon: "clock", label: "Time", color: .blue, action: {}),
            SwipeAction(icon: "trash", label: "Delete", color: .red, action: {})
        ]
    }

    static var prnSwipeActions: [SwipeAction] {
        [
            SwipeAction(icon: "clock", label: "Time", color: .blue, action: {}),
            SwipeAction(icon: "trash", label: "Delete", color: .red, action: {})
        ]
    }
}

#Preview("Swipeable Row - Medication") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Swipe left to reveal actions")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top)

            SwipeableTimelineItemRow(
                item: PreviewHelpers.completedMedicationItem,
                onTap: {},
                swipeActions: PreviewHelpers.medicationSwipeActions
            )
        }
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Swipeable Row - Substance (3 actions)") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Swipe left to reveal actions")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top)

            SwipeableTimelineItemRow(
                item: PreviewHelpers.substanceItem,
                onTap: {},
                swipeActions: PreviewHelpers.substanceSwipeActions
            )
        }
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Swipeable Row - PRN Medication") {
    ScrollView {
        VStack(spacing: 16) {
            Text("PRN medications show badge")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top)

            SwipeableTimelineItemRow(
                item: PreviewHelpers.prnMedicationItem,
                onTap: {},
                swipeActions: PreviewHelpers.prnSwipeActions
            )
        }
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("All Item Types") {
    ScrollView {
        LazyVStack(spacing: 0) {
            TimeBlockHeader(block: .morning, completedCount: 3, totalCount: 4)

            SwipeableTimelineItemRow(
                item: PreviewHelpers.mindfulnessItem,
                onTap: {},
                swipeActions: PreviewHelpers.prnSwipeActions
            )

            SwipeableTimelineItemRow(
                item: PreviewHelpers.substanceItem,
                onTap: {},
                swipeActions: PreviewHelpers.substanceSwipeActions
            )

            SwipeableTimelineItemRow(
                item: PreviewHelpers.completedMedicationItem,
                onTap: {},
                swipeActions: PreviewHelpers.medicationSwipeActions
            )

            TimelineItemRow(item: PreviewHelpers.pendingMedicationItem, onTap: {})

            TimeBlockHeader(block: .evening, completedCount: 1, totalCount: 1)

            SwipeableTimelineItemRow(
                item: PreviewHelpers.selfCareItem,
                onTap: {},
                swipeActions: PreviewHelpers.medicationSwipeActions
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Full Timeline Demo") {
    NavigationStack {
        ScrollView {
            LazyVStack(spacing: 0) {
                TimeBlockHeader(block: .morning, completedCount: 3, totalCount: 4)

                SwipeableTimelineItemRow(
                    item: PreviewHelpers.mindfulnessItem,
                    onTap: {},
                    swipeActions: PreviewHelpers.prnSwipeActions
                )

                SwipeableTimelineItemRow(
                    item: PreviewHelpers.substanceItem,
                    onTap: {},
                    swipeActions: PreviewHelpers.substanceSwipeActions
                )

                SwipeableTimelineItemRow(
                    item: PreviewHelpers.completedMedicationItem,
                    onTap: {},
                    swipeActions: PreviewHelpers.medicationSwipeActions
                )

                TimelineItemRow(item: PreviewHelpers.pendingMedicationItem, onTap: {})

                TimeBlockHeader(block: .afternoon, completedCount: 1, totalCount: 1)

                SwipeableTimelineItemRow(
                    item: PreviewHelpers.prnMedicationItem,
                    onTap: {},
                    swipeActions: PreviewHelpers.prnSwipeActions
                )

                TimeBlockHeader(block: .evening, completedCount: 1, totalCount: 1)

                SwipeableTimelineItemRow(
                    item: PreviewHelpers.selfCareItem,
                    onTap: {},
                    swipeActions: PreviewHelpers.medicationSwipeActions
                )

                FinishDayButton(action: {})
                    .padding(.top, 16)

                Color.clear.frame(height: 80)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Today")
    }
}

#Preview("Empty Timeline") {
    EmptyTimelineView()
        .background(Color(.systemGroupedBackground))
}

#Preview("Finish Day Button") {
    VStack {
        Spacer()
        FinishDayButton(action: {})
    }
    .frame(height: 200)
    .background(Color(.systemGroupedBackground))
}


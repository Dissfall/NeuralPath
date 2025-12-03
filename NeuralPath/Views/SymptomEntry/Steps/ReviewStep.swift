import SwiftUI

struct ReviewStep: View {
    @Bindable var viewModel: StepperEntryViewModel
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Notes Section
                notesSection

                // Summary Cards
                if viewModel.hasCoreFeelings {
                    ReviewSectionCard(
                        title: "Feelings",
                        icon: "face.smiling",
                        color: .blue,
                        onEdit: { viewModel.goToStep(.coreFeelings) }
                    ) {
                        coreFeelingsReview
                    }
                }

                if viewModel.hasPhysicalHealth {
                    ReviewSectionCard(
                        title: "Physical Health",
                        icon: "heart.text.square",
                        color: .red,
                        onEdit: { viewModel.goToStep(.physicalHealth) }
                    ) {
                        physicalHealthReview
                    }
                }

                if viewModel.hasMedications {
                    ReviewSectionCard(
                        title: "Medications & Substances",
                        icon: "pills",
                        color: .blue,
                        onEdit: { viewModel.goToStep(.medications) }
                    ) {
                        medicationsReview
                    }
                }

                if viewModel.hasWellness {
                    ReviewSectionCard(
                        title: "Wellness",
                        icon: "sparkles",
                        color: .purple,
                        onEdit: { viewModel.goToStep(.wellness) }
                    ) {
                        wellnessReview
                    }
                }

                // Empty state
                if !viewModel.hasAnyData {
                    emptyStateView
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isNotesFocused = false
                }
            }
        }
    }

    // MARK: - Notes Section

    @ViewBuilder
    private var notesSection: some View {
        StepSectionCard(title: "Notes", icon: "note.text", color: .gray) {
            TextField("Add any additional notes about your day...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...8)
                .focused($isNotesFocused)
        }
    }

    // MARK: - Core Feelings Review

    @ViewBuilder
    private var coreFeelingsReview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let mood = viewModel.moodLevel {
                ReviewRow(label: "Mood", value: "\(mood.emoji) \(mood.displayName)")
            }

            if !viewModel.selectedEmotions.isEmpty {
                ReviewRow(label: "Emotions", value: emotionsSummary)
            }

            if let anxiety = viewModel.anxietyLevel {
                ReviewRow(label: "Anxiety", value: anxiety.displayName)
            }

            if let anhedonia = viewModel.anhedoniaLevel {
                ReviewRow(label: "Anhedonia", value: anhedonia.displayName)
            }
        }
    }

    private var emotionsSummary: String {
        let names = viewModel.selectedEmotions.map { $0.displayName }.sorted()
        if names.count <= 3 {
            return names.joined(separator: ", ")
        }
        return "\(names.prefix(2).joined(separator: ", ")) +\(names.count - 2)"
    }

    // MARK: - Physical Health Review

    @ViewBuilder
    private var physicalHealthReview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.sleepHours.isEmpty {
                let quality = viewModel.sleepQualityRating.map { "\($0)/5" } ?? ""
                let value = "\(viewModel.sleepHours) hrs" + (quality.isEmpty ? "" : " (\(quality) quality)")
                ReviewRow(label: "Sleep", value: value)
            }

            if !viewModel.exerciseMinutes.isEmpty {
                ReviewRow(label: "Exercise", value: "\(viewModel.exerciseMinutes) min")
            }

            if !viewModel.timeInDaylightMinutes.isEmpty {
                ReviewRow(label: "Daylight", value: "\(viewModel.timeInDaylightMinutes) min")
            }
        }
    }

    // MARK: - Medications Review

    @ViewBuilder
    private var medicationsReview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.takenMedications.isEmpty {
                let medNames = viewModel.takenMedications.compactMap { (id, _) -> String? in
                    viewModel.userMedications.first { $0.id == id }?.name
                }
                ReviewRow(label: "Medications", value: medNames.joined(separator: ", "))
            }

            if !viewModel.takenSubstances.isEmpty {
                let subNames = viewModel.takenSubstances.compactMap { entry -> String? in
                    viewModel.userSubstances.first { $0.id == entry.userSubstanceId }?.name
                }
                ReviewRow(label: "Substances", value: subNames.joined(separator: ", "))
            }
        }
    }

    // MARK: - Wellness Review

    @ViewBuilder
    private var wellnessReview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.loggedMindfulness.isEmpty {
                let practiceNames = viewModel.loggedMindfulness.compactMap { entry -> String? in
                    viewModel.userMindfulness.first { $0.id == entry.userMindfulnessId }?.name
                }
                ReviewRow(label: "Mindfulness", value: practiceNames.joined(separator: ", "))
            }

            if !viewModel.loggedSelfCare.isEmpty {
                let practiceNames = viewModel.loggedSelfCare.compactMap { entry -> String? in
                    viewModel.userSelfCare.first { $0.id == entry.userSelfCareId }?.name
                }
                ReviewRow(label: "Self-Care", value: practiceNames.joined(separator: ", "))
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No data entered yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Go back to previous steps to add information about your day.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Review Section Card

struct ReviewSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let onEdit: () -> Void
    @ViewBuilder let content: Content

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.headline)
                        .foregroundStyle(color)

                    Spacer()

                    Button("Edit") {
                        onEdit()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()

            if isExpanded {
                Divider()
                content
                    .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Review Row

struct ReviewRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ReviewStep(viewModel: StepperEntryViewModel())
}

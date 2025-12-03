import SwiftUI

struct WellnessStep: View {
    @Bindable var viewModel: StepperEntryViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mindfulness Section
                mindfulnessSection

                // Self-Care Section
                selfCareSection
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Mindfulness Section

    @ViewBuilder
    private var mindfulnessSection: some View {
        StepSectionCard(
            title: "Mindfulness",
            icon: "brain.head.profile",
            color: .purple
        ) {
            if viewModel.userMindfulness.isEmpty {
                emptyMindfulnessView
            } else {
                VStack(spacing: 0) {
                    // Logged practices
                    ForEach(viewModel.loggedMindfulness) { entry in
                        mindfulnessRow(entry)
                        if entry.id != viewModel.loggedMindfulness.last?.id {
                            Divider()
                        }
                    }

                    // Add practice menu
                    if !viewModel.loggedMindfulness.isEmpty {
                        Divider()
                            .padding(.top, 8)
                    }

                    Menu {
                        ForEach(viewModel.userMindfulness) { practice in
                            Button {
                                viewModel.addMindfulness(practice)
                            } label: {
                                Label(
                                    practice.name ?? "Unknown",
                                    systemImage: practice.category?.icon ?? "brain.head.profile"
                                )
                            }
                        }
                    } label: {
                        Label("Log Practice", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    .padding(.top, viewModel.loggedMindfulness.isEmpty ? 0 : 8)
                }
            }
        } footer: {
            Text("\(viewModel.mindfulnessSummary)")
        }
    }

    @ViewBuilder
    private func mindfulnessRow(_ entry: MindfulnessLogEntry) -> some View {
        let practice = viewModel.userMindfulness.first { $0.id == entry.userMindfulnessId }
        let practiceName = practice?.name ?? "Unknown"

        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            HStack(spacing: 8) {
                Image(systemName: practice?.category?.icon ?? "brain.head.profile")
                    .foregroundStyle(.purple)
                Text(practiceName)
                    .font(.subheadline)
            }

            Spacer()

            Text(timeFormatter.string(from: entry.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeMindfulness(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                viewModel.mindfulnessToEditTime = entry
                viewModel.editMindfulnessTime = entry.timestamp
            } label: {
                Label("Edit Time", systemImage: "clock")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    private var emptyMindfulnessView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No mindfulness practices in your library")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NavigationLink {
                MindfulnessManagementView()
            } label: {
                Label("Add Practices in Settings", systemImage: "gear")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Self-Care Section

    @ViewBuilder
    private var selfCareSection: some View {
        StepSectionCard(
            title: "Self-Care",
            icon: "heart.fill",
            color: .pink
        ) {
            if viewModel.userSelfCare.isEmpty {
                emptySelfCareView
            } else {
                VStack(spacing: 0) {
                    // Logged practices
                    ForEach(viewModel.loggedSelfCare) { entry in
                        selfCareRow(entry)
                        if entry.id != viewModel.loggedSelfCare.last?.id {
                            Divider()
                        }
                    }

                    // Add practice menu (grouped by time of day)
                    if !viewModel.loggedSelfCare.isEmpty {
                        Divider()
                            .padding(.top, 8)
                    }

                    Menu {
                        ForEach(SelfCareTimeOfDay.allCases, id: \.self) { timeOfDay in
                            let practicesForTime = viewModel.userSelfCare.filter { $0.timeOfDay == timeOfDay }
                            if !practicesForTime.isEmpty {
                                Menu {
                                    ForEach(practicesForTime) { practice in
                                        Button {
                                            viewModel.addSelfCare(practice)
                                        } label: {
                                            Text(practice.name ?? "Unknown")
                                        }
                                    }
                                } label: {
                                    Label(timeOfDay.displayName, systemImage: timeOfDay.icon)
                                }
                            }
                        }
                    } label: {
                        Label("Log Practice", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    .padding(.top, viewModel.loggedSelfCare.isEmpty ? 0 : 8)
                }
            }
        } footer: {
            Text("\(viewModel.selfCareSummary)")
        }
    }

    @ViewBuilder
    private func selfCareRow(_ entry: SelfCareLogEntry) -> some View {
        let practice = viewModel.userSelfCare.first { $0.id == entry.userSelfCareId }
        let practiceName = practice?.name ?? "Unknown"

        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            HStack(spacing: 8) {
                Image(systemName: entry.timeOfDay.icon)
                    .foregroundStyle(entry.timeOfDay.color)
                Text(practiceName)
                    .font(.subheadline)
            }

            Spacer()

            Text(timeFormatter.string(from: entry.timestamp))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.removeSelfCare(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                viewModel.selfCareToEditTime = entry
                viewModel.editSelfCareTime = entry.timestamp
            } label: {
                Label("Edit Time", systemImage: "clock")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    private var emptySelfCareView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No self-care practices in your library")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NavigationLink {
                SelfCareManagementView()
            } label: {
                Label("Add Practices in Settings", systemImage: "gear")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    NavigationStack {
        WellnessStep(viewModel: StepperEntryViewModel())
    }
}

import SwiftUI

struct CoreFeelingsStep: View {
    @Bindable var viewModel: StepperEntryViewModel
    @FocusState private var focusedField: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mood Section
                StepSectionCard(title: "Mood", icon: "face.smiling", color: .blue) {
                    Picker("Mood Level", selection: $viewModel.moodLevel) {
                        Text("Not Set").tag(nil as MoodLevel?)
                        ForEach(MoodLevel.allCases, id: \.self) { level in
                            Text("\(level.emoji) \(level.displayName)").tag(level as MoodLevel?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Emotions Section
                StepSectionCard(title: "Feelings", icon: "heart.circle", color: .pink) {
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.selectedEmotions.isEmpty {
                            Text("Tap to select emotions")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(emotionsSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        EmotionCloudSelector(selectedEmotions: $viewModel.selectedEmotions)
                    }
                } footer: {
                    Text("Select all emotions that describe how you felt today")
                }

                // Anxiety Section
                StepSectionCard(title: "Anxiety", icon: "waveform.path.ecg", color: .orange) {
                    Picker("Anxiety Level", selection: $viewModel.anxietyLevel) {
                        Text("Not Set").tag(nil as AnxietyLevel?)
                        ForEach(AnxietyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as AnxietyLevel?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Anhedonia Section
                StepSectionCard(title: "Anhedonia", icon: "sparkle", color: .purple) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Anhedonia Level", selection: $viewModel.anhedoniaLevel) {
                            Text("Not Set").tag(nil as AnhedoniaLevel?)
                            ForEach(AnhedoniaLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level as AnhedoniaLevel?)
                            }
                        }
                        .pickerStyle(.menu)

                        if let anhedonia = viewModel.anhedoniaLevel {
                            Text(anhedonia.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var emotionsSummary: String {
        let names = viewModel.selectedEmotions.map { $0.displayName }.sorted()
        if names.count <= 3 {
            return names.joined(separator: ", ")
        }
        return "\(names.prefix(2).joined(separator: ", ")) +\(names.count - 2)"
    }
}

// MARK: - Step Section Card

struct StepSectionCard<Content: View, Footer: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    init(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            content

            footer
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CoreFeelingsStep(viewModel: StepperEntryViewModel())
}

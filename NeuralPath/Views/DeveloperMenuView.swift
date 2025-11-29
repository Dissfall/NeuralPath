import SwiftUI
import SwiftData

struct DeveloperMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDays = 30
    @State private var selectedPattern = TestDataGenerator.DataPattern.variable
    @State private var includeMedications = true
    @State private var includeSubstances = true
    @State private var includeSleep = true
    @State private var includeExercise = true
    @State private var includeDaylight = true

    @State private var isGenerating = false
    @State private var showClearConfirmation = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    @State private var whatsNewReset = false
    @State private var onboardingReset = false

    private let quickDayOptions = [7, 30, 90]

    var body: some View {
        NavigationStack {
            Form {
                // Header with warning
                Section {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Developer Tools")
                                .font(.headline)
                            Text("Test data generation for development")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Quick Generate Section
                Section("Quick Generate") {
                    HStack {
                        ForEach(quickDayOptions, id: \.self) { days in
                            Button {
                                selectedDays = days
                            } label: {
                                Text("\(days) Days")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedDays == days ? .blue : .gray)
                        }
                    }

                    // Custom day selector
                    Stepper("Days: \(selectedDays)", value: $selectedDays, in: 1...365)
                }

                // Pattern Selection
                Section("Data Pattern") {
                    Picker("Pattern", selection: $selectedPattern) {
                        Label("Improving", systemImage: "arrow.up.right")
                            .tag(TestDataGenerator.DataPattern.improving)
                        Label("Worsening", systemImage: "arrow.down.right")
                            .tag(TestDataGenerator.DataPattern.worsening)
                        Label("Stable", systemImage: "arrow.right")
                            .tag(TestDataGenerator.DataPattern.stable)
                        Label("Variable", systemImage: "waveform")
                            .tag(TestDataGenerator.DataPattern.variable)
                    }
                    .pickerStyle(.segmented)

                    Text(patternDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Data to Include
                Section("Include Data") {
                    Toggle(isOn: $includeMedications) {
                        Label("Medications (2 test meds)", systemImage: "pills.fill")
                    }

                    Toggle(isOn: $includeSubstances) {
                        Label("Substances (Coffee, Alcohol)", systemImage: "drop.triangle.fill")
                    }

                    Toggle(isOn: $includeSleep) {
                        Label("Sleep Data (5-9 hours)", systemImage: "moon.zzz.fill")
                    }

                    Toggle(isOn: $includeExercise) {
                        Label("Exercise (0-60 min)", systemImage: "figure.run")
                    }

                    Toggle(isOn: $includeDaylight) {
                        Label("Daylight (15-90 min)", systemImage: "sun.max.fill")
                    }
                }

                // Generate Button
                Section {
                    Button {
                        generateTestData()
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Generate Test Data")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating || !hasSelectedData)

                    if isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating \(selectedDays) days of data...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // UI Debug
                Section("UI Debug") {
                    Button {
                        let manager = OnboardingManager()
                        manager.resetOnboarding()
                        onboardingReset = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Reset Onboarding")
                            Spacer()
                            if onboardingReset {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    Button {
                        let manager = WhatsNewManager()
                        manager.resetWhatsNew()
                        whatsNewReset = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Reset What's New Popup")
                            Spacer()
                            if whatsNewReset {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear All Test Data")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } header: {
                    Label("Danger Zone", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Developer Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear Test Data?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearTestData()
                }
            } message: {
                Text("This will delete all entries marked as test data, including [TEST] medications and substances.")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var patternDescription: String {
        switch selectedPattern {
        case .improving:
            return "Symptoms gradually improve over time (medication working)"
        case .worsening:
            return "Symptoms gradually worsen (need adjustment)"
        case .stable:
            return "Symptoms remain relatively constant"
        case .variable:
            return "Realistic daily variations with weekly patterns"
        }
    }

    private var hasSelectedData: Bool {
        includeMedications || includeSubstances || includeSleep || includeExercise || includeDaylight
    }

    private func generateTestData() {
        Task {
            isGenerating = true

            let generator = TestDataGenerator(modelContext: modelContext)
            let options = TestDataGenerator.GenerationOptions(
                numberOfDays: selectedDays,
                pattern: selectedPattern,
                includeMedications: includeMedications,
                includeSubstances: includeSubstances,
                includeSleep: includeSleep,
                includeExercise: includeExercise,
                includeDaylight: includeDaylight
            )

            do {
                try await generator.generateTestData(options: options)

                await MainActor.run {
                    alertMessage = "Successfully generated \(selectedDays) days of test data!"
                    showSuccessAlert = true
                    isGenerating = false

                    // Haptic feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to generate test data: \(error.localizedDescription)"
                    showSuccessAlert = true
                    isGenerating = false

                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }

    private func clearTestData() {
        Task {
            let generator = TestDataGenerator(modelContext: modelContext)

            do {
                try await generator.clearAllTestData()

                await MainActor.run {
                    alertMessage = "All test data has been cleared!"
                    showSuccessAlert = true

                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to clear test data: \(error.localizedDescription)"
                    showSuccessAlert = true

                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    DeveloperMenuView()
        .modelContainer(for: SymptomEntry.self, inMemory: true)
}
#endif
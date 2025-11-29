//
//  OnboardingView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData
import HealthKit
import Combine
import UserNotifications

// MARK: - Onboarding Manager

@MainActor
class OnboardingManager: ObservableObject {
    @Published var shouldShowOnboarding = false

    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    func checkOnboardingStatus() {
        shouldShowOnboarding = !hasCompletedOnboarding
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        shouldShowOnboarding = false
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case healthKit = 1
    case medications = 2
    case substances = 3
    case reminders = 4
    case howToUse = 5
    case complete = 6

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .healthKit: return "Apple Health"
        case .medications: return "Medications"
        case .substances: return "Substances"
        case .reminders: return "Reminders"
        case .howToUse: return "How to Use"
        case .complete: return "All Set!"
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    @State private var currentStep: OnboardingStep = .welcome
    @State private var healthKitAuthorized = false

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            OnboardingProgressBar(
                currentStep: currentStep.rawValue,
                totalSteps: OnboardingStep.allCases.count
            )
            .padding(.top, 16)
            .padding(.horizontal, 32)

            // Content
            TabView(selection: $currentStep) {
                OnboardingWelcomeStep(onContinue: { nextStep() })
                    .tag(OnboardingStep.welcome)

                OnboardingHealthKitStep(
                    isAuthorized: $healthKitAuthorized,
                    healthKitManager: healthKitManager,
                    onContinue: { nextStep() },
                    onSkip: { nextStep() }
                )
                .tag(OnboardingStep.healthKit)

                OnboardingMedicationsStep(
                    onContinue: { nextStep() },
                    onSkip: { nextStep() }
                )
                .tag(OnboardingStep.medications)

                OnboardingSubstancesStep(
                    onContinue: { nextStep() },
                    onSkip: { nextStep() }
                )
                .tag(OnboardingStep.substances)

                OnboardingRemindersStep(
                    onContinue: { nextStep() },
                    onSkip: { nextStep() }
                )
                .tag(OnboardingStep.reminders)

                OnboardingHowToUseStep(onContinue: { nextStep() })
                    .tag(OnboardingStep.howToUse)

                OnboardingCompleteStep(onFinish: onComplete)
                    .tag(OnboardingStep.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
    }

    private func nextStep() {
        withAnimation {
            if let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextIndex
            }
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Welcome Step

struct OnboardingWelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                VStack(spacing: 12) {
                    Text("Welcome to NeuralPath")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Track your mental health journey with mood, sleep, medications, and more.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Let's get you set up in just a few steps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - HealthKit Step

struct OnboardingHealthKitStep: View {
    @Binding var isAuthorized: Bool
    let healthKitManager: HealthKitManager
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)

                VStack(spacing: 12) {
                    Text("Connect Apple Health")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Automatically import sleep data and sync your health information.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Benefits list
                VStack(alignment: .leading, spacing: 12) {
                    HealthKitBenefitRow(icon: "moon.zzz.fill", color: .purple, text: "Auto-import sleep data")
                    HealthKitBenefitRow(icon: "figure.run", color: .green, text: "Track exercise minutes")
                    HealthKitBenefitRow(icon: "pills.fill", color: .blue, text: "View medication history")
                }
                .padding(.top, 8)
            }

            Spacer()

            VStack(spacing: 12) {
                if isAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to Apple Health")
                            .foregroundStyle(.green)
                    }
                    .padding(.bottom, 8)
                }

                Button(action: {
                    if isAuthorized {
                        onContinue()
                    } else {
                        requestHealthKit()
                    }
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isAuthorized ? "Continue" : "Connect Apple Health")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isRequesting)

                if !isAuthorized {
                    Button("Skip for Now", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private func requestHealthKit() {
        isRequesting = true
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                await MainActor.run {
                    isAuthorized = true
                    isRequesting = false
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                }
            }
        }
    }
}

struct HealthKitBenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Medications Step

struct OnboardingMedicationsStep: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserMedication> { $0.isActive == true },
           sort: \UserMedication.name) private var medications: [UserMedication]

    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var showingAddMedication = false
    @State private var showingHealthKitImport = false

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("Add Your Medications")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Track daily medications and as-needed doses.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 40)

            // Medications list
            if medications.isEmpty {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "pills")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text("No medications added yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            } else {
                List {
                    ForEach(medications) { medication in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(medication.name ?? "Unknown")
                                    .font(.headline)
                                if let dosage = medication.dosage, !dosage.isEmpty {
                                    Text(dosage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let frequency = medication.frequency {
                                Text(frequency.shortName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .onDelete(perform: deleteMedications)
                }
                .listStyle(.inset)
            }

            // Action buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Label("Add Manually", systemImage: "plus")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    if healthKitManager.isAuthorized {
                        Button {
                            showingHealthKitImport = true
                        } label: {
                            Label("Import", systemImage: "heart.text.square")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button(action: onContinue) {
                    Text(medications.isEmpty ? "Skip" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(medications.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(medications.isEmpty ? .primary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingAddMedication) {
            AddUserMedicationView()
        }
        .sheet(isPresented: $showingHealthKitImport) {
            HealthKitImportView(onImport: importMedications)
        }
    }

    private func deleteMedications(at offsets: IndexSet) {
        for index in offsets {
            medications[index].isActive = false
        }
    }

    private func importMedications(_ selectedMedications: [HKUserAnnotatedMedication]) {
        for hkMed in selectedMedications {
            let userMed = UserMedication(
                name: hkMed.medication.displayText,
                dosage: "",
                category: nil,
                frequency: .onceDaily,
                notes: "Imported from HealthKit"
            )
            modelContext.insert(userMed)
        }
        showingHealthKitImport = false
    }
}

// MARK: - Substances Step

struct OnboardingSubstancesStep: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserSubstance> { $0.isActive == true },
           sort: \UserSubstance.name) private var substances: [UserSubstance]

    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var showingAddSubstance = false

    // Common substances for quick add
    private let commonSubstances: [(name: String, unit: SubstanceUnit, icon: String)] = [
        ("Coffee", .cups, "cup.and.saucer.fill"),
        ("Alcohol", .drinks, "wineglass.fill"),
        ("Water", .milliliters, "drop.fill"),
        ("Tea", .cups, "leaf.fill"),
        ("Energy Drink", .milliliters, "bolt.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "drop.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)

                VStack(spacing: 8) {
                    Text("Track Substances")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Monitor caffeine, alcohol, and other substances that affect your wellbeing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.top, 40)

            // Quick add common substances
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Add")
                    .font(.headline)
                    .padding(.horizontal, 32)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(commonSubstances, id: \.name) { substance in
                            let isAdded = substances.contains { $0.name == substance.name }

                            Button {
                                if !isAdded {
                                    addSubstance(name: substance.name, unit: substance.unit)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: substance.icon)
                                    Text(substance.name)
                                    if isAdded {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(isAdded ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                                .foregroundStyle(isAdded ? .green : .primary)
                                .clipShape(Capsule())
                            }
                            .disabled(isAdded)
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.top, 24)

            // Current substances list
            if !substances.isEmpty {
                List {
                    ForEach(substances) { substance in
                        HStack {
                            Text(substance.name ?? "Unknown")
                                .font(.headline)
                            Spacer()
                            if let unit = substance.defaultUnit {
                                Text(unit.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteSubstances)
                }
                .listStyle(.inset)
            } else {
                Spacer()
            }

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    showingAddSubstance = true
                } label: {
                    Label("Add Custom Substance", systemImage: "plus")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button(action: onContinue) {
                    Text(substances.isEmpty ? "Skip" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(substances.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(substances.isEmpty ? .primary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingAddSubstance) {
            AddUserSubstanceView()
        }
    }

    private func addSubstance(name: String, unit: SubstanceUnit) {
        let substance = UserSubstance(
            name: name,
            defaultUnit: unit,
            notes: nil
        )
        modelContext.insert(substance)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deleteSubstances(at offsets: IndexSet) {
        for index in offsets {
            substances[index].isActive = false
        }
    }
}

// MARK: - Reminders Step

struct OnboardingRemindersStep: View {
    @Query(filter: #Predicate<UserMedication> { $0.isActive == true && $0.reminderEnabled == true })
    private var medicationsWithReminders: [UserMedication]

    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var dailyReminderEnabled = false
    @State private var dailyReminderTime: Date
    @State private var medicationReminderEnabled = false
    @State private var notificationPermissionGranted = false
    @State private var isRequestingPermission = false

    private let dailyReminderEnabledKey = "dailyReminderEnabled"
    private let dailyReminderTimeKey = "dailyReminderTime"
    private let medicationReminderEnabledKey = "medicationReminderEnabled"

    init(onContinue: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onSkip = onSkip

        // Default to 9 PM for daily reminder
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21
        components.minute = 0
        _dailyReminderTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                VStack(spacing: 8) {
                    Text("Set Up Reminders")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Stay on track with daily notifications for logging and medications.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.top, 40)

            // Reminder options
            VStack(spacing: 16) {
                // Daily Entry Reminder
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Entry Reminder")
                                .font(.headline)
                            Text("Get reminded to log your mood and symptoms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $dailyReminderEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if dailyReminderEnabled {
                        HStack {
                            Text("Reminder Time")
                                .font(.subheadline)
                            Spacer()
                            DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("We recommend evening time to reflect on your whole day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                }

                // Medication Reminder
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "pills.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Medication Reminders")
                                .font(.headline)
                            Text("Get reminded at times set for each medication")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $medicationReminderEnabled)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if medicationReminderEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text(medicationsWithReminders.isEmpty
                                 ? "Set reminder times when editing each medication"
                                 : "\(medicationsWithReminders.count) medication(s) have reminders configured")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    saveRemindersAndContinue()
                }) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(hasAnyReminderEnabled ? "Enable Reminders" : "Continue")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isRequestingPermission)

                if hasAnyReminderEnabled {
                    Button("Skip for Now", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    private var hasAnyReminderEnabled: Bool {
        dailyReminderEnabled || medicationReminderEnabled
    }

    private func saveRemindersAndContinue() {
        guard hasAnyReminderEnabled else {
            onContinue()
            return
        }

        isRequestingPermission = true

        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

                await MainActor.run {
                    isRequestingPermission = false

                    if granted {
                        // Save daily reminder settings
                        UserDefaults.standard.set(dailyReminderEnabled, forKey: dailyReminderEnabledKey)
                        UserDefaults.standard.set(dailyReminderTime, forKey: dailyReminderTimeKey)

                        if dailyReminderEnabled {
                            scheduleDailyReminder()
                        }

                        // Save medication reminder settings
                        UserDefaults.standard.set(medicationReminderEnabled, forKey: medicationReminderEnabledKey)

                        if medicationReminderEnabled {
                            MedicationReminderService.shared.scheduleMedicationRemindersFromContext()
                        }
                    }

                    onContinue()
                }
            } catch {
                await MainActor.run {
                    isRequestingPermission = false
                    onContinue()
                }
            }
        }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyEntryReminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Check In"
        content.body = "How are you feeling today? Take a moment to log your mood and symptoms."
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dailyReminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyEntryReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error)")
            }
        }
    }
}

// MARK: - How To Use Step

struct OnboardingHowToUseStep: View {
    let onContinue: () -> Void

    @State private var currentPage = 0

    private let tutorials: [(icon: String, color: Color, title: String, description: String)] = [
        (
            "calendar",
            .blue,
            "Today View",
            "Your daily dashboard. Tap circles to mark medications as taken. Swipe left on items to edit time, amount, or delete."
        ),
        (
            "hand.tap",
            .green,
            "Quick Logging",
            "Tap 'Take As-Needed' to log PRN medications. Tap 'Log Substance' to track substances with custom amounts."
        ),
        (
            "square.and.pencil",
            .orange,
            "Daily Entries",
            "Tap the + button to log your mood, anxiety, sleep, and other daily metrics. Try to log at the same time each day."
        ),
        (
            "chart.xyaxis.line",
            .purple,
            "Charts & Trends",
            "View your progress over time in the Charts tab. Spot patterns between sleep, mood, and medications."
        ),
        (
            "brain",
            .pink,
            "AI Analysis",
            "The Analysis tab provides insights about your patterns and correlations to help you understand your mental health."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("How to Use NeuralPath")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
            }

            // Tutorial cards carousel
            TabView(selection: $currentPage) {
                ForEach(0..<tutorials.count, id: \.self) { index in
                    TutorialCard(
                        icon: tutorials[index].icon,
                        color: tutorials[index].color,
                        title: tutorials[index].title,
                        description: tutorials[index].description
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: 350)

            Spacer()

            // Navigation
            VStack(spacing: 16) {
                // Page indicator text
                Text("\(currentPage + 1) of \(tutorials.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: {
                    if currentPage < tutorials.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onContinue()
                    }
                }) {
                    Text(currentPage < tutorials.count - 1 ? "Next" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if currentPage < tutorials.count - 1 {
                    Button("Skip Tutorial", action: onContinue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

struct TutorialCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(color)
                .frame(width: 100, height: 100)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Complete Step

struct OnboardingCompleteStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                VStack(spacing: 12) {
                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Start tracking your mental health journey. Remember, consistency is key.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    TipRow(icon: "calendar", text: "Log daily for best insights")
                    TipRow(icon: "chart.xyaxis.line", text: "View trends in the Charts tab")
                    TipRow(icon: "brain", text: "Get AI analysis of your patterns")
                }
                .padding(.top, 16)
            }

            Spacer()

            Button(action: onFinish) {
                Text("Start Tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [UserMedication.self, UserSubstance.self], inMemory: true)
}

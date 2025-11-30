import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var dailyReminderEnabled = false
    @State private var dailyReminderTime = Date()
    @State private var medicationReminderEnabled = false
    @State private var healthKitAuthorized = false
    @State private var showingExport = false
    @State private var showingDonation = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false

    // Developer menu states
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    @State private var showDeveloperMenu = false

    private let healthKitManager = HealthKitManager.shared

    // UserDefaults keys for reminders
    private let dailyReminderEnabledKey = "dailyReminderEnabled"
    private let dailyReminderTimeKey = "dailyReminderTime"
    private let medicationReminderEnabledKey = "medicationReminderEnabled"

    var body: some View {
        NavigationStack {
            Form {
                // Daily Entry Reminder
                Section {
                    Toggle("Daily Entry Reminder", isOn: $dailyReminderEnabled)
                        .onChange(of: dailyReminderEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission {
                                    scheduleDailyReminder()
                                    saveDailyReminderSettings()
                                }
                            } else {
                                cancelDailyReminder()
                                saveDailyReminderSettings()
                            }
                        }

                    if dailyReminderEnabled {
                        DatePicker("Reminder Time", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: dailyReminderTime) { _, _ in
                                scheduleDailyReminder()
                                saveDailyReminderSettings()
                            }
                    }
                } header: {
                    Label("Daily Entry", systemImage: "square.and.pencil")
                } footer: {
                    Text("Get reminded to log your mood and symptoms. We recommend setting this to the evening so you can reflect on your entire day.")
                }

                // Medication Reminder
                Section {
                    Toggle("Medication Reminders", isOn: $medicationReminderEnabled)
                        .onChange(of: medicationReminderEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission {
                                    MedicationReminderService.shared.scheduleMedicationRemindersFromContext()
                                    saveMedicationReminderSettings()
                                }
                            } else {
                                MedicationReminderService.shared.cancelAllMedicationReminders()
                                saveMedicationReminderSettings()
                            }
                        }

                    NavigationLink {
                        MedicationManagementView()
                    } label: {
                        HStack {
                            Text("Configure Times")
                            Spacer()
                            Text("Per medication")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Label("Medications", systemImage: "pills.fill")
                } footer: {
                    Text("Enable reminders and set individual times for each medication in Manage Medications.")
                }

                Section {
                    NavigationLink {
                        MedicationManagementView()
                    } label: {
                        Label("Manage Medications", systemImage: "pills.fill")
                    }

                    NavigationLink {
                        SubstanceManagementView()
                    } label: {
                        Label("Manage Substances", systemImage: "drop.triangle.fill")
                    }

                    NavigationLink {
                        MindfulnessManagementView()
                    } label: {
                        Label("Manage Mindfulness", systemImage: "brain.head.profile")
                    }

                    NavigationLink {
                        SelfCareManagementView()
                    } label: {
                        Label("Manage Self-Care", systemImage: "sparkles")
                    }
                } header: {
                    Text("Tracking")
                } footer: {
                    Text("Manage your medications, substances, mindfulness, and self-care practices for easy tracking")
                }

                // CloudKit sync status
                CloudKitStatusView()

                Section {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("Apple Health")
                        Spacer()
                        if healthKitAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("Connect") {
                                Task {
                                    await requestHealthKitAuthorization()
                                }
                            }
                        }
                    }
                } header: {
                    Text("Integrations")
                } footer: {
                    Text("Connect with Apple Health to automatically import sleep data, medications, exercise minutes and other")
                }

                // ML Analysis Section
                MLSettingsSection()

                // Language Section
                LanguageSettingsSection()

                Section {
                    Button {
                        showingExport = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        if isDeleting {
                            HStack {
                                Label("Deleting...", systemImage: "trash")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Label("Delete All Data", systemImage: "trash")
                        }
                    }
                    .disabled(isDeleting)
                } header: {
                    Text("Data")
                }

                // Support Development
                Section {
                    Button {
                        showingDonation = true
                    } label: {
                        HStack {
                            Label("Support Development", systemImage: "heart.fill")
                                .foregroundStyle(.pink)
                            Spacer()
                            if StoreKitManager.shared.hasActiveSubscription {
                                Text("Subscribed")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    if StoreKitManager.shared.hasActiveSubscription {
                        Button {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Manage Subscription", systemImage: "creditcard")
                        }
                    }

                    Button {
                        Task {
                            await StoreKitManager.shared.restorePurchases()
                        }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("Support")
                } footer: {
                    Text("Your support helps keep the app free and funds new features")
                }

                Section {
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }

                    Link(destination: URL(string: "https://github.com/Dissfall/NeuralPath/issues/new?labels=bug")!) {
                        Label("Report a Bug", systemImage: "ant.fill")
                    }

                    Link(destination: URL(string: "https://github.com/Dissfall/NeuralPath/issues/new?labels=enhancement")!) {
                        Label("Suggest a Feature", systemImage: "lightbulb.fill")
                    }

                    Link(destination: URL(string: "mailto:heorhi@lukyanau.me")!) {
                        Label("Share Feedback", systemImage: "envelope.fill")
                    }
                } header: {
                    Text("About")
                }

                // Version section with hidden developer menu trigger
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                #if DEBUG
                                handleVersionTap()
                                #endif
                            }
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.appBuild)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportView()
            }
            .sheet(isPresented: $showingDonation) {
                DonationView(
                    onDismiss: { showingDonation = false },
                    onNeverShow: { showingDonation = false }
                )
            }
            .confirmationDialog(
                "Delete All Data",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    Task {
                        await deleteAllData()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your entries, medications, substances, mindfulness practices, and self-care routines from this device and iCloud. This cannot be undone.")
            }
            #if DEBUG
            .sheet(isPresented: $showDeveloperMenu) {
                DeveloperMenuView()
            }
            #endif
            .task {
                await checkPermissions()
            }
        }
    }

    private func checkPermissions() async {
        healthKitAuthorized = healthKitManager.isAuthorized
        loadReminderSettings()
    }

    private func loadReminderSettings() {
        dailyReminderEnabled = UserDefaults.standard.bool(forKey: dailyReminderEnabledKey)
        medicationReminderEnabled = UserDefaults.standard.bool(forKey: medicationReminderEnabledKey)

        if let dailyTime = UserDefaults.standard.object(forKey: dailyReminderTimeKey) as? Date {
            dailyReminderTime = dailyTime
        } else {
            // Default to 9 PM for daily entry
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 21
            components.minute = 0
            dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    private func saveDailyReminderSettings() {
        UserDefaults.standard.set(dailyReminderEnabled, forKey: dailyReminderEnabledKey)
        UserDefaults.standard.set(dailyReminderTime, forKey: dailyReminderTimeKey)
    }

    private func saveMedicationReminderSettings() {
        UserDefaults.standard.set(medicationReminderEnabled, forKey: medicationReminderEnabledKey)
    }

    private func requestNotificationPermission(onSuccess: @escaping () -> Void) {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    await MainActor.run {
                        onSuccess()
                    }
                }
            } catch {
                print("Failed to request notification permission: \(error)")
            }
        }
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyEntryReminder"])

        guard dailyReminderEnabled else { return }

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

    private func cancelDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyEntryReminder"])
    }

    private func requestHealthKitAuthorization() async {
        do {
            try await healthKitManager.requestAuthorization()
            healthKitAuthorized = true
        } catch {
            print("Failed to authorize HealthKit: \(error)")
        }
    }

    private func deleteAllData() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await CloudKitManager.shared.deleteAllData(modelContext: modelContext)
        } catch {
            print("Failed to delete data: \(error)")
        }
    }

    #if DEBUG
    private func handleVersionTap() {
        let now = Date()

        // Reset counter if more than 1 second has passed since last tap
        if now.timeIntervalSince(lastTapTime) > 1.0 {
            tapCount = 0
        }

        tapCount += 1
        lastTapTime = now

        // Show developer menu after 10 taps
        if tapCount >= 10 {
            showDeveloperMenu = true
            tapCount = 0

            // Haptic feedback to confirm
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else if tapCount == 5 {
            // Light feedback at halfway point
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    #endif
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

// MARK: - ML Settings Section

struct MLSettingsSection: View {
    private var modelManager: MLModelManager { MLModelManager.shared }

    var body: some View {
        Section {
            Toggle(isOn: Binding(
                get: { modelManager.isMLEnabled },
                set: { modelManager.isMLEnabled = $0 }
            )) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(.purple)
                    Text("AI Analysis")
                }
            }

            if modelManager.isMLEnabled {
                HStack {
                    Text("Status")
                    Spacer()
                    MLStatusIndicator(state: modelManager.overallState)
                }

                HStack {
                    Text("Model Version")
                    Spacer()
                    Text(modelManager.modelVersion)
                        .foregroundStyle(.secondary)
                }

                if let lastTrained = modelManager.lastTrainingDate {
                    HStack {
                        Text("Last Trained")
                        Spacer()
                        Text(lastTrained, format: .relative(presentation: .named))
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    MLInfoView()
                } label: {
                    Label("About AI Analysis", systemImage: "info.circle")
                }
            }
        } header: {
            Label("AI Analysis", systemImage: "brain")
        } footer: {
            if modelManager.isMLEnabled {
                Text("AI analysis uses on-device machine learning to identify patterns and predict mood trends. All processing happens locally on your device.")
            } else {
                Text("Enable AI analysis for mood predictions, pattern detection, and personalized insights. Requires at least 30 entries.")
            }
        }
    }
}

struct MLStatusIndicator: View {
    let state: MLModelManager.ModelState

    var statusColor: Color {
        switch state {
        case .ready: return .green
        case .initializing: return .orange
        case .needsRetraining: return .yellow
        case .notInitialized: return .gray
        case .error: return .red
        }
    }

    var statusText: String {
        switch state {
        case .ready: return "Ready"
        case .initializing: return "Initializing..."
        case .needsRetraining: return "Needs Update"
        case .notInitialized: return "Not Initialized"
        case .error(let message): return "Error: \(message)"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct MLInfoView: View {
    var body: some View {
        List {
            Section {
                Text("NeuralPath uses on-device machine learning to analyze your mental health patterns. All processing happens locally on your device - your data never leaves your phone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Label("How It Works", systemImage: "cpu")
            }

            Section {
                MLFeatureInfoRow(icon: "sun.horizon.fill", title: "Mood Prediction", description: "Predicts tomorrow's mood based on today's factors")
                MLFeatureInfoRow(icon: "waveform.path.ecg", title: "Pattern Detection", description: "Identifies recurring patterns in your data")
                MLFeatureInfoRow(icon: "chart.line.uptrend.xyaxis", title: "7-Day Forecast", description: "Projects your mental health trends")
                MLFeatureInfoRow(icon: "calendar.badge.clock", title: "Similar Days", description: "Finds past days similar to today")
            } header: {
                Label("Features", systemImage: "sparkles")
            }

            Section {
                MLDataRequirementInfoRow(entries: 7, feature: "Basic Statistics")
                MLDataRequirementInfoRow(entries: 30, feature: "ML Predictions")
                MLDataRequirementInfoRow(entries: 90, feature: "Hybrid AI Analysis")
                MLDataRequirementInfoRow(entries: 180, feature: "Personalized AI")
            } header: {
                Label("Data Requirements", systemImage: "chart.bar.doc.horizontal")
            }

            Section {
                Text("Your data stays on your device. ML models are trained locally using Apple's CoreML framework. No data is ever sent to external servers for analysis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Privacy", systemImage: "lock.shield")
            }
        }
        .navigationTitle("AI Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MLFeatureInfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MLDataRequirementInfoRow: View {
    let entries: Int
    let feature: String

    var body: some View {
        HStack {
            Text("\(entries)+ entries")
                .font(.subheadline)
                .foregroundStyle(.purple)
                .frame(width: 100, alignment: .leading)
            Text(feature)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Language Settings Section

struct LanguageSettingsSection: View {
    var languageManager = LanguageManager.shared

    var body: some View {
        Section {
            NavigationLink {
                LanguageSettingsView()
            } label: {
                HStack {
                    Label("Language", systemImage: "globe")
                    Spacer()
                    HStack(spacing: 6) {
                        if languageManager.currentLanguage.isSystemFlag {
                            Image(systemName: languageManager.currentLanguage.flagImageName)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(languageManager.currentLanguage.flagImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 14)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                        Text(languageManager.currentLanguage.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("Language", systemImage: "character.bubble")
        }
    }
}

#Preview {
    SettingsView()
}

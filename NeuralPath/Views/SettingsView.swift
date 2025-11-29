import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dailyReminderEnabled = false
    @State private var dailyReminderTime = Date()
    @State private var medicationReminderEnabled = false
    @State private var healthKitAuthorized = false
    @State private var showingExport = false

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
                } header: {
                    Text("Tracking")
                } footer: {
                    Text("Manage your medications and substances for easy tracking")
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

                Section {
                    Button {
                        showingExport = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Data")
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

#Preview {
    SettingsView()
}

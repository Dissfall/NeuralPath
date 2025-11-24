import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = false
    @State private var reminderTime = Date()
    @State private var healthKitAuthorized = false
    @State private var showingExport = false

    // Developer menu states
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    @State private var showDeveloperMenu = false

    private let healthKitManager = HealthKitManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                cancelNotifications()
                            }
                        }

                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newValue in
                                scheduleNotification(at: newValue)
                            }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get a daily reminder to log your symptoms")
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
                        Text("HealthKit")
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

                    if #available(iOS 16.0, *), healthKitAuthorized {
                        NavigationLink {
                            MedicationHistoryView()
                        } label: {
                            Label("Medication History", systemImage: "pills")
                        }
                    }
                } header: {
                    Text("Integrations")
                } footer: {
                    Text("Connect with HealthKit to automatically import sleep data and view medication adherence from the Health app")
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
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        notificationsEnabled = settings.authorizationStatus == .authorized

        healthKitAuthorized = healthKitManager.isAuthorized
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                try await center.requestAuthorization(options: [.alert, .sound, .badge])
                scheduleNotification(at: reminderTime)
            } catch {
                print("Failed to request notification permission: \(error)")
                notificationsEnabled = false
            }
        }
    }

    private func scheduleNotification(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Time to Check In"
        content.body = "How are you feeling today? Take a moment to log your symptoms."
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func cancelNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
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

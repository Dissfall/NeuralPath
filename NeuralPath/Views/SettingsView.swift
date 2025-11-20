import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = false
    @State private var reminderTime = Date()
    @State private var healthKitAuthorized = false
    @State private var showingExport = false

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
}

#Preview {
    SettingsView()
}

//
//  SelfCareManagementView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct SelfCareManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserSelfCare> { $0.isActive == true }, sort: \UserSelfCare.name) private var practices: [UserSelfCare]

    @State private var showingAddSheet = false

    // Reminder states
    @State private var morningReminderEnabled = false
    @State private var afternoonReminderEnabled = false
    @State private var eveningReminderEnabled = false
    @State private var morningReminderTime = SelfCareReminderService.defaultReminderTime(for: .morning)
    @State private var afternoonReminderTime = SelfCareReminderService.defaultReminderTime(for: .afternoon)
    @State private var eveningReminderTime = SelfCareReminderService.defaultReminderTime(for: .evening)

    private var morningPractices: [UserSelfCare] {
        practices.filter { $0.timeOfDay == .morning }
    }

    private var afternoonPractices: [UserSelfCare] {
        practices.filter { $0.timeOfDay == .afternoon }
    }

    private var eveningPractices: [UserSelfCare] {
        practices.filter { $0.timeOfDay == .evening }
    }

    var body: some View {
        List {
            if practices.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Self-Care Practices",
                        systemImage: "sparkles",
                        description: Text("Add self-care practices to build healthy daily routines")
                    )
                }
            } else {
                // Morning practices
                if !morningPractices.isEmpty {
                    Section {
                        ForEach(morningPractices) { practice in
                            NavigationLink {
                                AddUserSelfCareView(practice: practice)
                            } label: {
                                SelfCareRow(practice: practice)
                            }
                        }
                        .onDelete { offsets in
                            deletePractices(from: morningPractices, at: offsets)
                        }
                    } header: {
                        Label("Morning", systemImage: SelfCareTimeOfDay.morning.icon)
                    }
                }

                // Afternoon practices
                if !afternoonPractices.isEmpty {
                    Section {
                        ForEach(afternoonPractices) { practice in
                            NavigationLink {
                                AddUserSelfCareView(practice: practice)
                            } label: {
                                SelfCareRow(practice: practice)
                            }
                        }
                        .onDelete { offsets in
                            deletePractices(from: afternoonPractices, at: offsets)
                        }
                    } header: {
                        Label("Afternoon", systemImage: SelfCareTimeOfDay.afternoon.icon)
                    }
                }

                // Evening practices
                if !eveningPractices.isEmpty {
                    Section {
                        ForEach(eveningPractices) { practice in
                            NavigationLink {
                                AddUserSelfCareView(practice: practice)
                            } label: {
                                SelfCareRow(practice: practice)
                            }
                        }
                        .onDelete { offsets in
                            deletePractices(from: eveningPractices, at: offsets)
                        }
                    } header: {
                        Label("Evening", systemImage: SelfCareTimeOfDay.evening.icon)
                    }
                }
            }

            // Reminders section
            Section {
                if !morningPractices.isEmpty {
                    Toggle(isOn: $morningReminderEnabled) {
                        Label("Morning Reminder", systemImage: SelfCareTimeOfDay.morning.icon)
                    }
                    .onChange(of: morningReminderEnabled) { _, _ in
                        saveReminderSettings()
                    }

                    if morningReminderEnabled {
                        DatePicker("Time", selection: $morningReminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: morningReminderTime) { _, _ in
                                saveReminderSettings()
                            }
                    }
                }

                if !afternoonPractices.isEmpty {
                    Toggle(isOn: $afternoonReminderEnabled) {
                        Label("Afternoon Reminder", systemImage: SelfCareTimeOfDay.afternoon.icon)
                    }
                    .onChange(of: afternoonReminderEnabled) { _, _ in
                        saveReminderSettings()
                    }

                    if afternoonReminderEnabled {
                        DatePicker("Time", selection: $afternoonReminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: afternoonReminderTime) { _, _ in
                                saveReminderSettings()
                            }
                    }
                }

                if !eveningPractices.isEmpty {
                    Toggle(isOn: $eveningReminderEnabled) {
                        Label("Evening Reminder", systemImage: SelfCareTimeOfDay.evening.icon)
                    }
                    .onChange(of: eveningReminderEnabled) { _, _ in
                        saveReminderSettings()
                    }

                    if eveningReminderEnabled {
                        DatePicker("Time", selection: $eveningReminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: eveningReminderTime) { _, _ in
                                saveReminderSettings()
                            }
                    }
                }
            } header: {
                Label("Reminders", systemImage: "bell.fill")
            } footer: {
                Text("Set reminders for each part of your day")
            }
        }
        .navigationTitle("Manage Self-Care")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddUserSelfCareView()
        }
        .onAppear {
            loadReminderSettings()
        }
    }

    private func deletePractices(from practiceList: [UserSelfCare], at offsets: IndexSet) {
        for index in offsets {
            let practice = practiceList[index]
            practice.isActive = false
        }
    }

    private func loadReminderSettings() {
        morningReminderEnabled = UserDefaults.standard.bool(forKey: SelfCareReminderService.morningReminderEnabledKey)
        afternoonReminderEnabled = UserDefaults.standard.bool(forKey: SelfCareReminderService.afternoonReminderEnabledKey)
        eveningReminderEnabled = UserDefaults.standard.bool(forKey: SelfCareReminderService.eveningReminderEnabledKey)

        if let time = UserDefaults.standard.object(forKey: SelfCareReminderService.morningReminderTimeKey) as? Date {
            morningReminderTime = time
        }
        if let time = UserDefaults.standard.object(forKey: SelfCareReminderService.afternoonReminderTimeKey) as? Date {
            afternoonReminderTime = time
        }
        if let time = UserDefaults.standard.object(forKey: SelfCareReminderService.eveningReminderTimeKey) as? Date {
            eveningReminderTime = time
        }
    }

    private func saveReminderSettings() {
        UserDefaults.standard.set(morningReminderEnabled, forKey: SelfCareReminderService.morningReminderEnabledKey)
        UserDefaults.standard.set(afternoonReminderEnabled, forKey: SelfCareReminderService.afternoonReminderEnabledKey)
        UserDefaults.standard.set(eveningReminderEnabled, forKey: SelfCareReminderService.eveningReminderEnabledKey)
        UserDefaults.standard.set(morningReminderTime, forKey: SelfCareReminderService.morningReminderTimeKey)
        UserDefaults.standard.set(afternoonReminderTime, forKey: SelfCareReminderService.afternoonReminderTimeKey)
        UserDefaults.standard.set(eveningReminderTime, forKey: SelfCareReminderService.eveningReminderTimeKey)

        SelfCareReminderService.shared.scheduleSelfCareReminders(practices: practices)
    }
}

struct SelfCareRow: View {
    let practice: UserSelfCare

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: practice.timeOfDay.icon)
                .font(.title2)
                .foregroundStyle(practice.timeOfDay.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(practice.name ?? "")
                    .font(.headline)

                Text(practice.timeOfDay.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(practice.timeOfDay.color.opacity(0.1))
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SelfCareManagementView()
            .modelContainer(for: UserSelfCare.self)
    }
}

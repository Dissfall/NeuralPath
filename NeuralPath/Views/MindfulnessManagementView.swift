//
//  MindfulnessManagementView.swift
//  NeuralPath
//

import SwiftUI
import SwiftData

struct MindfulnessManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserMindfulness> { $0.isActive == true }, sort: \UserMindfulness.name) private var practices: [UserMindfulness]

    @State private var showingAddSheet = false

    var body: some View {
        List {
            if practices.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Practices",
                        systemImage: "brain.head.profile",
                        description: Text("Add mindfulness practices to track your wellness journey")
                    )
                }
            } else {
                Section {
                    ForEach(practices) { practice in
                        NavigationLink {
                            AddUserMindfulnessView(practice: practice)
                        } label: {
                            MindfulnessRow(practice: practice)
                        }
                    }
                    .onDelete(perform: deletePractices)
                } header: {
                    Text("Active Practices")
                } footer: {
                    if practices.count == 1 {
                        Text("1 active practice")
                    } else {
                        Text("\(practices.count) active practices")
                    }
                }
            }
        }
        .navigationTitle("Manage Mindfulness")
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
            AddUserMindfulnessView()
        }
    }

    private func deletePractices(at offsets: IndexSet) {
        for index in offsets {
            let practice = practices[index]
            practice.isActive = false
        }
    }
}

struct MindfulnessRow: View {
    let practice: UserMindfulness

    private var reminderTimeString: String? {
        guard practice.reminderEnabled == true,
              let time = practice.reminderTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: practice.category?.icon ?? "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(practice.name ?? "")
                    .font(.headline)

                HStack(spacing: 8) {
                    if let duration = practice.durationMinutes, duration > 0 {
                        Text("\(duration) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let category = practice.category {
                        Text(category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(4)
                    }

                    if let timeStr = reminderTimeString {
                        HStack(spacing: 2) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                            Text(timeStr)
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MindfulnessManagementView()
            .modelContainer(for: UserMindfulness.self)
    }
}

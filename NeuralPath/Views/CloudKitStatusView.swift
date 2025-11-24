//
//  CloudKitStatusView.swift
//  NeuralPath
//
//  Shows CloudKit sync status in Settings
//

import SwiftUI

// Only import CloudKit on non-simulator platforms
#if !targetEnvironment(simulator)
import CloudKit
#endif

struct CloudKitStatusView: View {
    @State private var cloudStatus: String = "Checking..."
    @State private var statusColor: Color = .gray
    @State private var statusIcon: String = "icloud"

    var body: some View {
        Section("Sync Status") {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text("iCloud Sync")
                        .font(.headline)
                    Text(cloudStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            checkCloudKitStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitAvailabilityChanged"))) { _ in
            checkCloudKitStatus()
        }
    }

    private func checkCloudKitStatus() {
        #if targetEnvironment(simulator)
            // On simulator, show local-only status
            cloudStatus = "Simulator - Data stored locally only"
            statusColor = .blue
            statusIcon = "icloud.slash"
        #else
            // Only check CloudKit on real devices
            CKContainer.default().accountStatus { status, error in
                DispatchQueue.main.async {
                    switch status {
                    case .available:
                        cloudStatus = "Connected - Data syncing with iCloud"
                        statusColor = .green
                        statusIcon = "icloud.fill"

                    case .noAccount:
                        cloudStatus = "No iCloud account - Data stored locally only"
                        statusColor = .orange
                        statusIcon = "icloud.slash"

                    case .restricted:
                        cloudStatus = "iCloud restricted - Data stored locally only"
                        statusColor = .orange
                        statusIcon = "exclamationmark.icloud"

                    case .couldNotDetermine:
                        cloudStatus = "Unable to determine status - Data stored locally"
                        statusColor = .gray
                        statusIcon = "questionmark.circle"

                    case .temporarilyUnavailable:
                        cloudStatus = "iCloud temporarily unavailable - Will retry"
                        statusColor = .yellow
                        statusIcon = "exclamationmark.triangle"

                    @unknown default:
                        cloudStatus = "Unknown status - Data stored locally"
                        statusColor = .gray
                        statusIcon = "questionmark.circle"
                    }
                }
            }
        #endif
    }
}

#Preview {
    Form {
        CloudKitStatusView()
    }
}
//
//  WhatsNewView.swift
//  NeuralPath
//

import SwiftUI
import Combine

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

struct WhatsNewVersion {
    let version: String
    let features: [WhatsNewFeature]
}

// MARK: - What's New Content

enum WhatsNewContent {
    static let versions: [WhatsNewVersion] = [
        WhatsNewVersion(
            version: "1.1",
            features: [
                WhatsNewFeature(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "Today View",
                    description: "New dashboard showing your daily medications, substances, and entry status at a glance."
                ),
                WhatsNewFeature(
                    icon: "hand.draw",
                    iconColor: .orange,
                    title: "Swipe Actions",
                    description: "Swipe on medications and substances to quickly undo, delete, or adjust time and amount."
                ),
                WhatsNewFeature(
                    icon: "pills",
                    iconColor: .green,
                    title: "PRN Medications",
                    description: "Track as-needed medications separately with support for multiple daily doses."
                ),
                WhatsNewFeature(
                    icon: "clock",
                    iconColor: .purple,
                    title: "Quick Logging",
                    description: "Log medications and substances directly from the Today view with a single tap."
                )
            ]
        )
    ]

    static func features(for version: String) -> [WhatsNewFeature]? {
        versions.first { $0.version == version }?.features
    }

    static var latestVersion: String {
        versions.first?.version ?? "1.0"
    }
}

// MARK: - What's New Manager

@MainActor
class WhatsNewManager: ObservableObject {
    @Published var shouldShowWhatsNew = false
    @Published var currentFeatures: [WhatsNewFeature] = []

    private let lastSeenVersionKey = "lastSeenWhatsNewVersion"

    var lastSeenVersion: String? {
        get { UserDefaults.standard.string(forKey: lastSeenVersionKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastSeenVersionKey) }
    }

    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    func checkForWhatsNew() {
        let lastSeen = lastSeenVersion

        // Find features for versions newer than last seen
        var newFeatures: [WhatsNewFeature] = []

        for versionInfo in WhatsNewContent.versions {
            if let lastSeen = lastSeen {
                if compareVersions(versionInfo.version, isNewerThan: lastSeen) {
                    newFeatures.append(contentsOf: versionInfo.features)
                }
            } else {
                // First launch - show latest version features
                if versionInfo.version == WhatsNewContent.latestVersion {
                    newFeatures = versionInfo.features
                    break
                }
            }
        }

        if !newFeatures.isEmpty {
            currentFeatures = newFeatures
            shouldShowWhatsNew = true
        }
    }

    func markAsSeen() {
        lastSeenVersion = WhatsNewContent.latestVersion
        shouldShowWhatsNew = false
    }

    func resetWhatsNew() {
        lastSeenVersion = nil
    }

    private func compareVersions(_ version1: String, isNewerThan version2: String) -> Bool {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(v1Components.count, v2Components.count)

        for i in 0..<maxLength {
            let v1Part = i < v1Components.count ? v1Components[i] : 0
            let v2Part = i < v2Components.count ? v2Components[i] : 0

            if v1Part > v2Part { return true }
            if v1Part < v2Part { return false }
        }

        return false
    }
}

// MARK: - What's New View

struct WhatsNewView: View {
    let features: [WhatsNewFeature]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What's New")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("in NeuralPath")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // Features list
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(features) { feature in
                        WhatsNewFeatureRow(feature: feature)
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Continue button
            Button(action: onDismiss) {
                Text("Continue")
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
        .background(Color(.systemBackground))
    }
}

struct WhatsNewFeatureRow: View {
    let feature: WhatsNewFeature

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(feature.iconColor)
                .frame(width: 44, height: 44)
                .background(feature.iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    WhatsNewView(
        features: WhatsNewContent.versions.first?.features ?? [],
        onDismiss: {}
    )
}

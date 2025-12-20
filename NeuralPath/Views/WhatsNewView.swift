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
            version: "1.2.0",
            features: [
                WhatsNewFeature(
                    icon: "figure.mind.and.body",
                    iconColor: .teal,
                    title: String(localized: "Guided Practices"),
                    description: String(localized: "New practices screen with guided breathing, grounding, and emotional exercises. Step-by-step instructions with timers and animations.")
                ),
                WhatsNewFeature(
                    icon: "clock.badge.checkmark",
                    iconColor: .orange,
                    title: String(localized: "Simplified Scheduling"),
                    description: String(localized: "Easier activity scheduling — just set morning, afternoon, or evening instead of exact times.")
                ),
                WhatsNewFeature(
                    icon: "timeline.selection",
                    iconColor: .blue,
                    title: String(localized: "Timeline View"),
                    description: String(localized: "Today's view is now a timeline of your day. See medications, practices, and activities in chronological order.")
                ),
            ]
        ),
        WhatsNewVersion(
            version: "1.1.0",
            features: [
                WhatsNewFeature(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "Today View",
                    description: "New dashboard showing your daily medications, substances, and entry status at a glance."
                ),
                WhatsNewFeature(
                    icon: "cpu",
                    iconColor: .purple,
                    title: "AI-Powered Analysis",
                    description: "On-device machine learning predicts tomorrow's mood, detects patterns, and provides personalized insights - all while keeping your data private."
                ),
                WhatsNewFeature(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .blue,
                    title: "7-Day Forecast",
                    description: "See your projected mood trends for the week ahead with confidence intervals."
                ),
                WhatsNewFeature(
                    icon: "brain.head.profile",
                    iconColor: .teal,
                    title: "Mindfulness Tracking",
                    description: "Track meditation, breathing exercises, yoga, journaling, and other wellness practices with daily logging and reminders."
                ),
                WhatsNewFeature(
                    icon: "sparkles",
                    iconColor: .cyan,
                    title: "Self-Care Routines",
                    description: "Build healthy daily habits with morning, afternoon, and evening self-care practices. Set category reminders and celebrate completions."
                ),
                WhatsNewFeature(
                    icon: "cloud.fill",
                    iconColor: .blue,
                    title: "Emotion Cloud",
                    description: "Track your feelings. Select multiple feelings colored by type: positive, negative, or neutral."
                ),
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

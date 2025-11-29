//
//  DonationView.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI
import StoreKit
import Combine

// MARK: - Donation Manager

@MainActor
class DonationManager: ObservableObject {
    @Published var shouldShowDonation = false

    private let sessionCountKey = "appSessionCount"
    private let neverShowKey = "neverShowDonation"
    private let showEveryNSessions = 5

    var sessionCount: Int {
        get { UserDefaults.standard.integer(forKey: sessionCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: sessionCountKey) }
    }

    var neverShowDonation: Bool {
        get { UserDefaults.standard.bool(forKey: neverShowKey) }
        set { UserDefaults.standard.set(newValue, forKey: neverShowKey) }
    }

    func incrementSessionAndCheck() {
        sessionCount += 1
        checkShouldShowDonation()
    }

    func checkShouldShowDonation() {
        guard !neverShowDonation else { return }
        guard !StoreKitManager.shared.hasActiveSubscription else { return }
        guard sessionCount % showEveryNSessions == 0 else { return }
        guard sessionCount > 0 else { return }

        shouldShowDonation = true
    }

    func dismissForNow() {
        shouldShowDonation = false
    }

    func dismissForever() {
        neverShowDonation = true
        shouldShowDonation = false
    }

    func resetDonationPrompt() {
        sessionCount = 0
        neverShowDonation = false
    }
}

// MARK: - Donation View

struct DonationView: View {
    let onDismiss: () -> Void
    let onNeverShow: () -> Void

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var purchaseSuccess = false

    private var storeKit: StoreKitManager { StoreKitManager.shared }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.linearGradient(
                            colors: [.pink, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    VStack(spacing: 8) {
                        Text("Support NeuralPath")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Your donation helps keep the app free and supports ongoing development of new features.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                // Tier selection
                if storeKit.isLoading {
                    Spacer()
                    ProgressView("Loading options...")
                    Spacer()
                } else if storeKit.products.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Unable to load donation options")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await storeKit.loadProducts() }
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(storeKit.products.sorted { $0.price < $1.price }) { product in
                                DonationTierRow(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onSelect: { selectedProduct = product }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        purchase()
                    } label: {
                        HStack(spacing: 8) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Subscribe")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedProduct != nil ? Color.pink : Color.gray.opacity(0.3))
                        .foregroundStyle(selectedProduct != nil ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(selectedProduct == nil || isPurchasing)

                    Button("Maybe Later") {
                        onDismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                    Button("Don't Show Again") {
                        onNeverShow()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Thank You!", isPresented: $purchaseSuccess) {
                Button("OK") {
                    onDismiss()
                }
            } message: {
                Text("Your support means the world to us. Thank you for helping NeuralPath grow!")
            }
        }
    }

    private func purchase() {
        guard let product = selectedProduct else { return }

        isPurchasing = true

        Task {
            do {
                let success = try await storeKit.purchase(product)
                await MainActor.run {
                    isPurchasing = false
                    if success {
                        purchaseSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Donation Tier Row

struct DonationTierRow: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    private var tierEmoji: String {
        switch product.price {
        case 0..<1: return "☕️"
        case 1..<3: return "🍪"
        case 3..<5: return "🧁"
        case 5..<10: return "🍰"
        case 10..<15: return "🎂"
        default: return "🌟"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Text(tierEmoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline)
                    Text("per month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .pink : .secondary)
            }
            .padding()
            .background(isSelected ? Color.pink.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DonationView(
        onDismiss: { },
        onNeverShow: { }
    )
}

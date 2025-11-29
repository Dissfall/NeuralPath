//
//  StoreKitManager.swift
//  NeuralPath
//
//  Created by Claude Code
//

import Foundation
import StoreKit

@MainActor
@Observable
class StoreKitManager {
    static let shared = StoreKitManager()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false

    private var updateListenerTask: Task<Void, Error>?

    static let donationProductIDs = [
        "com.geometryrain.neuralpath.donation.tier1",
        "com.geometryrain.neuralpath.donation.tier2",
        "com.geometryrain.neuralpath.donation.tier3",
        "com.geometryrain.neuralpath.donation.tier4",
        "com.geometryrain.neuralpath.donation.tier5",
        "com.geometryrain.neuralpath.donation.tier6"
    ]

    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    func cleanup() {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.donationProductIDs)
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            isLoading = false
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                purchasedIDs.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchasedIDs
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreKitError: LocalizedError {
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}

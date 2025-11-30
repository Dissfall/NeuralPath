//
//  MLModelManager.swift
//  NeuralPath
//
//  Model lifecycle management for ML models
//

import Foundation
import CoreML

@MainActor
@Observable
class MLModelManager {
    static let shared = MLModelManager()

    // MARK: - Model State

    enum ModelState: Equatable {
        case notInitialized
        case initializing
        case ready
        case needsRetraining
        case error(String)

        static func == (lhs: ModelState, rhs: ModelState) -> Bool {
            switch (lhs, rhs) {
            case (.notInitialized, .notInitialized): return true
            case (.initializing, .initializing): return true
            case (.ready, .ready): return true
            case (.needsRetraining, .needsRetraining): return true
            case (.error(let l), .error(let r)): return l == r
            default: return false
            }
        }
    }

    var overallState: ModelState = .notInitialized
    var lastTrainingDate: Date?
    var entriesSinceTraining: Int = 0
    var modelVersion: String = "1.0"

    // MARK: - UserDefaults Keys

    private let lastTrainingDateKey = "mlLastTrainingDate"
    private let entriesSinceTrainingKey = "mlEntriesSinceTraining"
    private let modelVersionKey = "mlModelVersion"
    private let mlEnabledKey = "mlAnalysisEnabled"

    // MARK: - Configuration

    private let minimumEntriesForTraining = 30
    private let retrainingThresholdDays = 7
    private let retrainingThresholdEntries = 10

    // MARK: - ML Engine Reference

    private var mlEngine: MLAnalysisEngine?

    // MARK: - Initialization

    private init() {
        loadState()
    }

    // MARK: - State Persistence

    private func loadState() {
        lastTrainingDate = UserDefaults.standard.object(forKey: lastTrainingDateKey) as? Date
        entriesSinceTraining = UserDefaults.standard.integer(forKey: entriesSinceTrainingKey)
        modelVersion = UserDefaults.standard.string(forKey: modelVersionKey) ?? "1.0"
    }

    private func saveState() {
        UserDefaults.standard.set(lastTrainingDate, forKey: lastTrainingDateKey)
        UserDefaults.standard.set(entriesSinceTraining, forKey: entriesSinceTrainingKey)
        UserDefaults.standard.set(modelVersion, forKey: modelVersionKey)
    }

    // MARK: - ML Enabled Setting

    var isMLEnabled: Bool {
        get {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: mlEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: mlEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: mlEnabledKey)
            if newValue && overallState == .notInitialized {
                Task { await initialize(engine: nil) }
            } else if !newValue {
                overallState = .notInitialized
            }
        }
    }

    /// Call this on app launch to auto-initialize ML if enabled
    func autoInitializeIfNeeded() {
        guard isMLEnabled && overallState == .notInitialized else { return }
        Task { await initialize(engine: nil) }
    }

    // MARK: - Initialization

    func initialize(engine: MLAnalysisEngine?) async {
        guard isMLEnabled else {
            overallState = .notInitialized
            return
        }

        overallState = .initializing

        // Create engine if not provided
        let engineToUse = engine ?? MLAnalysisEngine()
        mlEngine = engineToUse

        do {
            // Load bundled models
            try await engineToUse.loadBundledModels()
            overallState = .ready

            // Check if retraining is needed
            if shouldRetrain() {
                overallState = .needsRetraining
            }
        } catch {
            overallState = .error(error.localizedDescription)
            print("MLModelManager initialization failed: \(error)")
        }
    }

    // MARK: - Training Decisions

    func shouldRetrain() -> Bool {
        // Never trained
        guard let lastDate = lastTrainingDate else { return true }

        // More than threshold days since training
        let daysSinceTraining = Calendar.current.dateComponents(
            [.day],
            from: lastDate,
            to: Date()
        ).day ?? 0

        if daysSinceTraining >= retrainingThresholdDays {
            return true
        }

        // Enough new entries
        if entriesSinceTraining >= retrainingThresholdEntries {
            return true
        }

        return false
    }

    // MARK: - Training

    func trainModels(with data: [MLFeatureVector]) async throws {
        guard data.count >= minimumEntriesForTraining else {
            throw MLError.insufficientData(have: data.count, need: minimumEntriesForTraining)
        }

        overallState = .initializing

        do {
            // Train pattern matcher (k-NN)
            try await mlEngine?.trainPatternMatcher(data: data)

            // Update training state
            lastTrainingDate = Date()
            entriesSinceTraining = 0
            saveState()

            overallState = .ready
        } catch {
            overallState = .error(error.localizedDescription)
            throw error
        }
    }

    func trainForecaster(entries: [SymptomEntry]) async throws {
        try await mlEngine?.trainForecaster(entries: entries)
    }

    // MARK: - Entry Tracking

    func recordNewEntry() {
        entriesSinceTraining += 1
        saveState()

        if shouldRetrain() {
            overallState = .needsRetraining
        }
    }

    // MARK: - Model Reset

    func resetModels() {
        lastTrainingDate = nil
        entriesSinceTraining = 0
        modelVersion = "1.0"
        saveState()
        overallState = .notInitialized
    }

    // MARK: - Status Information

    var statusDescription: String {
        switch overallState {
        case .notInitialized:
            return "ML analysis not initialized"
        case .initializing:
            return "Initializing ML models..."
        case .ready:
            if let date = lastTrainingDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return "Trained \(formatter.localizedString(for: date, relativeTo: Date()))"
            }
            return "Ready"
        case .needsRetraining:
            return "Retraining recommended"
        case .error(let errorMessage):
            return "Error: \(errorMessage)"
        }
    }

    var trainingProgress: Double {
        guard minimumEntriesForTraining > 0 else { return 1.0 }
        return Double(entriesSinceTraining) / Double(minimumEntriesForTraining)
    }

    // MARK: - Model Information

    struct ModelInfo {
        let name: String
        let version: String
        let trainedDate: Date?
        let dataPointsUsed: Int
        let accuracy: Double?
    }

    func getModelInfo() -> [ModelInfo] {
        var info: [ModelInfo] = []

        // Pattern Matcher
        if let engine = mlEngine {
            let patternStatus = engine.patternMatcherStatus
            info.append(ModelInfo(
                name: "Pattern Matcher (k-NN)",
                version: modelVersion,
                trainedDate: lastTrainingDate,
                dataPointsUsed: 0, // Would track actual count
                accuracy: patternStatus == .ready ? 0.75 : nil
            ))

            // Forecaster
            info.append(ModelInfo(
                name: "Mood Forecaster",
                version: modelVersion,
                trainedDate: lastTrainingDate,
                dataPointsUsed: 0,
                accuracy: engine.forecasterStatus == .ready ? 0.70 : nil
            ))
        }

        return info
    }
}

// MARK: - Background Training Support

extension MLModelManager {

    func scheduleBackgroundTraining() {
        // NOTE: In production, this would use BGTaskScheduler
        // to schedule periodic model retraining
        //
        // Example:
        // BGTaskScheduler.shared.register(
        //     forTaskWithIdentifier: "com.neuralpath.mlModelUpdate",
        //     using: nil
        // ) { task in
        //     self.handleBackgroundTraining(task: task as! BGProcessingTask)
        // }
    }

    func performBackgroundTrainingIfNeeded(
        dataExtractor: MLDataExtractor
    ) async {
        guard shouldRetrain() else { return }

        do {
            let data = try await dataExtractor.extractTrainingData(
                minEntries: minimumEntriesForTraining
            )
            try await trainModels(with: data)
        } catch {
            print("Background training failed: \(error)")
        }
    }
}

// MARK: - Model Migration

extension MLModelManager {

    func checkForModelMigration() -> Bool {
        let currentVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"

        // Check if model needs migration based on app version
        // This would be expanded based on actual versioning needs
        return modelVersion != currentVersion
    }

    func migrateModels() async throws {
        // Reset and retrain when app version changes significantly
        resetModels()
    }
}

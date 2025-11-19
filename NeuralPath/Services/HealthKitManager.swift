import Foundation
import HealthKit

@Observable
class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false

    private init() {}

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        var typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        ]

        var typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]

        if #available(iOS 17.0, *) {
            typesToRead.insert(HKObjectType.quantityType(forIdentifier: .timeInDaylight)!)
        }

        if #available(iOS 18.0, *) {
            typesToRead.insert(HKObjectType.stateOfMindType())
            typesToWrite.insert(HKObjectType.stateOfMindType())
        }

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        isAuthorized = true
    }

    @available(iOS 16.0, *)
    func requestMedicationAuthorization() async throws {
        let medicationType = HKObjectType.userAnnotatedMedicationType()

        try await healthStore.requestPerObjectReadAuthorization(for: medicationType, predicate: nil)
    }

    func fetchSleepData(for date: Date) async throws -> (hours: Double, quality: Int)? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }

        guard !samples.isEmpty else { return nil }

        let totalSleepHours = samples
            .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                     $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                     $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                     $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
            .reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            } / 3600.0

        let deepSleepRatio = samples
            .filter { $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue }
            .reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            } / (totalSleepHours * 3600.0)

        let quality = Int(min(5, max(1, (totalSleepHours / 8.0 * 3.0 + deepSleepRatio * 2.0))))

        return (hours: totalSleepHours, quality: quality)
    }

    func saveMindfulSession(duration: TimeInterval, date: Date = Date()) async throws {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.typeNotAvailable
        }

        let endDate = date
        let startDate = date.addingTimeInterval(-duration)

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        try await healthStore.save(sample)
    }

    @available(iOS 17.0, *)
    func fetchTimeInDaylight(for date: Date) async throws -> Double? {
        guard let daylightType = HKObjectType.quantityType(forIdentifier: .timeInDaylight) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: daylightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            self.healthStore.execute(query)
        }

        guard !samples.isEmpty else { return nil }

        let totalMinutes = samples.reduce(0.0) { total, sample in
            total + sample.quantity.doubleValue(for: HKUnit.minute())
        }

        return totalMinutes
    }

    func fetchExerciseMinutes(for date: Date) async throws -> Double? {
        guard let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: exerciseType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            self.healthStore.execute(query)
        }

        guard !samples.isEmpty else { return nil }

        let totalMinutes = samples.reduce(0.0) { total, sample in
            total + sample.quantity.doubleValue(for: HKUnit.minute())
        }

        return totalMinutes
    }


    @available(iOS 16.0, *)
    func fetchMedications() async throws -> [HKUserAnnotatedMedication] {
        let queryDescriptor = HKUserAnnotatedMedicationQueryDescriptor(predicate: nil)
        let medications = try await queryDescriptor.result(for: healthStore)
        return medications.filter { !$0.isArchived }
    }

    @available(iOS 18.0, *)
    func saveStateOfMind(valence: Double, kind: HKStateOfMind.Kind, labels: [HKStateOfMind.Label], date: Date = Date()) async throws {
        let stateOfMind = HKStateOfMind(
            date: date,
            kind: kind,
            valence: valence,
            labels: labels,
            associations: []
        )

        try await healthStore.save(stateOfMind)
    }

    @available(iOS 18.0, *)
    func fetchStateOfMind(from startDate: Date, to endDate: Date) async throws -> [HKStateOfMind] {
        let stateOfMindType = HKObjectType.stateOfMindType()

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stateOfMindType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKStateOfMind] ?? [])
            }
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .typeNotAvailable:
            return "The requested health data type is not available"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
}

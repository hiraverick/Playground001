import Foundation
import HealthKit

@Observable
@MainActor
final class HealthKitManager {

    // MARK: - Published State

    var restingHeartRate: Double? = nil
    var lastReadingDate: Date? = nil
    var isLoading = false
    var isAuthorized = false
    var errorMessage: String? = nil

    // MARK: - Private

    private let healthStore = HKHealthStore()
    private let restingHRType = HKQuantityType(.restingHeartRate)
    private let bpmUnit = HKUnit(from: "count/min")

    /// Persists whether the user has ever tapped through the HK auth dialog,
    /// so on subsequent launches we skip the prompt and go straight to fetching.
    private var hasRequestedAuth: Bool {
        get { UserDefaults.standard.bool(forKey: "hk_auth_requested") }
        set { UserDefaults.standard.set(newValue, forKey: "hk_auth_requested") }
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var isReadingFromToday: Bool {
        guard let date = lastReadingDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    // MARK: - Initialization

    /// Called once when the root view appears. If the user has already been
    /// through the auth dialog we skip the prompt and fetch immediately.
    func initialize() async {
        guard isHealthDataAvailable else { return }
        if hasRequestedAuth {
            isAuthorized = true
            await fetchRestingHeartRate()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isHealthDataAvailable else {
            errorMessage = "HealthKit is not available on this device."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await healthStore.requestAuthorization(
                toShare: [],
                read: [restingHRType]
            )
            hasRequestedAuth = true
            isAuthorized = true
            await fetchRestingHeartRate()
        } catch {
            isLoading = false
            errorMessage = "Authorization failed. Please try again."
        }
    }

    // MARK: - Data Fetching

    func fetchRestingHeartRate() async {
        isLoading = true
        errorMessage = nil

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let todayPredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        // Prefer a reading from today; fall back to most recent ever
        let store = healthStore
        let type  = restingHRType
        let unit  = bpmUnit
        var result = await querySample(predicate: todayPredicate, store: store, type: type, unit: unit)
        if result == nil {
            result = await querySample(predicate: nil, store: store, type: type, unit: unit)
        }

        restingHeartRate = result?.0
        lastReadingDate = result?.1
        isLoading = false
    }

    // MARK: - Private Helpers

    // nonisolated so the continuation is not main-actor-bound; HKSampleQuery
    // delivers its callback on a background thread and resuming from there
    // would otherwise trigger an unsafeForcedSync warning.
    private nonisolated func querySample(
        predicate: NSPredicate?,
        store: HKHealthStore,
        type: HKQuantityType,
        unit: HKUnit
    ) async -> (Double, Date)? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (sample.quantity.doubleValue(for: unit), sample.startDate))
            }
            store.execute(query)
        }
    }
}

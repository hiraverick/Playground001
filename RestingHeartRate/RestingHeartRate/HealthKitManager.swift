import Foundation
import HealthKit

@Observable
@MainActor
final class HealthKitManager {

    // MARK: - Observable State

    var restingHeartRate: Double?
    var lastReadingDate: Date?
    var isLoading = false
    var isAuthorized = false
    var errorMessage: String?

    // MARK: - Private

    private let healthStore = HKHealthStore()
    private let restingHRType = HKQuantityType(.restingHeartRate)
    private let bpmUnit = HKUnit(from: "count/min")

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

    // Allow SwiftUI @State to create this off the main actor without
    // triggering "unsafeForcedSync called from Swift Concurrent context".
    nonisolated init() {}

    // MARK: - Initialization

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

        // Capture values for the nonisolated helper
        let store = healthStore
        let type  = restingHRType
        let unit  = bpmUnit

        var result = await querySample(predicate: todayPredicate, store: store, type: type, unit: unit)
        if result == nil {
            result = await querySample(predicate: nil, store: store, type: type, unit: unit)
        }

        restingHeartRate = result?.0
        lastReadingDate  = result?.1
        isLoading = false
    }

    // MARK: - Private Helpers

    // nonisolated so the HKSampleQuery callback (which fires on an
    // arbitrary HealthKit thread) can resume the continuation directly
    // instead of hopping through the main actor synchronously.
    private nonisolated func querySample(
        predicate: NSPredicate?,
        store: HKHealthStore,
        type: HKQuantityType,
        unit: HKUnit
    ) async -> (Double, Date)? {
        await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
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
                continuation.resume(returning: (
                    sample.quantity.doubleValue(for: unit),
                    sample.startDate
                ))
            }
            store.execute(query)
        }
    }
}

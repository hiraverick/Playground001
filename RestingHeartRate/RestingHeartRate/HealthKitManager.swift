import Foundation
import HealthKit

@Observable
@MainActor
final class HealthKitManager {

    // MARK: - Published State

    var restingHeartRate: Double? = nil
    var lastReadingDate: Date? = nil
    var isLoading = false
    var errorMessage: String? = nil

    // MARK: - Private

    private let healthStore = HKHealthStore()
    private let restingHRType = HKQuantityType(.restingHeartRate)
    private let bpmUnit = HKUnit(from: "count/min")

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var isReadingFromToday: Bool {
        guard let date = lastReadingDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    // MARK: - Authorization

    func requestAuthorization() {
        guard isHealthDataAvailable else {
            errorMessage = "HealthKit is not available on this device."
            return
        }

        Task {
            do {
                try await healthStore.requestAuthorization(
                    toShare: [],
                    read: [restingHRType]
                )
                await fetchRestingHeartRate()
            } catch {
                errorMessage = error.localizedDescription
            }
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
        var result = await querySample(predicate: todayPredicate)
        if result == nil {
            result = await querySample(predicate: nil)
        }

        restingHeartRate = result?.0
        lastReadingDate = result?.1
        isLoading = false
    }

    // MARK: - Private Helpers

    private func querySample(predicate: NSPredicate?) async -> (Double, Date)? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { [bpmUnit] _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: bpmUnit)
                continuation.resume(returning: (bpm, sample.startDate))
            }
            healthStore.execute(query)
        }
    }
}

//
//  HealthKitBridge.swift
//  FaithQuest
//
//  Read-only Apple Health source for the Locker Room.
//  Share types are never requested. Readings are not logged or uploaded.
//

import Foundation

#if canImport(HealthKit)
import HealthKit

/// Reads the seven Locker Room metrics from HealthKit.
/// Immutable after init. HKHealthStore queries are safe to run concurrently.
final class HealthKitBridge: HealthMetricSource, @unchecked Sendable {
    private let store: HKHealthStore
    private let calendar: Calendar

    init(store: HKHealthStore = HKHealthStore(), calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
    }

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard Self.isAvailable else { return }
        // nil share types: FaithQuest never writes Health samples.
        try await store.requestAuthorization(toShare: nil, read: readTypes)
    }

    func fetchSnapshot(now: Date) async -> HealthSnapshot {
        guard Self.isAvailable else {
            return HealthSnapshot(
                readings: HealthMetric.allCases.map { HealthReading(metric: $0, value: nil, capturedAt: nil) },
                access: .unavailable,
                capturedAt: now
            )
        }

        var fetched: [MetricFetch] = []
        await withTaskGroup(of: MetricFetch.self) { group in
            for metric in HealthMetric.allCases {
                group.addTask { [calendar] in
                    await self.fetch(metric, now: now, calendar: calendar)
                }
            }
            for await result in group {
                fetched.append(result)
            }
        }

        let readings = HealthMetric.allCases.map { metric in
            fetched.first { $0.reading.metric == metric }?.reading
                ?? HealthReading(metric: metric, value: nil, capturedAt: nil)
        }
        let anyValue = readings.contains { $0.value != nil }
        let anyDenied = fetched.contains { $0.denied }
        let access: HealthAccessState = anyValue || !anyDenied ? .authorized : .denied
        return HealthSnapshot(readings: readings, access: access, capturedAt: now)
    }

    // MARK: - Types

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        for metric in HealthMetric.allCases {
            if let type = objectType(for: metric) {
                types.insert(type)
            }
        }
        return types
    }

    private func objectType(for metric: HealthMetric) -> HKObjectType? {
        if metric == .sleepAnalysis {
            return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        }
        guard let identifier = quantityIdentifier(for: metric) else { return nil }
        return HKObjectType.quantityType(forIdentifier: identifier)
    }

    private func quantityIdentifier(for metric: HealthMetric) -> HKQuantityTypeIdentifier? {
        switch metric {
        case .activeEnergyBurned: return .activeEnergyBurned
        case .appleExerciseTime: return .appleExerciseTime
        case .bodyMass: return .bodyMass
        case .heartRate: return .heartRate
        case .restingHeartRate: return .restingHeartRate
        case .stepCount: return .stepCount
        case .sleepAnalysis: return nil
        }
    }

    private func unit(for metric: HealthMetric) -> HKUnit? {
        switch metric {
        case .activeEnergyBurned: return .kilocalorie()
        case .appleExerciseTime: return .minute()
        case .bodyMass: return .gramUnit(with: .kilo)
        case .heartRate, .restingHeartRate: return HKUnit.count().unitDivided(by: .minute())
        case .stepCount: return .count()
        case .sleepAnalysis: return nil
        }
    }

    // MARK: - Fetch

    private func fetch(_ metric: HealthMetric, now: Date, calendar: Calendar) async -> MetricFetch {
        do {
            switch metric.aggregation {
            case .cumulativeToday:
                let start = calendar.startOfDay(for: now)
                let value = try await cumulativeValue(for: metric, from: start, to: now)
                return MetricFetch(
                    reading: HealthReading(metric: metric, value: value, capturedAt: now),
                    denied: false
                )
            case .mostRecent(let lookback):
                let start = now.addingTimeInterval(-lookback)
                let sample = try await mostRecentQuantity(for: metric, from: start, to: now)
                return MetricFetch(
                    reading: HealthReading(metric: metric, value: sample?.value, capturedAt: sample?.date),
                    denied: false
                )
            case .sleepNight:
                let window = SleepDuration.recentNightWindow(containing: now, calendar: calendar)
                let samples = try await sleepSamples(overlapping: window)
                let hours = SleepDuration.hours(samples: samples, overlapping: window)
                return MetricFetch(
                    reading: HealthReading(metric: metric, value: hours, capturedAt: now),
                    denied: false
                )
            }
        } catch {
            return MetricFetch(
                reading: HealthReading(metric: metric, value: nil, capturedAt: nil),
                denied: isAuthorizationFailure(error)
            )
        }
    }

    private func cumulativeValue(for metric: HealthMetric, from start: Date, to end: Date) async throws -> Double {
        guard let identifier = quantityIdentifier(for: metric), let unit = unit(for: metric),
              let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return 0
        }
        do {
            return try await statisticsSum(type: type, unit: unit, from: start, to: end) ?? 0
        } catch {
            if isAuthorizationFailure(error) { throw error }
            return try await sumOfSamples(type: type, unit: unit, from: start, to: end)
        }
    }

    private func statisticsSum(type: HKQuantityType, unit: HKUnit, from start: Date, to end: Date) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let store = self.store
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func sumOfSamples(type: HKQuantityType, unit: HKUnit, from start: Date, to end: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let store = self.store
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let total = (samples as? [HKQuantitySample])?.reduce(0.0) { partial, sample in
                    partial + sample.quantity.doubleValue(for: unit)
                } ?? 0
                continuation.resume(returning: total)
            }
            store.execute(query)
        }
    }

    private func mostRecentQuantity(for metric: HealthMetric, from start: Date, to end: Date) async throws -> (value: Double, date: Date)? {
        guard let identifier = quantityIdentifier(for: metric), let unit = unit(for: metric),
              let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let store = self.store
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (sample.quantity.doubleValue(for: unit), sample.endDate))
            }
            store.execute(query)
        }
    }

    private func sleepSamples(overlapping window: DateInterval) async throws -> [SleepInterval] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end, options: [])
        let store = self.store
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let intervals = (samples as? [HKCategorySample] ?? []).map { sample in
                    SleepInterval(value: sample.value, start: sample.startDate, end: sample.endDate)
                }
                continuation.resume(returning: intervals)
            }
            store.execute(query)
        }
    }

    private func isAuthorizationFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == HKError.errorDomain else { return false }
        switch HKError.Code(rawValue: nsError.code) {
        case .errorAuthorizationDenied, .errorAuthorizationNotDetermined:
            return true
        default:
            return false
        }
    }
}

private struct MetricFetch: Sendable {
    let reading: HealthReading
    let denied: Bool
}
#endif

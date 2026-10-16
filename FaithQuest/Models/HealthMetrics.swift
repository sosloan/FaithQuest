//
//  HealthMetrics.swift
//  FaithQuest
//
//  Apple Health readings for the Locker Room.
//  Readings stay on this device. We describe a new snapshot; we do not mutate Health.
//

import Foundation

/// HealthKit types read for the physical realm.
/// Raw values match `HKQuantityTypeIdentifier` / `HKCategoryTypeIdentifier`.
enum HealthMetric: String, Codable, CaseIterable, Identifiable, Sendable {
    case activeEnergyBurned
    case appleExerciseTime
    case bodyMass
    case heartRate
    case restingHeartRate
    case stepCount
    case sleepAnalysis

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .activeEnergyBurned: return "Active Energy"
        case .appleExerciseTime: return "Exercise Time"
        case .bodyMass: return "Body Mass"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .stepCount: return "Steps"
        case .sleepAnalysis: return "Sleep"
        }
    }

    var systemImage: String {
        switch self {
        case .activeEnergyBurned: return "flame.fill"
        case .appleExerciseTime: return "timer"
        case .bodyMass: return "scalemass.fill"
        case .heartRate: return "heart.fill"
        case .restingHeartRate: return "heart.circle.fill"
        case .stepCount: return "figure.walk"
        case .sleepAnalysis: return "bed.double.fill"
        }
    }

    /// Sleep is a category type. Every other requested metric is a quantity type.
    var isCategoryType: Bool { self == .sleepAnalysis }

    /// Daily goal used only to scale the Locker Room activity floor.
    /// Display-only metrics return nil so they are never scored.
    var activityGoal: Double? {
        switch self {
        case .activeEnergyBurned: return 500
        case .appleExerciseTime: return 30
        case .stepCount: return 10_000
        case .sleepAnalysis: return 8
        case .bodyMass, .heartRate, .restingHeartRate: return nil
        }
    }

    /// Weight of this metric in the activity floor. Weights of scored metrics sum to 1.
    var activityWeight: Double {
        switch self {
        case .activeEnergyBurned: return 0.30
        case .appleExerciseTime: return 0.25
        case .stepCount: return 0.25
        case .sleepAnalysis: return 0.20
        case .bodyMass, .heartRate, .restingHeartRate: return 0
        }
    }

    var contributesToActivityFloor: Bool {
        activityGoal != nil && activityWeight > 0
    }
}

/// How a metric is reduced into one number for the Locker Room.
enum HealthAggregation: Equatable {
    /// Sum of samples that started today.
    case cumulativeToday
    /// Latest sample inside a lookback window. Lookback is seconds.
    case mostRecent(lookback: TimeInterval)
    /// Asleep duration overlapping the most recent night window.
    case sleepNight
}

extension HealthMetric {
    var aggregation: HealthAggregation {
        switch self {
        case .activeEnergyBurned, .appleExerciseTime, .stepCount:
            return .cumulativeToday
        case .heartRate:
            return .mostRecent(lookback: 24 * 60 * 60)
        case .restingHeartRate:
            return .mostRecent(lookback: 7 * 24 * 60 * 60)
        case .bodyMass:
            return .mostRecent(lookback: 365 * 24 * 60 * 60)
        case .sleepAnalysis:
            return .sleepNight
        }
    }
}

/// One immutable reading. A nil value means the metric could not be read.
struct HealthReading: Codable, Equatable, Identifiable, Sendable {
    let metric: HealthMetric
    let value: Double?
    let capturedAt: Date?

    var id: String { metric.rawValue }

    var formattedValue: String {
        guard let value, value.isFinite else { return "—" }
        switch metric {
        case .activeEnergyBurned:
            return "\(Int(value.rounded())) kcal"
        case .appleExerciseTime:
            return "\(Int(value.rounded())) min"
        case .bodyMass:
            return String(format: "%.1f kg", locale: Locale(identifier: "en_US_POSIX"), value)
        case .heartRate, .restingHeartRate:
            return "\(Int(value.rounded())) bpm"
        case .stepCount:
            return Self.groupedInteger(value)
        case .sleepAnalysis:
            let totalMinutes = max(0, Int((value * 60).rounded()))
            return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
        }
    }

    private static func groupedInteger(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        let digits = String(abs(rounded))
        var groups: [String] = []
        var remaining = digits
        while remaining.count > 3 {
            let split = remaining.index(remaining.endIndex, offsetBy: -3)
            groups.append(String(remaining[split...]))
            remaining = String(remaining[..<split])
        }
        groups.append(remaining)
        let grouped = groups.reversed().joined(separator: ",")
        return rounded < 0 ? "-\(grouped)" : grouped
    }
}

/// Result of asking Apple Health for the Locker Room metrics.
enum HealthAccessState: String, Codable, Sendable {
    case notDetermined
    case unavailable
    case authorized
    case denied
}

/// Immutable set of Health readings. Not synced to CloudKit.
struct HealthSnapshot: Codable, Equatable, Sendable {
    let readings: [HealthReading]
    let access: HealthAccessState
    let capturedAt: Date?

    static let notDetermined = HealthSnapshot(
        readings: HealthMetric.allCases.map { HealthReading(metric: $0, value: nil, capturedAt: nil) },
        access: .notDetermined,
        capturedAt: nil
    )

    static func assembling(
        values: [HealthMetric: Double],
        sampleDates: [HealthMetric: Date] = [:],
        access: HealthAccessState,
        capturedAt: Date?
    ) -> HealthSnapshot {
        let readings = HealthMetric.allCases.map { metric in
            HealthReading(metric: metric, value: values[metric], capturedAt: sampleDates[metric])
        }
        return HealthSnapshot(readings: readings, access: access, capturedAt: capturedAt)
    }

    func reading(for metric: HealthMetric) -> HealthReading? {
        readings.first { $0.metric == metric }
    }

    /// Locker Room floor in [0, 1], from active energy, exercise time, steps, and sleep.
    /// Missing scored metrics are left out and the remaining weights are renormalized.
    /// Body mass, heart rate, and resting heart rate are never interpreted.
    var activityScore: Double {
        var weighted = 0.0
        var weight = 0.0
        for metric in HealthMetric.allCases where metric.contributesToActivityFloor {
            guard let goal = metric.activityGoal, goal > 0 else { continue }
            guard let value = reading(for: metric)?.value, value.isFinite, value >= 0 else { continue }
            let normalized = min(value / goal, 1.0)
            weighted += normalized * metric.activityWeight
            weight += metric.activityWeight
        }
        guard weight > 0 else { return 0 }
        let score = weighted / weight
        guard score.isFinite else { return 0 }
        return min(max(score, 0), 1)
    }
}

/// A sleep category sample reduced to the fields the duration calculation needs.
struct SleepInterval: Equatable {
    let value: Int
    let start: Date
    let end: Date
}

/// Pure sleep-duration helpers. Raw values match `HKCategoryValueSleepAnalysis`.
enum SleepDuration {
    static let inBed = 0
    static let asleepUnspecified = 1
    static let awake = 2
    static let asleepCore = 3
    static let asleepDeep = 4
    static let asleepREM = 5
    static let stagedAsleep: Set<Int> = [asleepCore, asleepDeep, asleepREM]

    /// Night window used for sleep: 18:00 the previous day through noon, capped at `now`.
    static func recentNightWindow(containing now: Date, calendar: Calendar = .current) -> DateInterval {
        let startOfToday = calendar.startOfDay(for: now)
        let windowStart = calendar.date(byAdding: .hour, value: -6, to: startOfToday)
            ?? startOfToday.addingTimeInterval(-6 * 60 * 60)
        let noon = calendar.date(byAdding: .hour, value: 12, to: startOfToday)
            ?? startOfToday.addingTimeInterval(12 * 60 * 60)
        let windowEnd = min(now, noon)
        if windowEnd >= windowStart {
            return DateInterval(start: windowStart, end: windowEnd)
        }
        return DateInterval(start: windowStart, duration: 0)
    }

    /// Hours of sleep overlapping `window`.
    /// Staged asleep samples are preferred so an unspecified sample covering the same
    /// night is not added again. Overlapping counted samples are merged.
    static func hours(samples: [SleepInterval], overlapping window: DateInterval) -> Double {
        let overlappingSamples = samples.filter { sample in
            sample.end > sample.start && sample.end > window.start && sample.start < window.end
        }
        let hasStaged = overlappingSamples.contains { stagedAsleep.contains($0.value) }
        let counted = overlappingSamples.filter { sample in
            hasStaged ? stagedAsleep.contains(sample.value) : sample.value == asleepUnspecified
        }
        let clipped: [DateInterval] = counted.compactMap { sample in
            let start = max(sample.start, window.start)
            let end = min(sample.end, window.end)
            guard end > start else { return nil }
            return DateInterval(start: start, end: end)
        }
        return mergedDuration(clipped) / 3600.0
    }

    private static func mergedDuration(_ intervals: [DateInterval]) -> TimeInterval {
        let sorted = intervals.sorted { $0.start < $1.start }
        var total: TimeInterval = 0
        var currentStart: Date?
        var currentEnd: Date?
        for interval in sorted {
            if let end = currentEnd, interval.start <= end {
                currentEnd = max(end, interval.end)
            } else {
                if let start = currentStart, let end = currentEnd {
                    total += end.timeIntervalSince(start)
                }
                currentStart = interval.start
                currentEnd = interval.end
            }
        }
        if let start = currentStart, let end = currentEnd {
            total += end.timeIntervalSince(start)
        }
        return total
    }
}

/// Source of Locker Room health readings. Tests supply a stub; the app uses HealthKit when it is linked.
protocol HealthMetricSource {
    func requestAuthorization() async throws
    func fetchSnapshot(now: Date) async -> HealthSnapshot
}

/// Used where HealthKit cannot be linked, including native macOS package builds.
struct UnavailableHealthMetricSource: HealthMetricSource {
    func requestAuthorization() async throws {}

    func fetchSnapshot(now: Date) async -> HealthSnapshot {
        HealthSnapshot(
            readings: HealthMetric.allCases.map { HealthReading(metric: $0, value: nil, capturedAt: nil) },
            access: .unavailable,
            capturedAt: now
        )
    }
}

enum HealthMetricSourceFactory {
    static func makeDefault() -> HealthMetricSource {
        #if canImport(HealthKit)
        return HealthKitBridge()
        #else
        return UnavailableHealthMetricSource()
        #endif
    }
}

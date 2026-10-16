//
//  HealthMetricsTests.swift
//  FaithQuestTests
//
//  Tests for Apple Health metric identity, scoring, and sleep duration.
//

import XCTest
@testable import FaithQuest

final class HealthMetricsTests: XCTestCase {

    func testRequestedHealthKitIdentifiers() {
        XCTAssertEqual(HealthMetric.allCases.map(\.rawValue), [
            "activeEnergyBurned",
            "appleExerciseTime",
            "bodyMass",
            "heartRate",
            "restingHeartRate",
            "stepCount",
            "sleepAnalysis"
        ])
    }

    func testOnlySleepIsACategoryType() {
        XCTAssertTrue(HealthMetric.sleepAnalysis.isCategoryType)
        let quantityTypes = HealthMetric.allCases.filter { !$0.isCategoryType }
        XCTAssertEqual(quantityTypes.map(\.rawValue), [
            "activeEnergyBurned",
            "appleExerciseTime",
            "bodyMass",
            "heartRate",
            "restingHeartRate",
            "stepCount"
        ])
    }

    func testDisplayOnlyMetricsDoNotAffectActivityScore() {
        let withoutVitals = HealthSnapshot.assembling(
            values: scoredGoals(),
            access: .authorized,
            capturedAt: Date()
        )
        var withVitals = scoredGoals()
        withVitals[.bodyMass] = 82
        withVitals[.heartRate] = 140
        withVitals[.restingHeartRate] = 48
        let includingVitals = HealthSnapshot.assembling(
            values: withVitals,
            access: .authorized,
            capturedAt: Date()
        )

        XCTAssertEqual(withoutVitals.activityScore, 1.0, accuracy: 0.0001)
        XCTAssertEqual(includingVitals.activityScore, withoutVitals.activityScore, accuracy: 0.0001)
    }

    func testActivityScoreRenormalizesMissingMetricsAndClampsGoals() {
        let stepsOnly = HealthSnapshot.assembling(
            values: [.stepCount: 10_000],
            access: .authorized,
            capturedAt: Date()
        )
        XCTAssertEqual(stepsOnly.activityScore, 1.0, accuracy: 0.0001)

        let half = HealthSnapshot.assembling(
            values: [
                .activeEnergyBurned: 250,
                .appleExerciseTime: 15,
                .stepCount: 5_000,
                .sleepAnalysis: 4
            ],
            access: .authorized,
            capturedAt: Date()
        )
        XCTAssertEqual(half.activityScore, 0.5, accuracy: 0.0001)

        var overGoal = scoredGoals()
        overGoal[.stepCount] = 40_000
        overGoal[.activeEnergyBurned] = -10
        let clamped = HealthSnapshot.assembling(values: overGoal, access: .authorized, capturedAt: Date())
        XCTAssertEqual(clamped.activityScore, 1.0, accuracy: 0.0001)
    }

    func testActivityScoreIgnoresNonFiniteValuesAndStaysInUnitInterval() {
        let invalid = HealthSnapshot.assembling(
            values: [
                .activeEnergyBurned: .nan,
                .appleExerciseTime: .infinity,
                .stepCount: -5,
                .sleepAnalysis: 8
            ],
            access: .authorized,
            capturedAt: Date()
        )
        XCTAssertEqual(invalid.activityScore, 1.0, accuracy: 0.0001)

        for _ in 0..<100 {
            var values: [HealthMetric: Double] = [:]
            for metric in HealthMetric.allCases {
                values[metric] = Double.random(in: -50...20_000)
            }
            let snapshot = HealthSnapshot.assembling(values: values, access: .authorized, capturedAt: Date())
            XCTAssertGreaterThanOrEqual(snapshot.activityScore, 0)
            XCTAssertLessThanOrEqual(snapshot.activityScore, 1)
        }
    }

    func testActivityWeightsSumToOne() {
        let total = HealthMetric.allCases.reduce(0.0) { $0 + $1.activityWeight }
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
    }

    func testFormattedValues() {
        let reading = HealthReading(metric: .stepCount, value: 12345, capturedAt: nil)
        XCTAssertEqual(reading.formattedValue, "12,345")
        XCTAssertEqual(HealthReading(metric: .heartRate, value: nil, capturedAt: nil).formattedValue, "—")
        XCTAssertEqual(HealthReading(metric: .sleepAnalysis, value: 7.5, capturedAt: nil).formattedValue, "7h 30m")
        XCTAssertEqual(HealthReading(metric: .bodyMass, value: 81.26, capturedAt: nil).formattedValue, "81.3 kg")
    }

    func testSnapshotRoundTripPreservesIdentifiers() throws {
        let original = HealthSnapshot.assembling(
            values: [.stepCount: 100, .sleepAnalysis: 6],
            access: .authorized,
            capturedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HealthSnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.reading(for: .stepCount)?.value, 100)
    }

    func testRecentNightWindowCapsAtNoon() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let afternoon = ISO8601DateFormatter().date(from: "2026-03-15T15:00:00Z")!
        let afternoonWindow = SleepDuration.recentNightWindow(containing: afternoon, calendar: calendar)
        XCTAssertEqual(afternoonWindow.start, ISO8601DateFormatter().date(from: "2026-03-14T18:00:00Z"))
        XCTAssertEqual(afternoonWindow.end, ISO8601DateFormatter().date(from: "2026-03-15T12:00:00Z"))

        let early = ISO8601DateFormatter().date(from: "2026-03-15T03:00:00Z")!
        let earlyWindow = SleepDuration.recentNightWindow(containing: early, calendar: calendar)
        XCTAssertEqual(earlyWindow.end, early)
    }

    func testSleepHoursPreferStagedSamplesAndMergeOverlaps() {
        let window = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 12 * 3600)
        )
        let samples = [
            SleepInterval(value: SleepDuration.asleepCore, start: date(1), end: date(3)),
            SleepInterval(value: SleepDuration.asleepDeep, start: date(2), end: date(4)),
            SleepInterval(value: SleepDuration.asleepREM, start: date(4), end: date(5)),
            SleepInterval(value: SleepDuration.asleepUnspecified, start: date(1), end: date(8)),
            SleepInterval(value: SleepDuration.awake, start: date(5), end: date(6)),
            SleepInterval(value: SleepDuration.inBed, start: date(0), end: date(8))
        ]

        XCTAssertEqual(SleepDuration.hours(samples: samples, overlapping: window), 4, accuracy: 0.0001)
    }

    func testSleepHoursUseUnspecifiedWhenNoStagedSamplesExist() {
        let window = DateInterval(start: date(0), end: date(12))
        let samples = [
            SleepInterval(value: SleepDuration.asleepUnspecified, start: date(10), end: date(14)),
            SleepInterval(value: SleepDuration.inBed, start: date(0), end: date(12))
        ]

        XCTAssertEqual(SleepDuration.hours(samples: samples, overlapping: window), 2, accuracy: 0.0001)
    }

    func testSleepHoursIgnoreSamplesOutsideTheWindow() {
        let window = DateInterval(start: date(0), end: date(2))
        let samples = [
            SleepInterval(value: SleepDuration.asleepUnspecified, start: date(3), end: date(4))
        ]
        XCTAssertEqual(SleepDuration.hours(samples: samples, overlapping: window), 0, accuracy: 0.0001)
    }

    private func scoredGoals() -> [HealthMetric: Double] {
        var values: [HealthMetric: Double] = [:]
        for metric in HealthMetric.allCases {
            if let goal = metric.activityGoal {
                values[metric] = goal
            }
        }
        return values
    }

    private func date(_ hours: TimeInterval) -> Date {
        Date(timeIntervalSince1970: hours * 3600)
    }
}

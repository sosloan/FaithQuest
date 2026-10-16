//
//  InvestingAssertions.swift
//  FaithQuestTests
//
//  XCTest's floating-point equality overload does not accept optional results.
//  Investing and derivative formulas return nil for undefined inputs, so tests
//  compare those results through this overload.
//

import XCTest

func XCTAssertEqual(_ actual: @autoclosure () throws -> Double?,
                    _ expected: @autoclosure () throws -> Double,
                    accuracy: Double,
                    _ message: @autoclosure () -> String = "",
                    file: StaticString = #filePath,
                    line: UInt = #line) {
    do {
        let value = try actual()
        let target = try expected()
        guard let value else {
            let description = message()
            XCTFail(description.isEmpty ? "Expected \(target) but value was nil" : description, file: file, line: line)
            return
        }
        XCTAssertEqual(value, target, accuracy: accuracy, message(), file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}

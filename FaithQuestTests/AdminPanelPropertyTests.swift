//
//  AdminPanelPropertyTests.swift
//  FaithQuestTests
//
//  Property-based tests for Admin Panel
//  Testing invariants, boundary conditions, and behavioral properties
//

import XCTest
import SwiftCheck
@testable import FaithQuest

final class AdminPanelPropertyTests: XCTestCase {
    
    var manager: AdminPanelManager!
    
    override func setUp() {
        super.setUp()
        manager = AdminPanelManager()
    }
    
    // MARK: - Energy Level Properties
    
    func testEnergyLevelValidation() {
        property("Energy levels must be in [0, 1] to be valid") <- forAll { (level: Double) in
            let normalizedLevel = level.truncatingRemainder(dividingBy: 10.0) // Get variety
            let command = AdminCommand.setEnergyLevel(realm: .lockerRoom, level: normalizedLevel)
            let canExecute = self.manager.canExecute(command)
            
            if normalizedLevel >= 0.0 && normalizedLevel <= 1.0 {
                return canExecute <?> "Valid level \(normalizedLevel) should be executable"
            } else {
                return !canExecute <?> "Invalid level \(normalizedLevel) should not be executable"
            }
        }
    }
    
    func testBridgeStrengthValidation() {
        property("Bridge strength must be in [0, 1] to be valid") <- forAll { (level: Double) in
            let normalizedLevel = level.truncatingRemainder(dividingBy: 10.0)
            let command = AdminCommand.setBridgeStrength(level: normalizedLevel)
            let canExecute = self.manager.canExecute(command)
            
            if normalizedLevel >= 0.0 && normalizedLevel <= 1.0 {
                return canExecute <?> "Valid strength \(normalizedLevel) should be executable"
            } else {
                return !canExecute <?> "Invalid strength \(normalizedLevel) should not be executable"
            }
        }
    }
    
    // MARK: - Test Data Generation Properties
    
    func testGenerateTestDataValidation() {
        property("Test data count must be in [1, 1000] to be valid") <- forAll { (count: Int) in
            let command = AdminCommand.generateTestData(count: count)
            let canExecute = self.manager.canExecute(command)
            
            if count >= 1 && count <= 1000 {
                return canExecute <?> "Valid count \(count) should be executable"
            } else {
                return !canExecute <?> "Invalid count \(count) should not be executable"
            }
        }
    }
    
    // MARK: - Command Execution Properties
    
    func testAllValidCommandsSucceed() {
        property("All valid commands should succeed when executed") <- forAll { (rawLevel: Double) in
            let level = abs(rawLevel).truncatingRemainder(dividingBy: 1.0) // Normalize to [0, 1)
            
            let validCommands: [AdminCommand] = [
                .resetEnergy,
                .resetState,
                .forceSync,
                .toggleDebugMode,
                .exportMetrics,
                .setEnergyLevel(realm: .lockerRoom, level: level),
                .setBridgeStrength(level: level),
                .clearTheorems,
                .generateTestData(count: max(1, Int(level * 100) + 1))
            ]
            
            // Use fresh manager for each test
            let freshManager = AdminPanelManager()
            
            for command in validCommands {
                let result = freshManager.execute(command)
                if !result.success {
                    return false <?> "Command \(command.commandId) should succeed"
                }
            }
            
            return true <?> "All valid commands succeeded"
        }
    }
    
    // MARK: - Command History Properties
    
    func testCommandHistoryGrowsMonotonically() {
        property("Command history count never decreases within max limit") <- forAll { (commandCount: UInt8) in
            let freshManager = AdminPanelManager()
            var previousCount = 0
            let iterations = min(Int(commandCount), 50) // Limit iterations
            
            for i in 0..<iterations {
                let level = Double(i) * 0.01
                _ = freshManager.execute(.setEnergyLevel(realm: .lockerRoom, level: level))
                let newCount = freshManager.adminState.commandHistory.count
                
                if newCount < previousCount {
                    return false <?> "History count decreased from \(previousCount) to \(newCount)"
                }
                previousCount = newCount
            }
            
            return true <?> "History count never decreased"
        }
    }
    
    func testCommandHistoryBounded() {
        property("Command history is bounded by max size") <- forAll { (iterations: UInt8) in
            let freshManager = AdminPanelManager()
            let maxSize = 100
            let actualIterations = min(Int(iterations) + 50, 150) // Ensure we go past max
            
            for i in 0..<actualIterations {
                let level = Double(i % 100) * 0.01
                _ = freshManager.execute(.setEnergyLevel(realm: .lockerRoom, level: level))
            }
            
            return freshManager.adminState.commandHistory.count <= maxSize <?> "History should be bounded"
        }
    }
    
    // MARK: - Debug Mode Properties
    
    func testDebugModeToggleIsIdempotent() {
        property("Double toggle returns to original state") <- forAll { (initialToggle: Bool) in
            let freshManager = AdminPanelManager()
            
            if initialToggle {
                _ = freshManager.execute(.toggleDebugMode) // Set to true
            }
            
            let stateBeforeDoubleToggle = freshManager.adminState.isDebugModeEnabled
            _ = freshManager.execute(.toggleDebugMode)
            _ = freshManager.execute(.toggleDebugMode)
            let stateAfterDoubleToggle = freshManager.adminState.isDebugModeEnabled
            
            return stateBeforeDoubleToggle == stateAfterDoubleToggle <?> "Double toggle should restore state"
        }
    }
    
    // MARK: - Command ID Properties
    
    func testCommandIdsAreConsistent() {
        property("Command IDs are consistent across calls") <- forAll { (level: Double) in
            let normalizedLevel = abs(level).truncatingRemainder(dividingBy: 1.0)
            
            let command1 = AdminCommand.setEnergyLevel(realm: .lockerRoom, level: normalizedLevel)
            let command2 = AdminCommand.setEnergyLevel(realm: .lockerRoom, level: normalizedLevel)
            
            return command1.commandId == command2.commandId <?> "Same command should have same ID"
        }
    }
    
    func testDifferentCommandsHaveDifferentIds() {
        property("Different command types have different IDs") <- forAll { (_: Bool) in
            let commands: [AdminCommand] = [
                .resetEnergy,
                .resetState,
                .forceSync,
                .toggleDebugMode,
                .exportMetrics,
                .clearTheorems
            ]
            
            let ids = commands.map { $0.commandId }
            let uniqueIds = Set(ids)
            
            return ids.count == uniqueIds.count <?> "All command types should have unique IDs"
        }
    }
    
    // MARK: - Metrics Properties
    
    func testMetricsAverageEnergyCalculation() {
        property("Average energy is always the mean of locker and library") <- forAll { (lockerEnergy: Double, libraryWisdom: Double) in
            let normLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 1.0)
            let normLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 1.0)
            
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: 0.5
            )
            
            let metrics = AdminMetrics(from: state)
            let expectedAverage = (normLocker + normLibrary) / 2.0
            
            return abs(metrics.averageEnergyLevel - expectedAverage) < 0.0001 <?> "Average should match calculation"
        }
    }
    
    func testMetricsTheoremCount() {
        property("Metrics theorem count matches state theorem count") <- forAll { (count: UInt8) in
            let theoremCount = Int(count) % 50 // Keep reasonable
            var theorems: [OmniTheorem] = []
            
            for i in 0..<theoremCount {
                theorems.append(OmniTheorem(content: "Test \(i)", category: .lockerRoom))
            }
            
            let state = UnifiedState(
                theorems: theorems,
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            )
            
            let metrics = AdminMetrics(from: state)
            
            return metrics.totalTheorems == theoremCount <?> "Theorem count should match"
        }
    }
    
    func testMetricsHarmonyMatchesState() {
        property("Metrics harmony matches UnifiedState harmony") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, bridgeStrength: Double) in
            let normLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 1.0)
            let normLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 1.0)
            let normBridge = abs(bridgeStrength).truncatingRemainder(dividingBy: 1.0)
            
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: normBridge
            )
            
            let metrics = AdminMetrics(from: state)
            
            return abs(metrics.harmony - state.harmony) < 0.0001 <?> "Harmony should match state"
        }
    }
    
    // MARK: - Category Count Properties
    
    func testMetricsCategoryCountsAddUp() {
        property("Category counts sum to total theorems") <- forAll { (lockerCount: UInt8, libraryCount: UInt8, bridgeCount: UInt8) in
            let lc = Int(lockerCount) % 20
            let lib = Int(libraryCount) % 20
            let br = Int(bridgeCount) % 20
            
            var theorems: [OmniTheorem] = []
            for i in 0..<lc {
                theorems.append(OmniTheorem(content: "Locker \(i)", category: .lockerRoom))
            }
            for i in 0..<lib {
                theorems.append(OmniTheorem(content: "Library \(i)", category: .library))
            }
            for i in 0..<br {
                theorems.append(OmniTheorem(content: "Bridge \(i)", category: .bridge))
            }
            
            let state = UnifiedState(theorems: theorems)
            let metrics = AdminMetrics(from: state)
            
            let categorySum = metrics.theoremsByCategory.values.reduce(0, +)
            
            return categorySum == metrics.totalTheorems <?> "Category sum should equal total"
        }
    }
    
    // MARK: - Command Result Properties
    
    func testCommandResultToRecordPreservesData() {
        property("Converting result to record preserves all data") <- forAll { (success: Bool) in
            let command = AdminCommand.resetEnergy
            let message = success ? "Success" : "Failure"
            
            let result = AdminCommandResult(
                success: success,
                message: message,
                command: command
            )
            
            let record = result.toRecord()
            
            return record.command == command <?> "Command preserved" ^&&^
                   record.success == success <?> "Success preserved" ^&&^
                   record.resultMessage == message <?> "Message preserved"
        }
    }
    
    // MARK: - Confirmation Requirement Properties
    
    func testDestructiveCommandsRequireConfirmation() {
        property("Destructive commands always require confirmation") <- forAll { (_: Bool) in
            let destructiveCommands = [
                AdminCommand.resetState,
                AdminCommand.clearTheorems
            ]
            
            for command in destructiveCommands {
                if !command.requiresConfirmation {
                    return false <?> "\(command.commandId) should require confirmation"
                }
            }
            
            return true <?> "All destructive commands require confirmation"
        }
    }
    
    // MARK: - State Immutability Properties
    
    func testAdminStateCopiesAreIndependent() {
        property("Modifying copy doesn't affect original") <- forAll { (isDebug: Bool) in
            var state1 = AdminPanelState(isDebugModeEnabled: isDebug)
            let state2 = state1
            
            state1.isDebugModeEnabled.toggle()
            
            return state1.isDebugModeEnabled != state2.isDebugModeEnabled <?> "States should be independent"
        }
    }
}

// MARK: - Additional Boundary Tests

extension AdminPanelPropertyTests {
    
    func testBoundaryEnergyLevels() {
        // Test exact boundaries
        XCTAssertTrue(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 0.0)))
        XCTAssertTrue(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 1.0)))
        XCTAssertFalse(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: -0.0001)))
        XCTAssertFalse(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 1.0001)))
    }
    
    func testBoundaryTestDataCounts() {
        // Test exact boundaries
        XCTAssertTrue(manager.canExecute(.generateTestData(count: 1)))
        XCTAssertTrue(manager.canExecute(.generateTestData(count: 1000)))
        XCTAssertFalse(manager.canExecute(.generateTestData(count: 0)))
        XCTAssertFalse(manager.canExecute(.generateTestData(count: 1001)))
    }
}

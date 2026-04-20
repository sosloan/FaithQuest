//
//  AdminPanelTests.swift
//  FaithQuestCoreTests
//
//  Tests for the AdminPanel
//

import XCTest
@testable import FaithQuestCore

final class AdminPanelTests: XCTestCase {
    
    var manager: AdminPanelManager!
    
    override func setUp() {
        super.setUp()
        manager = AdminPanelManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - Command Execution Tests
    
    func testExecuteResetEnergy() {
        // When
        let result = manager.execute(.resetEnergy)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("reset"))
    }
    
    func testExecuteToggleDebugMode() {
        // Given
        XCTAssertFalse(manager.adminState.isDebugModeEnabled)
        
        // When
        let result = manager.execute(.toggleDebugMode)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertTrue(manager.adminState.isDebugModeEnabled)
    }
    
    func testCommandHistoryIsUpdated() {
        // When
        _ = manager.execute(.resetEnergy)
        _ = manager.execute(.toggleDebugMode)
        
        // Then
        XCTAssertEqual(manager.adminState.commandHistory.count, 2)
    }
    
    func testLastCommandExecutedIsUpdated() {
        // When
        _ = manager.execute(.resetEnergy)
        
        // Then
        XCTAssertEqual(manager.adminState.lastCommandExecuted, .resetEnergy)
    }
    
    // MARK: - Can Execute Tests
    
    func testCanExecuteValidEnergyLevel() {
        XCTAssertTrue(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 0.5)))
    }
    
    func testCannotExecuteInvalidEnergyLevel() {
        XCTAssertFalse(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 1.5)))
        XCTAssertFalse(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: -0.5)))
    }
    
    func testCanExecuteValidBridgeStrength() {
        XCTAssertTrue(manager.canExecute(.setBridgeStrength(level: 0.7)))
    }
    
    func testCannotExecuteInvalidBridgeStrength() {
        XCTAssertFalse(manager.canExecute(.setBridgeStrength(level: 2.0)))
        XCTAssertFalse(manager.canExecute(.setBridgeStrength(level: -1.0)))
    }
    
    func testCanExecuteValidTestDataCount() {
        XCTAssertTrue(manager.canExecute(.generateTestData(count: 10)))
    }
    
    func testCannotExecuteInvalidTestDataCount() {
        XCTAssertFalse(manager.canExecute(.generateTestData(count: 0)))
        XCTAssertFalse(manager.canExecute(.generateTestData(count: 1001)))
    }
    
    // MARK: - Metrics Tests
    
    func testRefreshMetrics() {
        // Given
        let state = UnifiedState(
            theorems: [
                OmniTheorem(content: "Test", category: .lockerRoom),
                OmniTheorem(content: "Test2", category: .library)
            ],
            lockerRoomEnergy: 0.8,
            libraryWisdom: 0.6,
            bridgeStrength: 0.9
        )
        
        // When
        let metrics = manager.refreshMetrics(from: state)
        
        // Then
        XCTAssertEqual(metrics.totalTheorems, 2)
        XCTAssertEqual(metrics.lockerRoomEnergy, 0.8)
        XCTAssertEqual(metrics.libraryWisdom, 0.6)
        XCTAssertEqual(metrics.bridgeStrength, 0.9)
        XCTAssertEqual(metrics.theoremsByCategory["lockerRoom"], 1)
        XCTAssertEqual(metrics.theoremsByCategory["library"], 1)
    }
    
    // MARK: - Command Properties Tests
    
    func testCommandIdIsUnique() {
        let commands: [AdminCommand] = [
            .resetEnergy,
            .resetState,
            .forceSync,
            .toggleDebugMode,
            .exportMetrics,
            .setEnergyLevel(realm: .lockerRoom, level: 0.5),
            .setBridgeStrength(level: 0.5),
            .clearTheorems,
            .generateTestData(count: 10)
        ]
        
        let ids = commands.map { $0.commandId }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }
    
    func testRequiresConfirmation() {
        XCTAssertTrue(AdminCommand.resetState.requiresConfirmation)
        XCTAssertTrue(AdminCommand.clearTheorems.requiresConfirmation)
        XCTAssertFalse(AdminCommand.resetEnergy.requiresConfirmation)
        XCTAssertFalse(AdminCommand.toggleDebugMode.requiresConfirmation)
    }
    
    func testCommandCategories() {
        XCTAssertEqual(AdminCommand.resetEnergy.category, .energy)
        XCTAssertEqual(AdminCommand.resetState.category, .state)
        XCTAssertEqual(AdminCommand.forceSync.category, .sync)
        XCTAssertEqual(AdminCommand.toggleDebugMode.category, .debug)
        XCTAssertEqual(AdminCommand.exportMetrics.category, .metrics)
    }
    
    // MARK: - Command Result Tests
    
    func testCommandResultToRecord() {
        // Given
        let result = AdminCommandResult(
            success: true,
            message: "Test message",
            command: .resetEnergy
        )
        
        // When
        let record = result.toRecord()
        
        // Then
        XCTAssertEqual(record.success, result.success)
        XCTAssertEqual(record.resultMessage, result.message)
        XCTAssertEqual(record.command, result.command)
    }
}

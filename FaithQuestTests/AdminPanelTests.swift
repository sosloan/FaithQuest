//
//  AdminPanelTests.swift
//  FaithQuestTests
//
//  Tests for the Admin Panel model layer
//  Following test-driven development with explicit calculations
//

import XCTest
@testable import FaithQuest

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
    
    // MARK: - AdminCommand Tests
    
    func testAdminCommandIds() {
        // Given - All admin commands
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
        
        // Then - All have unique IDs
        let ids = commands.map { $0.commandId }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All command IDs should be unique")
    }
    
    func testAdminCommandCategories() {
        // Energy commands
        XCTAssertEqual(AdminCommand.resetEnergy.category, .energy)
        XCTAssertEqual(AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.5).category, .energy)
        XCTAssertEqual(AdminCommand.setBridgeStrength(level: 0.5).category, .energy)
        
        // State commands
        XCTAssertEqual(AdminCommand.resetState.category, .state)
        XCTAssertEqual(AdminCommand.clearTheorems.category, .state)
        
        // Sync commands
        XCTAssertEqual(AdminCommand.forceSync.category, .sync)
        
        // Debug commands
        XCTAssertEqual(AdminCommand.toggleDebugMode.category, .debug)
        XCTAssertEqual(AdminCommand.generateTestData(count: 10).category, .debug)
        
        // Metrics commands
        XCTAssertEqual(AdminCommand.exportMetrics.category, .metrics)
    }
    
    func testConfirmationRequirements() {
        // Commands requiring confirmation
        XCTAssertTrue(AdminCommand.resetState.requiresConfirmation)
        XCTAssertTrue(AdminCommand.clearTheorems.requiresConfirmation)
        
        // Commands not requiring confirmation
        XCTAssertFalse(AdminCommand.resetEnergy.requiresConfirmation)
        XCTAssertFalse(AdminCommand.forceSync.requiresConfirmation)
        XCTAssertFalse(AdminCommand.toggleDebugMode.requiresConfirmation)
        XCTAssertFalse(AdminCommand.exportMetrics.requiresConfirmation)
    }
    
    func testCommandDescriptions() {
        // Given - Various commands
        let resetEnergy = AdminCommand.resetEnergy
        let setEnergy = AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.75)
        let setBridge = AdminCommand.setBridgeStrength(level: 0.5)
        let generateData = AdminCommand.generateTestData(count: 25)
        
        // Then - Descriptions are meaningful
        XCTAssertTrue(resetEnergy.commandDescription.contains("Reset"))
        XCTAssertTrue(setEnergy.commandDescription.contains("75%"))
        XCTAssertTrue(setBridge.commandDescription.contains("50%"))
        XCTAssertTrue(generateData.commandDescription.contains("25"))
    }
    
    // MARK: - AdminPanelManager Tests
    
    func testManagerInitialization() {
        // Then
        XCTAssertFalse(manager.adminState.isDebugModeEnabled)
        XCTAssertNil(manager.adminState.lastCommandExecuted)
        XCTAssertTrue(manager.adminState.commandHistory.isEmpty)
        XCTAssertFalse(manager.adminState.isProcessingCommand)
    }
    
    func testExecuteResetEnergy() {
        // When
        let result = manager.execute(.resetEnergy)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("reset"))
        XCTAssertEqual(manager.adminState.lastCommandExecuted, .resetEnergy)
        XCTAssertEqual(manager.adminState.commandHistory.count, 1)
    }
    
    func testExecuteToggleDebugMode() {
        // Given
        XCTAssertFalse(manager.adminState.isDebugModeEnabled)
        
        // When
        let result1 = manager.execute(.toggleDebugMode)
        
        // Then
        XCTAssertTrue(result1.success)
        XCTAssertTrue(manager.adminState.isDebugModeEnabled)
        
        // When - Toggle again
        let result2 = manager.execute(.toggleDebugMode)
        
        // Then
        XCTAssertTrue(result2.success)
        XCTAssertFalse(manager.adminState.isDebugModeEnabled)
    }
    
    func testCanExecuteValidation() {
        // Valid energy levels
        XCTAssertTrue(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 0.0)))
        XCTAssertTrue(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 0.5)))
        XCTAssertTrue(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 1.0)))
        
        // Invalid energy levels
        XCTAssertFalse(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: -0.1)))
        XCTAssertFalse(manager.canExecute(.setEnergyLevel(realm: .lockerRoom, level: 1.1)))
        
        // Valid bridge strength
        XCTAssertTrue(manager.canExecute(.setBridgeStrength(level: 0.5)))
        
        // Invalid bridge strength
        XCTAssertFalse(manager.canExecute(.setBridgeStrength(level: -0.5)))
        XCTAssertFalse(manager.canExecute(.setBridgeStrength(level: 2.0)))
        
        // Valid test data count
        XCTAssertTrue(manager.canExecute(.generateTestData(count: 1)))
        XCTAssertTrue(manager.canExecute(.generateTestData(count: 1000)))
        
        // Invalid test data count
        XCTAssertFalse(manager.canExecute(.generateTestData(count: 0)))
        XCTAssertFalse(manager.canExecute(.generateTestData(count: 1001)))
    }
    
    func testCommandHistoryGrowth() {
        // When - Execute multiple commands
        for i in 0..<5 {
            _ = manager.execute(.setEnergyLevel(realm: .lockerRoom, level: Double(i) * 0.1))
        }
        
        // Then
        XCTAssertEqual(manager.adminState.commandHistory.count, 5)
    }
    
    func testCommandResultConversion() {
        // Given
        let result = AdminCommandResult(
            success: true,
            message: "Test message",
            command: .resetEnergy
        )
        
        // When
        let record = result.toRecord()
        
        // Then
        XCTAssertEqual(record.command, .resetEnergy)
        XCTAssertTrue(record.success)
        XCTAssertEqual(record.resultMessage, "Test message")
    }
    
    // MARK: - AdminMetrics Tests
    
    func testMetricsCalculation() {
        // Given
        let theorems = [
            OmniTheorem(content: "Test 1", category: .lockerRoom),
            OmniTheorem(content: "Test 2", category: .library),
            OmniTheorem(content: "Test 3", category: .bridge),
            OmniTheorem(content: "Test 4", category: .lockerRoom)
        ]
        let state = UnifiedState(
            theorems: theorems,
            lockerRoomEnergy: 0.6,
            libraryWisdom: 0.4,
            bridgeStrength: 0.5
        )
        
        // When
        let metrics = AdminMetrics(from: state, uptime: 100.0)
        
        // Then
        XCTAssertEqual(metrics.totalTheorems, 4)
        XCTAssertEqual(metrics.lockerRoomEnergy, 0.6)
        XCTAssertEqual(metrics.libraryWisdom, 0.4)
        XCTAssertEqual(metrics.bridgeStrength, 0.5)
        
        // Average energy = (0.6 + 0.4) / 2 = 0.5
        XCTAssertEqual(metrics.averageEnergyLevel, 0.5, accuracy: 0.001)
        
        // Harmony = (1 - |0.6 - 0.4|) * 0.5 = (1 - 0.2) * 0.5 = 0.4
        XCTAssertEqual(metrics.harmony, 0.4, accuracy: 0.001)
        
        // Category counts
        XCTAssertEqual(metrics.theoremsByCategory["lockerRoom"], 2)
        XCTAssertEqual(metrics.theoremsByCategory["library"], 1)
        XCTAssertEqual(metrics.theoremsByCategory["bridge"], 1)
        
        XCTAssertEqual(metrics.systemUptime, 100.0)
    }
    
    func testMetricsWithEmptyState() {
        // Given
        let state = UnifiedState()
        
        // When
        let metrics = AdminMetrics(from: state)
        
        // Then
        XCTAssertEqual(metrics.totalTheorems, 0)
        XCTAssertTrue(metrics.theoremsByCategory.isEmpty)
        XCTAssertEqual(metrics.averageEnergyLevel, 0.5) // (0.5 + 0.5) / 2
    }
    
    // MARK: - AdminPanelState Tests
    
    func testPanelStateInitialization() {
        // Given
        let state = AdminPanelState()
        
        // Then
        XCTAssertFalse(state.isDebugModeEnabled)
        XCTAssertNil(state.lastCommandExecuted)
        XCTAssertTrue(state.commandHistory.isEmpty)
        XCTAssertFalse(state.isProcessingCommand)
        XCTAssertNil(state.errorMessage)
    }
    
    func testPanelStateEquality() {
        // Given
        let state1 = AdminPanelState(isDebugModeEnabled: true)
        let state2 = AdminPanelState(isDebugModeEnabled: true)
        let state3 = AdminPanelState(isDebugModeEnabled: false)
        
        // Then
        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
    }
    
    // MARK: - AdminCommandRecord Tests
    
    func testCommandRecordCreation() {
        // Given
        let command = AdminCommand.resetEnergy
        
        // When
        let record = AdminCommandRecord(
            command: command,
            success: true,
            resultMessage: "Success"
        )
        
        // Then
        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.command, command)
        XCTAssertTrue(record.success)
        XCTAssertEqual(record.resultMessage, "Success")
    }
    
    // MARK: - Command Equatable Tests
    
    func testCommandEquality() {
        // Simple commands
        XCTAssertEqual(AdminCommand.resetEnergy, AdminCommand.resetEnergy)
        XCTAssertNotEqual(AdminCommand.resetEnergy, AdminCommand.resetState)
        
        // Commands with associated values
        XCTAssertEqual(
            AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.5),
            AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.5)
        )
        XCTAssertNotEqual(
            AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.5),
            AdminCommand.setEnergyLevel(realm: .library, level: 0.5)
        )
        XCTAssertNotEqual(
            AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.5),
            AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.6)
        )
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testAdminCommandProtocolConformance() {
        // Given - Various commands as protocol type
        let commands: [AdminCommandProtocol] = [
            AdminCommand.resetEnergy,
            AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.5),
            AdminCommand.generateTestData(count: 10)
        ]
        
        // Then - All conform to protocol
        for command in commands {
            XCTAssertFalse(command.commandId.isEmpty)
            XCTAssertFalse(command.commandDescription.isEmpty)
        }
    }
    
    func testAdminStateProtocolConformance() {
        // Given
        let state: AdminStateProtocol = AdminPanelState()
        
        // Then - Protocol properties accessible
        XCTAssertFalse(state.isDebugModeEnabled)
        XCTAssertNil(state.lastCommandExecuted)
        XCTAssertTrue(state.commandHistory.isEmpty)
    }
    
    func testAdminPanelProtocolConformance() {
        // Given
        let panel: AdminPanelProtocol = AdminPanelManager()
        
        // Then - Protocol methods work
        XCTAssertTrue(panel.canExecute(.resetEnergy))
        let metrics = panel.refreshMetrics()
        XCTAssertEqual(metrics.totalTheorems, 0)
    }
}

// MARK: - Codable Tests

extension AdminPanelTests {
    
    func testCommandCodable() throws {
        // Given
        let command = AdminCommand.setEnergyLevel(realm: .lockerRoom, level: 0.75)
        
        // When - Encode
        let encoded = try JSONEncoder().encode(command)
        
        // Then - Decode
        let decoded = try JSONDecoder().decode(AdminCommand.self, from: encoded)
        XCTAssertEqual(decoded, command)
    }
    
    func testRecordCodable() throws {
        // Given
        let record = AdminCommandRecord(
            command: .resetEnergy,
            success: true,
            resultMessage: "Test"
        )
        
        // When - Encode
        let encoded = try JSONEncoder().encode(record)
        
        // Then - Decode
        let decoded = try JSONDecoder().decode(AdminCommandRecord.self, from: encoded)
        XCTAssertEqual(decoded.command, record.command)
        XCTAssertEqual(decoded.success, record.success)
        XCTAssertEqual(decoded.resultMessage, record.resultMessage)
    }
    
    func testMetricsCodable() throws {
        // Given
        let metrics = AdminMetrics(from: UnifiedState(), uptime: 42.0)
        
        // When - Encode
        let encoded = try JSONEncoder().encode(metrics)
        
        // Then - Decode
        let decoded = try JSONDecoder().decode(AdminMetrics.self, from: encoded)
        XCTAssertEqual(decoded.totalTheorems, metrics.totalTheorems)
        XCTAssertEqual(decoded.systemUptime, metrics.systemUptime)
    }
    
    func testPanelStateCodable() throws {
        // Given
        let state = AdminPanelState(
            isDebugModeEnabled: true,
            lastCommandExecuted: .resetEnergy
        )
        
        // When - Encode
        let encoded = try JSONEncoder().encode(state)
        
        // Then - Decode
        let decoded = try JSONDecoder().decode(AdminPanelState.self, from: encoded)
        XCTAssertEqual(decoded.isDebugModeEnabled, state.isDebugModeEnabled)
        XCTAssertEqual(decoded.lastCommandExecuted, state.lastCommandExecuted)
    }
}

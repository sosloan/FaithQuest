//
//  EnergyRouterTests.swift
//  FaithQuestCoreTests
//
//  Tests for the EnergyRouter
//

import XCTest
@testable import FaithQuestCore

final class EnergyRouterTests: XCTestCase {
    
    var router: EnergyRouter!
    
    override func setUp() {
        super.setUp()
        router = EnergyRouter()
    }
    
    override func tearDown() {
        router = nil
        super.tearDown()
    }
    
    // MARK: - Blow Tests
    
    func testBlowFromLockerToLibrary() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.8, libraryWisdom: 0.3, bridgeStrength: 0.5)
        
        // When
        let result = router.blowLockerToLibrary(amount: 0.2, state: state)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.deltaEnergies[.lockerRoom] ?? 0, -0.2, accuracy: 0.001)
        XCTAssertEqual(result.deltaEnergies[.library] ?? 0, 0.16, accuracy: 0.001) // 80% efficiency
    }
    
    func testBlowWithInsufficientEnergy() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.1, libraryWisdom: 0.3, bridgeStrength: 0.5)
        
        // When
        let result = router.blowLockerToLibrary(amount: 0.5, state: state)
        
        // Then
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.deltaEnergies.isEmpty)
    }
    
    func testBlowWithNegativeAmount() {
        // Given
        let state = UnifiedState()
        
        // When
        let result = router.blowLockerToLibrary(amount: -0.1, state: state)
        
        // Then
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("positive"))
    }
    
    // MARK: - Suck Tests
    
    func testSuckFromLibraryToLocker() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.3, libraryWisdom: 0.8, bridgeStrength: 0.5)
        
        // When
        let result = router.suckLibraryToLocker(amount: 0.2, state: state)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.deltaEnergies[.library] ?? 0, -0.2, accuracy: 0.001)
        XCTAssertEqual(result.deltaEnergies[.lockerRoom] ?? 0, 0.18, accuracy: 0.001) // 90% efficiency
    }
    
    func testSuckIsMoreEfficientThanBlow() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.5, libraryWisdom: 0.5, bridgeStrength: 0.5)
        let amount = 0.1
        
        // When
        let blowResult = router.blowLockerToLibrary(amount: amount, state: state)
        let suckResult = router.suckLockerToLibrary(amount: amount, state: state)
        
        // Then
        let blowTransfer = blowResult.deltaEnergies[.library] ?? 0
        let suckTransfer = suckResult.deltaEnergies[.library] ?? 0
        XCTAssertGreaterThan(suckTransfer, blowTransfer)
    }
    
    // MARK: - Balance Tests
    
    func testAutoBalanceWhenAlreadyBalanced() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.5, libraryWisdom: 0.5, bridgeStrength: 0.5)
        
        // When
        let result = router.autoBalance(state: state)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.deltaEnergies.isEmpty)
        XCTAssertTrue(result.message.contains("balanced"))
    }
    
    func testAutoBalanceTransfersFromHighToLow() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.9, libraryWisdom: 0.3, bridgeStrength: 0.5)
        
        // When
        let result = router.autoBalance(state: state)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertLessThan(result.deltaEnergies[.lockerRoom] ?? 0, 0)
        XCTAssertGreaterThan(result.deltaEnergies[.library] ?? 0, 0)
    }
    
    // MARK: - Apply Routing Result Tests
    
    func testApplyRoutingResultUpdatesState() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.8, libraryWisdom: 0.3, bridgeStrength: 0.5)
        let result = router.blowLockerToLibrary(amount: 0.2, state: state)
        
        // When
        let newState = router.applyRoutingResult(result, to: state)
        
        // Then
        XCTAssertEqual(newState.lockerRoomEnergy, 0.6, accuracy: 0.001)
        XCTAssertEqual(newState.libraryWisdom, 0.46, accuracy: 0.001) // 0.3 + 0.16
        XCTAssertEqual(newState.bridgeStrength, state.bridgeStrength) // Unchanged
    }
    
    func testApplyRoutingResultClampsValues() {
        // Given
        let state = UnifiedState(lockerRoomEnergy: 0.95, libraryWisdom: 0.95, bridgeStrength: 0.5)
        let result = RoutingResult(
            success: true,
            message: "Test",
            deltaEnergies: [.lockerRoom: 0.2, .library: 0.2]
        )
        
        // When
        let newState = router.applyRoutingResult(result, to: state)
        
        // Then
        XCTAssertEqual(newState.lockerRoomEnergy, 1.0)
        XCTAssertEqual(newState.libraryWisdom, 1.0)
    }
    
    func testApplyFailedResultReturnsOriginalState() {
        // Given
        let state = UnifiedState()
        let result = RoutingResult(success: false, message: "Failed", deltaEnergies: [:])
        
        // When
        let newState = router.applyRoutingResult(result, to: state)
        
        // Then
        XCTAssertEqual(newState.lockerRoomEnergy, state.lockerRoomEnergy)
        XCTAssertEqual(newState.libraryWisdom, state.libraryWisdom)
        XCTAssertEqual(newState.bridgeStrength, state.bridgeStrength)
    }
    
    // MARK: - Physics Constants Tests
    
    func testMuscleTransferEfficiency() {
        XCTAssertEqual(router.muscleTransferEfficiency, 0.8)
    }
    
    func testMindTransferEfficiency() {
        XCTAssertEqual(router.mindTransferEfficiency, 0.9)
    }
    
    func testBalancingRate() {
        XCTAssertEqual(router.balancingRate, 0.05)
    }
    
    func testEquilibriumThreshold() {
        XCTAssertEqual(router.equilibriumThreshold, 0.01)
    }
}

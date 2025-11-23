//
//  EnergyRouterTests.swift
//  FaithQuestTests
//
//  Tests for the EnergyRouter
//

import XCTest
@testable import FaithQuest

final class EnergyRouterTests: XCTestCase {
    
    var router: EnergyRouter!
    var initialState: UnifiedState!
    
    override func setUp() {
        super.setUp()
        router = EnergyRouter()
        initialState = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.6,
            libraryWisdom: 0.4,
            bridgeStrength: 0.5
        )
    }
    
    override func tearDown() {
        router = nil
        initialState = nil
        super.tearDown()
    }
    
    // MARK: - Blowing Tests
    
    func testBlowingFromLockerToLibrary() {
        // Given
        let transferAmount = 0.2
        let muscleEfficiency = 0.8  // 80% efficiency (20% loss in muscle-to-mental conversion)
        
        // When
        let result = router.blowLockerToLibrary(amount: transferAmount, state: initialState)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.deltaEnergies[.lockerRoom], -transferAmount)
        
        // Energy transferred = amount * efficiency (showing the 20% loss explicitly)
        let expectedTransfer = transferAmount * muscleEfficiency
        XCTAssertEqual(result.deltaEnergies[.library]!, expectedTransfer, accuracy: 0.01)
    }
    
    func testBlowingFromLibraryToLocker() {
        // Given
        let transferAmount = 0.2
        let muscleEfficiency = 0.8  // 80% efficiency
        
        // When
        let result = router.blowLibraryToLocker(amount: transferAmount, state: initialState)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.deltaEnergies[.library], -transferAmount)
        
        // Energy transferred = amount * efficiency
        let expectedTransfer = transferAmount * muscleEfficiency
        XCTAssertEqual(result.deltaEnergies[.lockerRoom]!, expectedTransfer, accuracy: 0.01)
    }
    
    func testBlowingInsufficientEnergy() {
        // When - Try to blow more than available
        let result = router.blowLockerToLibrary(amount: 0.8, state: initialState)
        
        // Then
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("Insufficient"))
    }
    
    func testBlowingNegativeAmount() {
        // When
        let result = router.blowLockerToLibrary(amount: -0.1, state: initialState)
        
        // Then
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("positive"))
    }
    
    // MARK: - Suction Tests
    
    func testSuckingFromLibraryToLocker() {
        // Given
        let transferAmount = 0.2
        let mindEfficiency = 0.9  // 90% efficiency (10% loss in mental-to-physical conversion)
        
        // When
        let result = router.suckLibraryToLocker(amount: transferAmount, state: initialState)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.deltaEnergies[.library], -transferAmount)
        
        // Energy transferred = amount * efficiency (more efficient than blowing)
        let expectedTransfer = transferAmount * mindEfficiency
        XCTAssertEqual(result.deltaEnergies[.lockerRoom]!, expectedTransfer, accuracy: 0.01)
    }
    
    func testSuckingFromLockerToLibrary() {
        // Given
        let transferAmount = 0.2
        let mindEfficiency = 0.9  // 90% efficiency
        
        // When
        let result = router.suckLockerToLibrary(amount: transferAmount, state: initialState)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.deltaEnergies[.lockerRoom], -transferAmount)
        
        // Energy transferred = amount * efficiency
        let expectedTransfer = transferAmount * mindEfficiency
        XCTAssertEqual(result.deltaEnergies[.library]!, expectedTransfer, accuracy: 0.01)
    }
    
    func testSuckingInsufficientEnergy() {
        // When - Try to suck more than available
        let result = router.suckLibraryToLocker(amount: 0.5, state: initialState)
        
        // Then
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("Insufficient"))
    }
    
    func testEnergyLossExplicitCalculation() {
        // Given - Test explicitly showing energy loss in transfer
        let transferAmount = 0.2
        let muscleEfficiency = 0.8
        let energyLoss = transferAmount * (1.0 - muscleEfficiency)  // 20% loss = 0.04
        
        // When - Blowing from locker to library
        let result = router.blowLockerToLibrary(amount: transferAmount, state: initialState)
        
        // Then - Verify the loss is exactly what we expect
        let expectedTransfer = transferAmount - energyLoss  // 0.2 - 0.04 = 0.16
        XCTAssertEqual(result.deltaEnergies[.library]!, expectedTransfer, accuracy: 0.01)
        XCTAssertEqual(energyLoss, 0.04, accuracy: 0.01, "Expected 20% loss in muscle-to-mental conversion")
    }
    
    func testSuckingMoreEfficientThanBlowing() {
        // When
        let blowResult = router.blowLockerToLibrary(amount: 0.1, state: initialState)
        let suckResult = router.suckLockerToLibrary(amount: 0.1, state: initialState)
        
        // Then
        let blowTransferred = blowResult.deltaEnergies[.library] ?? 0
        let suckTransferred = suckResult.deltaEnergies[.library] ?? 0
        XCTAssertGreaterThan(suckTransferred, blowTransferred)
    }
    
    // MARK: - Balancing Tests
    
    func testAutoBalancingFromHigherToLower() {
        // Given - Locker has more energy than Library (0.6 vs 0.4)
        
        // When
        let result = router.autoBalance(state: initialState)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.deltaEnergies[.lockerRoom])
        XCTAssertNotNil(result.deltaEnergies[.library])
        
        // Energy should flow from Locker to Library
        XCTAssertLessThan(result.deltaEnergies[.lockerRoom]!, 0)
        XCTAssertGreaterThan(result.deltaEnergies[.library]!, 0)
    }
    
    func testBalancingAlreadyBalanced() {
        // Given - Balanced state
        let balancedState = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.5,
            bridgeStrength: 0.5
        )
        
        // When
        let result = router.autoBalance(state: balancedState)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("already balanced"))
    }
    
    // MARK: - Apply Routing Result Tests
    
    func testApplyBlowingResult() {
        // Given
        let blowResult = router.blowLockerToLibrary(amount: 0.2, state: initialState)
        
        // When
        let newState = router.applyRoutingResult(blowResult, to: initialState)
        
        // Then
        XCTAssertLessThan(newState.lockerRoomEnergy, initialState.lockerRoomEnergy)
        XCTAssertGreaterThan(newState.libraryWisdom, initialState.libraryWisdom)
        XCTAssertEqual(newState.bridgeStrength, initialState.bridgeStrength) // Unchanged
    }
    
    func testApplySuctionResult() {
        // Given
        let suckResult = router.suckLibraryToLocker(amount: 0.2, state: initialState)
        
        // When
        let newState = router.applyRoutingResult(suckResult, to: initialState)
        
        // Then
        XCTAssertGreaterThan(newState.lockerRoomEnergy, initialState.lockerRoomEnergy)
        XCTAssertLessThan(newState.libraryWisdom, initialState.libraryWisdom)
    }
    
    func testApplyBalancingResult() {
        // Given
        let balanceResult = router.autoBalance(state: initialState)
        
        // When
        let newState = router.applyRoutingResult(balanceResult, to: initialState)
        
        // Then
        let initialDiff = abs(initialState.lockerRoomEnergy - initialState.libraryWisdom)
        let newDiff = abs(newState.lockerRoomEnergy - newState.libraryWisdom)
        XCTAssertLessThan(newDiff, initialDiff) // More balanced
    }
    
    func testApplyFailedResult() {
        // Given - Failed result
        let failedResult = router.blowLockerToLibrary(amount: 1.0, state: initialState)
        
        // When
        let newState = router.applyRoutingResult(failedResult, to: initialState)
        
        // Then - State should be unchanged
        XCTAssertEqual(newState.lockerRoomEnergy, initialState.lockerRoomEnergy)
        XCTAssertEqual(newState.libraryWisdom, initialState.libraryWisdom)
    }
    
    func testApplyResultClampsAtOne() {
        // Given - High library energy
        let highEnergyState = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.95,
            libraryWisdom: 0.95,
            bridgeStrength: 0.5
        )
        
        // When
        let blowResult = router.blowLockerToLibrary(amount: 0.2, state: highEnergyState)
        let newState = router.applyRoutingResult(blowResult, to: highEnergyState)
        
        // Then
        XCTAssertLessThanOrEqual(newState.libraryWisdom, 1.0)
    }
    
    func testApplyResultClampsAtZero() {
        // Given - Low energy state
        let lowEnergyState = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.05,
            libraryWisdom: 0.4,
            bridgeStrength: 0.5
        )
        
        // When
        let blowResult = router.blowLockerToLibrary(amount: 0.05, state: lowEnergyState)
        let newState = router.applyRoutingResult(blowResult, to: lowEnergyState)
        
        // Then
        XCTAssertGreaterThanOrEqual(newState.lockerRoomEnergy, 0.0)
    }
    
    // MARK: - State Immutability Tests
    
    func testRoutingDoesNotMutateOriginalState() {
        // Given
        let originalEnergy = initialState.lockerRoomEnergy
        
        // When
        let result = router.blowLockerToLibrary(amount: 0.1, state: initialState)
        _ = router.applyRoutingResult(result, to: initialState)
        
        // Then - Original state should be unchanged
        XCTAssertEqual(initialState.lockerRoomEnergy, originalEnergy)
    }
    
    // MARK: - Message Routing Tests
    
    func testDirectMessageRouting() {
        // When
        let message = EnergyMessage.blow(from: .lockerRoom, to: .library, amount: 0.1)
        let result = router.route(message, currentState: initialState)
        
        // Then
        XCTAssertTrue(result.success)
    }
    
    func testSuctionMessageRouting() {
        // When
        let message = EnergyMessage.suck(from: .library, to: .lockerRoom, amount: 0.1)
        let result = router.route(message, currentState: initialState)
        
        // Then
        XCTAssertTrue(result.success)
    }
    
    func testBalanceMessageRouting() {
        // When
        let message = EnergyMessage.balance(between: .lockerRoom, and: .library)
        let result = router.route(message, currentState: initialState)
        
        // Then
        XCTAssertTrue(result.success)
    }
}

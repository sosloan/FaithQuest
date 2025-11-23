//
//  PhysicsEngineTests.swift
//  FaithQuestTests
//
//  Tests for the PhysicsEngine ViewModel
//

import XCTest
import Combine
@testable import FaithQuest

final class PhysicsEngineTests: XCTestCase {
    
    var engine: PhysicsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        engine = PhysicsEngine()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        engine = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testEngineInitialization() {
        // Then
        XCTAssertNotNil(engine.state)
        XCTAssertFalse(engine.isLoading)
        XCTAssertNil(engine.errorMessage)
    }
    
    func testBoostLockerRoom() {
        // Given
        let initialEnergy = engine.state.lockerRoomEnergy
        
        // When
        engine.boostLockerRoom()
        
        // Then
        XCTAssertGreaterThan(engine.state.lockerRoomEnergy, initialEnergy)
    }
    
    func testBoostLibrary() {
        // Given
        let initialWisdom = engine.state.libraryWisdom
        
        // When
        engine.boostLibrary()
        
        // Then
        XCTAssertGreaterThan(engine.state.libraryWisdom, initialWisdom)
    }
    
    func testStrengthenBridge() {
        // Given
        let initialStrength = engine.state.bridgeStrength
        
        // When
        engine.strengthenBridge()
        
        // Then
        XCTAssertGreaterThan(engine.state.bridgeStrength, initialStrength)
    }
    
    func testEnergyCapAtOne() {
        // Given - Start with high energy
        engine = PhysicsEngine(initialState: UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.95,
            libraryWisdom: 0.95,
            bridgeStrength: 0.95
        ))
        
        // When - Boost multiple times
        engine.boostLockerRoom()
        engine.boostLockerRoom()
        engine.boostLibrary()
        engine.boostLibrary()
        engine.strengthenBridge()
        engine.strengthenBridge()
        
        // Then - Should not exceed 1.0
        XCTAssertLessThanOrEqual(engine.state.lockerRoomEnergy, 1.0)
        XCTAssertLessThanOrEqual(engine.state.libraryWisdom, 1.0)
        XCTAssertLessThanOrEqual(engine.state.bridgeStrength, 1.0)
    }
    
    func testStateImmutability() {
        // Given
        let initialState = engine.state
        let initialTheoremsCount = initialState.theorems.count
        
        // When
        engine.boostLockerRoom()
        
        // Then - New state should be created, not mutated
        XCTAssertNotEqual(engine.state.lockerRoomEnergy, initialState.lockerRoomEnergy)
        XCTAssertEqual(engine.state.theorems.count, initialTheoremsCount) // Theorems unchanged
    }
    
    func testPublishedStateUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "State published")
        var receivedUpdate = false
        
        engine.$state
            .dropFirst() // Skip initial value
            .sink { _ in
                receivedUpdate = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        engine.boostLockerRoom()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedUpdate)
    }
    
    // MARK: - Router Operations Tests
    
    func testBlowLockerToLibrary() {
        // Given
        let initialLockerEnergy = engine.state.lockerRoomEnergy
        let initialLibraryWisdom = engine.state.libraryWisdom
        
        // When
        engine.blowLockerToLibrary(amount: 0.1)
        
        // Then
        XCTAssertLessThan(engine.state.lockerRoomEnergy, initialLockerEnergy)
        XCTAssertGreaterThan(engine.state.libraryWisdom, initialLibraryWisdom)
    }
    
    func testBlowLibraryToLocker() {
        // Given
        let initialLockerEnergy = engine.state.lockerRoomEnergy
        let initialLibraryWisdom = engine.state.libraryWisdom
        
        // When
        engine.blowLibraryToLocker(amount: 0.1)
        
        // Then
        XCTAssertGreaterThan(engine.state.lockerRoomEnergy, initialLockerEnergy)
        XCTAssertLessThan(engine.state.libraryWisdom, initialLibraryWisdom)
    }
    
    func testSuckLibraryToLocker() {
        // Given
        let initialLockerEnergy = engine.state.lockerRoomEnergy
        let initialLibraryWisdom = engine.state.libraryWisdom
        
        // When
        engine.suckLibraryToLocker(amount: 0.1)
        
        // Then
        XCTAssertGreaterThan(engine.state.lockerRoomEnergy, initialLockerEnergy)
        XCTAssertLessThan(engine.state.libraryWisdom, initialLibraryWisdom)
    }
    
    func testSuckLockerToLibrary() {
        // Given
        let initialLockerEnergy = engine.state.lockerRoomEnergy
        let initialLibraryWisdom = engine.state.libraryWisdom
        
        // When
        engine.suckLockerToLibrary(amount: 0.1)
        
        // Then
        XCTAssertLessThan(engine.state.lockerRoomEnergy, initialLockerEnergy)
        XCTAssertGreaterThan(engine.state.libraryWisdom, initialLibraryWisdom)
    }
    
    func testAutoBalanceEnergy() {
        // Given - Create imbalanced state
        engine = PhysicsEngine(initialState: UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.8,
            libraryWisdom: 0.2,
            bridgeStrength: 0.5
        ))
        let initialDifference = abs(engine.state.lockerRoomEnergy - engine.state.libraryWisdom)
        
        // When
        engine.autoBalanceEnergy()
        
        // Then
        let newDifference = abs(engine.state.lockerRoomEnergy - engine.state.libraryWisdom)
        XCTAssertLessThan(newDifference, initialDifference)
    }
    
    func testSuctionMoreEfficientThanBlowing() {
        // Given - Two engines with same initial state
        let engine1 = PhysicsEngine(initialState: UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.5,
            bridgeStrength: 0.5
        ))
        let engine2 = PhysicsEngine(initialState: UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.5,
            bridgeStrength: 0.5
        ))
        
        // When
        engine1.blowLockerToLibrary(amount: 0.1)
        engine2.suckLockerToLibrary(amount: 0.1)
        
        // Then - Suction should transfer more energy
        XCTAssertGreaterThan(engine2.state.libraryWisdom, engine1.state.libraryWisdom)
    }
}

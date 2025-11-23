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
}

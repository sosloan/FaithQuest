//
//  OmniTheoremTests.swift
//  FaithQuestTests
//
//  Tests for the OmniTheorem model
//

import XCTest
@testable import FaithQuest

final class OmniTheoremTests: XCTestCase {
    
    func testTheoremCreation() {
        // Given
        let content = "Train harder to think clearer"
        let category = OmniTheorem.Category.lockerRoom
        
        // When
        let theorem = OmniTheorem(content: content, category: category)
        
        // Then
        XCTAssertEqual(theorem.content, content)
        XCTAssertEqual(theorem.category, category)
        XCTAssertNotNil(theorem.id)
        XCTAssertNotNil(theorem.timestamp)
    }
    
    func testTheoremCategoriesExist() {
        // Verify all three categories exist
        _ = OmniTheorem.Category.lockerRoom
        _ = OmniTheorem.Category.library
        _ = OmniTheorem.Category.bridge
    }
    
    func testUnifiedStateInitialization() {
        // Given
        let state = UnifiedState()
        
        // Then
        XCTAssertEqual(state.theorems.count, 0)
        XCTAssertEqual(state.lockerRoomEnergy, 0.5)
        XCTAssertEqual(state.libraryWisdom, 0.5)
        XCTAssertEqual(state.bridgeStrength, 0.5)
    }
    
    func testHarmonyCalculation() {
        // Given - Perfect balance
        let balancedState = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.7,
            libraryWisdom: 0.7,
            bridgeStrength: 1.0
        )
        
        // Then - Should have maximum harmony
        XCTAssertEqual(balancedState.harmony, 1.0, accuracy: 0.01)
        
        // Given - Imbalanced
        let imbalancedState = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 1.0,
            libraryWisdom: 0.0,
            bridgeStrength: 1.0
        )
        
        // Then - Should have zero harmony
        XCTAssertEqual(imbalancedState.harmony, 0.0, accuracy: 0.01)
    }
    
    func testHarmonyWithWeakBridge() {
        // Given - Good balance but weak bridge
        let state = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.5,
            bridgeStrength: 0.5
        )
        
        // Then - Harmony should be affected by bridge strength
        XCTAssertEqual(state.harmony, 0.5, accuracy: 0.01)
    }
    
    func testTheoremCodable() throws {
        // Given
        let theorem = OmniTheorem(content: "Test insight", category: .bridge)
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(theorem)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedTheorem = try decoder.decode(OmniTheorem.self, from: data)
        
        XCTAssertEqual(theorem.id, decodedTheorem.id)
        XCTAssertEqual(theorem.content, decodedTheorem.content)
        XCTAssertEqual(theorem.category, decodedTheorem.category)
    }
}

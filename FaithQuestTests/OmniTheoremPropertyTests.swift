//
//  OmniTheoremPropertyTests.swift
//  FaithQuestTests
//
//  Property-based tests for OmniTheorem
//  "In π's infinite digits, primes hide like gems. The polymath finds them where specialists see only chaos."
//  Moving from path coverage (99.1%) to behavioral coverage (∞)
//

import XCTest
import SwiftCheck
@testable import FaithQuest

final class OmniTheoremPropertyTests: XCTestCase {
    
    // MARK: - Harmony Property Tests
    
    func testHarmonyAlwaysBetweenZeroAndOne() {
        property("Harmony is always in [0, 1] for any valid state") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, bridgeStrength: Double) in
            // Normalize inputs to valid range [0, 1]
            let normalizedLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 1.0)
            let normalizedLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 1.0)
            let normalizedBridge = abs(bridgeStrength).truncatingRemainder(dividingBy: 1.0)
            
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normalizedLocker,
                libraryWisdom: normalizedLibrary,
                bridgeStrength: normalizedBridge
            )
            
            return state.harmony >= 0.0 <?> "Harmony below 0" ^&&^
                   state.harmony <= 1.0 <?> "Harmony above 1"
        }
    }
    
    func testHarmonyMaximizedWhenPerfectlyBalanced() {
        property("Perfect balance with max bridge strength gives harmony = 1.0") <- forAll { (energy: Double) in
            let normalized = abs(energy).truncatingRemainder(dividingBy: 1.0)
            
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normalized,
                libraryWisdom: normalized,  // Same as locker for perfect balance
                bridgeStrength: 1.0
            )
            
            return abs(state.harmony - 1.0) < 0.0001 <?> "Harmony should be 1.0 for perfect balance"
        }
    }
    
    func testHarmonyIsZeroWithMaxImbalance() {
        property("Maximum imbalance gives harmony = 0.0") <- {
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 1.0,
                libraryWisdom: 0.0,
                bridgeStrength: 1.0
            )
            
            return abs(state.harmony - 0.0) < 0.0001 <?> "Harmony should be 0.0 for max imbalance"
        }
    }
    
    func testHarmonyMonotonicWithBridgeStrength() {
        property("Harmony increases monotonically with bridge strength when balanced") <- forAll { (bridgeStrength1: Double, bridgeStrength2: Double) in
            let normalized1 = abs(bridgeStrength1).truncatingRemainder(dividingBy: 1.0)
            let normalized2 = abs(bridgeStrength2).truncatingRemainder(dividingBy: 1.0)
            
            guard normalized1 < normalized2 else { return Discard() }
            
            let state1 = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: normalized1
            )
            
            let state2 = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: normalized2
            )
            
            return state1.harmony < state2.harmony <?> "Harmony should increase with bridge strength"
        }
    }
    
    // MARK: - Coding/Decoding Property Tests
    
    func testTheoremEncodingDecodingRoundTrip() {
        property("Encoding then decoding produces identical theorem") <- forAll { (content: String, categoryRaw: Int) in
            guard !content.isEmpty else { return Discard() }
            
            let categories: [OmniTheorem.Category] = [.lockerRoom, .library, .bridge]
            let category = categories[abs(categoryRaw) % categories.count]
            
            let theorem = OmniTheorem(content: content, category: category)
            
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(theorem)
                
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(OmniTheorem.self, from: data)
                
                return decoded.id == theorem.id <?> "ID mismatch" ^&&^
                       decoded.content == theorem.content <?> "Content mismatch" ^&&^
                       decoded.category == theorem.category <?> "Category mismatch"
            } catch {
                return false <?> "Encoding/Decoding failed: \(error)"
            }
        }
    }
    
    // MARK: - State Immutability Properties
    
    func testUnifiedStateIsImmutable() {
        property("Creating new state doesn't affect old state") <- forAll { (energy: Double, wisdom: Double) in
            let normalized1 = abs(energy).truncatingRemainder(dividingBy: 1.0)
            let normalized2 = abs(wisdom).truncatingRemainder(dividingBy: 1.0)
            
            let state1 = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            )
            
            let originalEnergy = state1.lockerRoomEnergy
            let originalWisdom = state1.libraryWisdom
            
            // Create new state with different values
            _ = UnifiedState(
                theorems: state1.theorems,
                lockerRoomEnergy: normalized1,
                libraryWisdom: normalized2,
                bridgeStrength: state1.bridgeStrength
            )
            
            // Original state should be unchanged
            return state1.lockerRoomEnergy == originalEnergy <?> "Original energy changed" ^&&^
                   state1.libraryWisdom == originalWisdom <?> "Original wisdom changed"
        }
    }
    
    // MARK: - Harmony Formula Properties
    
    func testHarmonyFormulaCommutative() {
        property("Harmony formula is commutative: energy and wisdom can be swapped") <- forAll { (energy: Double, wisdom: Double, bridge: Double) in
            let normEnergy = abs(energy).truncatingRemainder(dividingBy: 1.0)
            let normWisdom = abs(wisdom).truncatingRemainder(dividingBy: 1.0)
            let normBridge = abs(bridge).truncatingRemainder(dividingBy: 1.0)
            
            let state1 = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normEnergy,
                libraryWisdom: normWisdom,
                bridgeStrength: normBridge
            )
            
            let state2 = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normWisdom,
                libraryWisdom: normEnergy,
                bridgeStrength: normBridge
            )
            
            return abs(state1.harmony - state2.harmony) < 0.0001 <?> "Harmony should be symmetric in energy and wisdom"
        }
    }
    
    func testHarmonyScalesWithBridge() {
        property("Harmony scales linearly with bridge strength for fixed balance") <- forAll { (bridge: Double, scale: Double) in
            let normBridge = abs(bridge).truncatingRemainder(dividingBy: 0.5) // Use half range to test scaling
            let normScale = 1.0 + abs(scale).truncatingRemainder(dividingBy: 1.0) // Scale between 1.0 and 2.0
            
            let scaledBridge = min(1.0, normBridge * normScale)
            
            let state1 = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: normBridge
            )
            
            let state2 = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: scaledBridge
            )
            
            // When balanced, harmony = bridgeStrength, so scaling should be linear
            let expectedRatio = scaledBridge / normBridge
            let actualRatio = state2.harmony / state1.harmony
            
            return abs(expectedRatio - actualRatio) < 0.01 <?> "Harmony should scale linearly with bridge strength"
        }
    }
    
    // MARK: - Theorem Properties
    
    func testTheoremTimestampIsReasonable() {
        property("Theorem timestamp is within reasonable bounds") <- forAll { (content: String, categoryRaw: Int) in
            guard !content.isEmpty else { return Discard() }
            
            let categories: [OmniTheorem.Category] = [.lockerRoom, .library, .bridge]
            let category = categories[abs(categoryRaw) % categories.count]
            
            let theorem = OmniTheorem(content: content, category: category)
            let now = Date()
            
            // Timestamp should be close to now (within 1 second)
            return abs(theorem.timestamp.timeIntervalSince(now)) < 1.0 <?> "Timestamp not within 1 second of creation"
        }
    }
    
    func testTheoremIDIsUnique() {
        property("Each theorem gets a unique ID") <- forAll { (content: String) in
            guard !content.isEmpty else { return Discard() }
            
            let theorem1 = OmniTheorem(content: content, category: .lockerRoom)
            let theorem2 = OmniTheorem(content: content, category: .lockerRoom)
            
            return theorem1.id != theorem2.id <?> "IDs should be unique even with same content"
        }
    }
}

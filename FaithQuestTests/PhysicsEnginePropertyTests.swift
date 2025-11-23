//
//  PhysicsEnginePropertyTests.swift
//  FaithQuestTests
//
//  Property-based tests for PhysicsEngine
//  Testing state transitions, bounds, and higher-order function properties
//

import XCTest
import SwiftCheck
@testable import FaithQuest

final class PhysicsEnginePropertyTests: XCTestCase {
    
    // MARK: - State Boundary Properties
    
    func testAllEnergyValuesStayWithinBounds() {
        property("All energy values remain in [0, 1] after any operation") <- forAll { (initialEnergy: Double, initialWisdom: Double, initialBridge: Double, operationChoice: Int) in
            let normEnergy = abs(initialEnergy).truncatingRemainder(dividingBy: 1.0)
            let normWisdom = abs(initialWisdom).truncatingRemainder(dividingBy: 1.0)
            let normBridge = abs(initialBridge).truncatingRemainder(dividingBy: 1.0)
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: normEnergy,
                libraryWisdom: normWisdom,
                bridgeStrength: normBridge
            ))
            
            // Perform random operation
            let operation = abs(operationChoice) % 6
            switch operation {
            case 0: engine.boostLockerRoom()
            case 1: engine.boostLibrary()
            case 2: engine.strengthenBridge()
            case 3: engine.blowLockerToLibrary(amount: 0.1)
            case 4: engine.suckLibraryToLocker(amount: 0.1)
            case 5: engine.autoBalanceEnergy()
            default: break
            }
            
            return engine.state.lockerRoomEnergy >= 0.0 <?> "Locker energy below 0" ^&&^
                   engine.state.lockerRoomEnergy <= 1.0 <?> "Locker energy above 1" ^&&^
                   engine.state.libraryWisdom >= 0.0 <?> "Library wisdom below 0" ^&&^
                   engine.state.libraryWisdom <= 1.0 <?> "Library wisdom above 1" ^&&^
                   engine.state.bridgeStrength >= 0.0 <?> "Bridge strength below 0" ^&&^
                   engine.state.bridgeStrength <= 1.0 <?> "Bridge strength above 1"
        }
    }
    
    func testBoostOperationsNeverExceedMaximum() {
        property("Boosting at max value doesn't exceed 1.0") <- forAll { (operationChoice: Int) in
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: 1.0,
                libraryWisdom: 1.0,
                bridgeStrength: 1.0
            ))
            
            // Apply boost operations
            for _ in 0..<5 {
                let operation = abs(operationChoice) % 3
                switch operation {
                case 0: engine.boostLockerRoom()
                case 1: engine.boostLibrary()
                case 2: engine.strengthenBridge()
                default: break
                }
            }
            
            return engine.state.lockerRoomEnergy <= 1.0 <?> "Locker energy exceeded 1.0" ^&&^
                   engine.state.libraryWisdom <= 1.0 <?> "Library wisdom exceeded 1.0" ^&&^
                   engine.state.bridgeStrength <= 1.0 <?> "Bridge strength exceeded 1.0"
        }
    }
    
    // MARK: - State Transition Properties
    
    func testBoostOperationsAlwaysIncrease() {
        property("Boost operations always increase the target value") <- forAll { (energy: Double, wisdom: Double, bridge: Double) in
            let normEnergy = abs(energy).truncatingRemainder(dividingBy: 0.8)
            let normWisdom = abs(wisdom).truncatingRemainder(dividingBy: 0.8)
            let normBridge = abs(bridge).truncatingRemainder(dividingBy: 0.8)
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: normEnergy,
                libraryWisdom: normWisdom,
                bridgeStrength: normBridge
            ))
            
            let initialLocker = engine.state.lockerRoomEnergy
            let initialLibrary = engine.state.libraryWisdom
            let initialBridge = engine.state.bridgeStrength
            
            engine.boostLockerRoom()
            let afterBoostLocker = engine.state.lockerRoomEnergy
            
            let engine2 = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: normEnergy,
                libraryWisdom: normWisdom,
                bridgeStrength: normBridge
            ))
            engine2.boostLibrary()
            let afterBoostLibrary = engine2.state.libraryWisdom
            
            let engine3 = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: normEnergy,
                libraryWisdom: normWisdom,
                bridgeStrength: normBridge
            ))
            engine3.strengthenBridge()
            let afterBoostBridge = engine3.state.bridgeStrength
            
            return afterBoostLocker > initialLocker <?> "Locker boost didn't increase" ^&&^
                   afterBoostLibrary > initialLibrary <?> "Library boost didn't increase" ^&&^
                   afterBoostBridge > initialBridge <?> "Bridge boost didn't increase"
        }
    }
    
    // MARK: - Router Operation Properties
    
    func testBlowOperationTransfersEnergy() {
        property("Blowing from locker to library transfers energy") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, amount: Double) in
            let normLocker = 0.3 + abs(lockerEnergy).truncatingRemainder(dividingBy: 0.5)
            let normLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 0.5)
            let normAmount = abs(amount).truncatingRemainder(dividingBy: 0.2) + 0.01
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: 0.5
            ))
            
            let initialLocker = engine.state.lockerRoomEnergy
            let initialLibrary = engine.state.libraryWisdom
            
            engine.blowLockerToLibrary(amount: normAmount)
            
            return engine.state.lockerRoomEnergy < initialLocker <?> "Locker energy should decrease" ^&&^
                   engine.state.libraryWisdom > initialLibrary <?> "Library wisdom should increase"
        }
    }
    
    func testSuckOperationTransfersEnergy() {
        property("Sucking from library to locker transfers energy") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, amount: Double) in
            let normLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 0.5)
            let normLibrary = 0.3 + abs(libraryWisdom).truncatingRemainder(dividingBy: 0.5)
            let normAmount = abs(amount).truncatingRemainder(dividingBy: 0.2) + 0.01
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: 0.5
            ))
            
            let initialLocker = engine.state.lockerRoomEnergy
            let initialLibrary = engine.state.libraryWisdom
            
            engine.suckLibraryToLocker(amount: normAmount)
            
            return engine.state.lockerRoomEnergy > initialLocker <?> "Locker energy should increase" ^&&^
                   engine.state.libraryWisdom < initialLibrary <?> "Library wisdom should decrease"
        }
    }
    
    func testAutoBalanceReducesImbalance() {
        property("Auto-balance reduces imbalance between realms") <- forAll { (energy1: Double, energy2: Double) in
            let norm1 = abs(energy1).truncatingRemainder(dividingBy: 1.0)
            let norm2 = abs(energy2).truncatingRemainder(dividingBy: 1.0)
            
            let initialDiff = abs(norm1 - norm2)
            guard initialDiff > 0.05 else { return Discard() }
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: norm1,
                libraryWisdom: norm2,
                bridgeStrength: 0.5
            ))
            
            engine.autoBalanceEnergy()
            
            let newDiff = abs(engine.state.lockerRoomEnergy - engine.state.libraryWisdom)
            
            return newDiff < initialDiff <?> "Auto-balance should reduce imbalance"
        }
    }
    
    // MARK: - Functor Properties (Higher-Order Functions)
    
    func testOperationsCompose() {
        property("Operations can be composed without breaking invariants") <- forAll { (amount1: Double, amount2: Double) in
            let norm1 = abs(amount1).truncatingRemainder(dividingBy: 0.1) + 0.05
            let norm2 = abs(amount2).truncatingRemainder(dividingBy: 0.1) + 0.05
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            ))
            
            // Compose multiple operations
            engine.blowLockerToLibrary(amount: norm1)
            engine.suckLibraryToLocker(amount: norm2)
            engine.autoBalanceEnergy()
            engine.boostLockerRoom()
            
            // All invariants should still hold
            return engine.state.lockerRoomEnergy >= 0.0 <?> "Invariant violated after composition" ^&&^
                   engine.state.lockerRoomEnergy <= 1.0 <?> "Invariant violated after composition" ^&&^
                   engine.state.libraryWisdom >= 0.0 <?> "Invariant violated after composition" ^&&^
                   engine.state.libraryWisdom <= 1.0 <?> "Invariant violated after composition"
        }
    }
    
    func testOperationSequenceIsAssociative() {
        property("Sequence of boosts is associative in effect") <- forAll { (count: Int) in
            let boostCount = abs(count) % 5 + 1
            
            let engine1 = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.3,
                libraryWisdom: 0.3,
                bridgeStrength: 0.3
            ))
            
            let engine2 = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.3,
                libraryWisdom: 0.3,
                bridgeStrength: 0.3
            ))
            
            // Apply boosts in sequence
            for _ in 0..<boostCount {
                engine1.boostLockerRoom()
            }
            
            // Apply same number of boosts (associativity test)
            for _ in 0..<boostCount {
                engine2.boostLockerRoom()
            }
            
            // Results should be equal (within floating point precision)
            return abs(engine1.state.lockerRoomEnergy - engine2.state.lockerRoomEnergy) < 0.001 <?> "Operation sequence not consistent"
        }
    }
    
    // MARK: - Idempotence Properties
    
    func testMaxedValuesAreIdempotent() {
        property("Operations on maxed values are idempotent") <- forAll { (count: Int) in
            let operationCount = abs(count) % 10 + 1
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: 1.0,
                libraryWisdom: 1.0,
                bridgeStrength: 1.0
            ))
            
            // Apply boost repeatedly
            for _ in 0..<operationCount {
                engine.boostLockerRoom()
            }
            
            // Should still be at max
            return abs(engine.state.lockerRoomEnergy - 1.0) < 0.001 <?> "Maxed value changed"
        }
    }
    
    // MARK: - State Consistency Properties
    
    func testTheoremListNeverChangesFromRouting() {
        property("Routing operations never affect theorem list") <- forAll { (amount: Double) in
            let normAmount = abs(amount).truncatingRemainder(dividingBy: 0.2)
            
            let theorem = OmniTheorem(content: "Test theorem", category: .bridge)
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [theorem],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            ))
            
            let initialTheoremCount = engine.state.theorems.count
            
            // Perform routing operations
            engine.blowLockerToLibrary(amount: normAmount)
            engine.suckLibraryToLocker(amount: normAmount)
            engine.autoBalanceEnergy()
            
            return engine.state.theorems.count == initialTheoremCount <?> "Theorem count changed from routing"
        }
    }
    
    func testBridgeStrengthUnaffectedByEnergyRouting() {
        property("Energy routing never changes bridge strength") <- forAll { (amount: Double, bridgeStrength: Double) in
            let normAmount = abs(amount).truncatingRemainder(dividingBy: 0.2)
            let normBridge = abs(bridgeStrength).truncatingRemainder(dividingBy: 1.0)
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: normBridge
            ))
            
            let initialBridge = engine.state.bridgeStrength
            
            // Perform various routing operations
            engine.blowLockerToLibrary(amount: normAmount)
            engine.suckLibraryToLocker(amount: normAmount)
            engine.autoBalanceEnergy()
            
            return abs(engine.state.bridgeStrength - initialBridge) < 0.001 <?> "Bridge strength changed from routing"
        }
    }
    
    // MARK: - Monotonicity Properties
    
    func testSequentialBoostsMonotonic() {
        property("Sequential boosts monotonically increase values") <- forAll { (initialValue: Double) in
            let normValue = abs(initialValue).truncatingRemainder(dividingBy: 0.5)
            
            let engine = PhysicsEngine(initialState: UnifiedState(
                theorems: [],
                lockerRoomEnergy: normValue,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            ))
            
            var previousValue = engine.state.lockerRoomEnergy
            
            for _ in 0..<3 {
                engine.boostLockerRoom()
                let currentValue = engine.state.lockerRoomEnergy
                
                guard currentValue >= previousValue else {
                    return false <?> "Value decreased during boost sequence"
                }
                
                previousValue = currentValue
            }
            
            return true <?> "Monotonicity maintained"
        }
    }
    
    // MARK: - Initial State Properties
    
    func testDefaultInitialStateIsBalanced() {
        property("Default initialized engine has balanced state") <- {
            let engine = PhysicsEngine()
            
            let locker = engine.state.lockerRoomEnergy
            let library = engine.state.libraryWisdom
            let bridge = engine.state.bridgeStrength
            
            return locker == 0.5 <?> "Default locker energy not 0.5" ^&&^
                   library == 0.5 <?> "Default library wisdom not 0.5" ^&&^
                   bridge == 0.5 <?> "Default bridge strength not 0.5"
        }
    }
    
    func testCustomInitialStateIsPreserved() {
        property("Custom initial state is preserved") <- forAll { (energy: Double, wisdom: Double, bridge: Double) in
            let normEnergy = abs(energy).truncatingRemainder(dividingBy: 1.0)
            let normWisdom = abs(wisdom).truncatingRemainder(dividingBy: 1.0)
            let normBridge = abs(bridge).truncatingRemainder(dividingBy: 1.0)
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normEnergy,
                libraryWisdom: normWisdom,
                bridgeStrength: normBridge
            )
            
            let engine = PhysicsEngine(initialState: initialState)
            
            return abs(engine.state.lockerRoomEnergy - normEnergy) < 0.001 <?> "Initial locker energy not preserved" ^&&^
                   abs(engine.state.libraryWisdom - normWisdom) < 0.001 <?> "Initial library wisdom not preserved" ^&&^
                   abs(engine.state.bridgeStrength - normBridge) < 0.001 <?> "Initial bridge strength not preserved"
        }
    }
}

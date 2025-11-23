//
//  EnergyRouterPropertyTests.swift
//  FaithQuestTests
//
//  Property-based tests for EnergyRouter
//  Testing energy conservation, efficiency bounds, and Lyapunov stability properties
//

import XCTest
import SwiftCheck
@testable import FaithQuest

final class EnergyRouterPropertyTests: XCTestCase {
    
    var router: EnergyRouter!
    
    override func setUp() {
        super.setUp()
        router = EnergyRouter()
    }
    
    // MARK: - Energy Conservation Properties
    
    func testBlowingConservesEnergyWithLoss() {
        property("Blowing operation conserves energy accounting for 20% loss") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, transferAmount: Double) in
            let normLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 1.0)
            let normLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 1.0)
            let normTransfer = abs(transferAmount).truncatingRemainder(dividingBy: min(normLocker, 0.5))
            
            guard normTransfer > 0.001 else { return Discard() }
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: 0.5
            )
            
            let result = self.router.blowLockerToLibrary(amount: normTransfer, state: initialState)
            
            guard result.success else { return Discard() }
            
            let newState = self.router.applyRoutingResult(result, to: initialState)
            
            // Energy before = lockerEnergy + libraryWisdom
            let energyBefore = initialState.lockerRoomEnergy + initialState.libraryWisdom
            // Energy after = new locker + new library
            let energyAfter = newState.lockerRoomEnergy + newState.libraryWisdom
            // Loss should be 20% of transferred amount
            let expectedLoss = normTransfer * 0.2
            
            return abs((energyBefore - energyAfter) - expectedLoss) < 0.01 <?> "Energy conservation violated"
        }
    }
    
    func testSuctionConservesEnergyWithLoss() {
        property("Suction operation conserves energy accounting for 10% loss") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, transferAmount: Double) in
            let normLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 1.0)
            let normLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 1.0)
            let normTransfer = abs(transferAmount).truncatingRemainder(dividingBy: min(normLibrary, 0.5))
            
            guard normTransfer > 0.001 else { return Discard() }
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: 0.5
            )
            
            let result = self.router.suckLibraryToLocker(amount: normTransfer, state: initialState)
            
            guard result.success else { return Discard() }
            
            let newState = self.router.applyRoutingResult(result, to: initialState)
            
            let energyBefore = initialState.lockerRoomEnergy + initialState.libraryWisdom
            let energyAfter = newState.lockerRoomEnergy + newState.libraryWisdom
            let expectedLoss = normTransfer * 0.1
            
            return abs((energyBefore - energyAfter) - expectedLoss) < 0.01 <?> "Energy conservation violated"
        }
    }
    
    // MARK: - Efficiency Properties
    
    func testBlowingEfficiencyIs80Percent() {
        property("Blowing always transfers exactly 80% of amount") <- forAll { (sourceEnergy: Double, transferAmount: Double) in
            let normSource = 0.5 + abs(sourceEnergy).truncatingRemainder(dividingBy: 0.5) // [0.5, 1.0]
            let normTransfer = abs(transferAmount).truncatingRemainder(dividingBy: min(normSource, 0.3))
            
            guard normTransfer > 0.001 else { return Discard() }
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normSource,
                libraryWisdom: 0.3,
                bridgeStrength: 0.5
            )
            
            let result = self.router.blowLockerToLibrary(amount: normTransfer, state: initialState)
            
            guard result.success else { return Discard() }
            
            let transferred = result.deltaEnergies[.library] ?? 0.0
            let expectedTransfer = normTransfer * 0.8
            
            return abs(transferred - expectedTransfer) < 0.001 <?> "Blowing efficiency not 80%"
        }
    }
    
    func testSuctionEfficiencyIs90Percent() {
        property("Suction always transfers exactly 90% of amount") <- forAll { (sourceEnergy: Double, transferAmount: Double) in
            let normSource = 0.5 + abs(sourceEnergy).truncatingRemainder(dividingBy: 0.5) // [0.5, 1.0]
            let normTransfer = abs(transferAmount).truncatingRemainder(dividingBy: min(normSource, 0.3))
            
            guard normTransfer > 0.001 else { return Discard() }
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.3,
                libraryWisdom: normSource,
                bridgeStrength: 0.5
            )
            
            let result = self.router.suckLibraryToLocker(amount: normTransfer, state: initialState)
            
            guard result.success else { return Discard() }
            
            let transferred = result.deltaEnergies[.lockerRoom] ?? 0.0
            let expectedTransfer = normTransfer * 0.9
            
            return abs(transferred - expectedTransfer) < 0.001 <?> "Suction efficiency not 90%"
        }
    }
    
    func testSuctionMoreEfficientThanBlowing() {
        property("Suction always transfers more energy than blowing for same amount") <- forAll { (amount: Double) in
            let normAmount = 0.1 + abs(amount).truncatingRemainder(dividingBy: 0.2) // [0.1, 0.3]
            
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            )
            
            let blowResult = self.router.blowLockerToLibrary(amount: normAmount, state: state)
            let suckResult = self.router.suckLockerToLibrary(amount: normAmount, state: state)
            
            let blowTransferred = blowResult.deltaEnergies[.library] ?? 0.0
            let suckTransferred = suckResult.deltaEnergies[.library] ?? 0.0
            
            return suckTransferred > blowTransferred <?> "Suction should transfer more than blowing"
        }
    }
    
    // MARK: - Boundary Condition Properties
    
    func testEnergyStaysWithinBounds() {
        property("All energy values stay within [0, 1] after routing") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, transferAmount: Double) in
            let normLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 1.0)
            let normLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 1.0)
            let normTransfer = abs(transferAmount).truncatingRemainder(dividingBy: 0.5)
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: 0.5
            )
            
            let result = self.router.blowLockerToLibrary(amount: normTransfer, state: initialState)
            let newState = self.router.applyRoutingResult(result, to: initialState)
            
            return newState.lockerRoomEnergy >= 0.0 <?> "Locker energy below 0" ^&&^
                   newState.lockerRoomEnergy <= 1.0 <?> "Locker energy above 1" ^&&^
                   newState.libraryWisdom >= 0.0 <?> "Library wisdom below 0" ^&&^
                   newState.libraryWisdom <= 1.0 <?> "Library wisdom above 1"
        }
    }
    
    func testNegativeTransferAlwaysFails() {
        property("Negative transfer amounts always fail") <- forAll { (amount: Double) in
            let negativeAmount = -abs(amount) - 0.01
            
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            )
            
            let blowResult = self.router.blowLockerToLibrary(amount: negativeAmount, state: state)
            let suckResult = self.router.suckLibraryToLocker(amount: negativeAmount, state: state)
            
            return !blowResult.success <?> "Blowing should fail with negative amount" ^&&^
                   !suckResult.success <?> "Suction should fail with negative amount"
        }
    }
    
    func testInsufficientEnergyAlwaysFails() {
        property("Transfer more than available energy always fails") <- forAll { (availableEnergy: Double, extraAmount: Double) in
            let normEnergy = abs(availableEnergy).truncatingRemainder(dividingBy: 0.5) // [0, 0.5)
            let normExtra = abs(extraAmount).truncatingRemainder(dividingBy: 0.5) + 0.01 // [0.01, 0.51)
            let transferAmount = normEnergy + normExtra
            
            let state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normEnergy,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            )
            
            let result = self.router.blowLockerToLibrary(amount: transferAmount, state: state)
            
            return !result.success <?> "Transfer should fail when amount exceeds available energy"
        }
    }
    
    // MARK: - Balance Properties
    
    func testAutoBalanceReducesDifference() {
        property("Auto-balance always reduces energy difference") <- forAll { (energy1: Double, energy2: Double) in
            let norm1 = abs(energy1).truncatingRemainder(dividingBy: 1.0)
            let norm2 = abs(energy2).truncatingRemainder(dividingBy: 1.0)
            
            let initialDiff = abs(norm1 - norm2)
            guard initialDiff > 0.02 else { return Discard() } // Skip already balanced states
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: norm1,
                libraryWisdom: norm2,
                bridgeStrength: 0.5
            )
            
            let result = self.router.autoBalance(state: initialState)
            let newState = self.router.applyRoutingResult(result, to: initialState)
            
            let newDiff = abs(newState.lockerRoomEnergy - newState.libraryWisdom)
            
            return newDiff < initialDiff <?> "Auto-balance should reduce energy difference"
        }
    }
    
    func testBalanceConvergesToEquilibrium() {
        property("Repeated balancing converges to equilibrium") <- forAll { (energy1: Double, energy2: Double) in
            let norm1 = abs(energy1).truncatingRemainder(dividingBy: 1.0)
            let norm2 = abs(energy2).truncatingRemainder(dividingBy: 1.0)
            
            guard abs(norm1 - norm2) > 0.05 else { return Discard() }
            
            var state = UnifiedState(
                theorems: [],
                lockerRoomEnergy: norm1,
                libraryWisdom: norm2,
                bridgeStrength: 0.5
            )
            
            // Apply balancing 10 times
            for _ in 0..<10 {
                let result = self.router.autoBalance(state: state)
                state = self.router.applyRoutingResult(result, to: state)
            }
            
            let finalDiff = abs(state.lockerRoomEnergy - state.libraryWisdom)
            
            return finalDiff < 0.1 <?> "Repeated balancing should converge to near-equilibrium"
        }
    }
    
    // MARK: - Lyapunov Stability Properties
    
    func testEnergyDecreasesBoundedByLossRate() {
        property("Energy loss in any operation is bounded by maximum loss rate (20%)") <- forAll { (lockerEnergy: Double, libraryWisdom: Double, transferAmount: Double) in
            let normLocker = abs(lockerEnergy).truncatingRemainder(dividingBy: 1.0)
            let normLibrary = abs(libraryWisdom).truncatingRemainder(dividingBy: 1.0)
            let normTransfer = abs(transferAmount).truncatingRemainder(dividingBy: min(normLocker, 0.5))
            
            guard normTransfer > 0.001 else { return Discard() }
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: normLocker,
                libraryWisdom: normLibrary,
                bridgeStrength: 0.5
            )
            
            let result = self.router.blowLockerToLibrary(amount: normTransfer, state: initialState)
            
            guard result.success else { return Discard() }
            
            let newState = self.router.applyRoutingResult(result, to: initialState)
            
            let totalEnergyBefore = initialState.lockerRoomEnergy + initialState.libraryWisdom
            let totalEnergyAfter = newState.lockerRoomEnergy + newState.libraryWisdom
            let energyLoss = totalEnergyBefore - totalEnergyAfter
            let maxLossRate = 0.2 // From formal specification
            
            return energyLoss <= normTransfer * maxLossRate + 0.001 <?> "Energy loss exceeds maximum rate"
        }
    }
    
    // MARK: - State Immutability Properties
    
    func testRoutingDoesNotMutateState() {
        property("Routing operations never mutate the original state") <- forAll { (amount: Double) in
            let normAmount = abs(amount).truncatingRemainder(dividingBy: 0.2)
            
            let originalState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.5
            )
            
            let originalLocker = originalState.lockerRoomEnergy
            let originalLibrary = originalState.libraryWisdom
            let originalBridge = originalState.bridgeStrength
            
            // Perform multiple operations
            _ = self.router.blowLockerToLibrary(amount: normAmount, state: originalState)
            _ = self.router.suckLibraryToLocker(amount: normAmount, state: originalState)
            _ = self.router.autoBalance(state: originalState)
            
            // Original state should be unchanged
            return originalState.lockerRoomEnergy == originalLocker <?> "Locker energy mutated" ^&&^
                   originalState.libraryWisdom == originalLibrary <?> "Library wisdom mutated" ^&&^
                   originalState.bridgeStrength == originalBridge <?> "Bridge strength mutated"
        }
    }
    
    func testBridgeStrengthUnaffectedByRouting() {
        property("Router operations never change bridge strength") <- forAll { (amount: Double) in
            let normAmount = abs(amount).truncatingRemainder(dividingBy: 0.2)
            
            let initialState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: 0.7
            )
            
            let result = self.router.blowLockerToLibrary(amount: normAmount, state: initialState)
            let newState = self.router.applyRoutingResult(result, to: initialState)
            
            return newState.bridgeStrength == initialState.bridgeStrength <?> "Bridge strength should not change during routing"
        }
    }
}

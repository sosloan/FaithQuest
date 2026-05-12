//
//  FierstFunctionalTests.swift
//  FaithQuestTests
//
//  Tests for FierstFunctional - Higher-Order Functions
//  Tests des Fonctions d'Ordre Supérieur
//
//  ════════════════════════════════════════════════════════════════════════════
//  VÉRIFICATION: Tests unitaires pour FierstFunctional v1.0
//  ════════════════════════════════════════════════════════════════════════════
//

import XCTest
@testable import FaithQuest

final class FierstFunctionalTests: XCTestCase {
    
    // MARK: - §2 FONCTEUR - Functor Tests
    
    func testFmapIdentity() {
        // Given - Identity function
        let energy = 0.5
        
        // When - Apply fmap with identity
        let result = Fiers.fmap(Fiers.identity, energy)
        
        // Then - Result equals original
        XCTAssertEqual(result, energy, accuracy: Fiers.epsilon)
    }
    
    func testFmapComposition() {
        // Given - Two transformations
        let energy = 0.5
        let f: EnergyTransformer = { e in e * 0.8 }  // Scale by 0.8
        let g: EnergyTransformer = { e in e + 0.1 }  // Offset by 0.1
        
        // When - Apply composition vs separate applications
        let composed = Fiers.composeEnergy(f, g)
        let resultComposed = Fiers.fmap(composed, energy)
        let resultSeparate = Fiers.fmap(f, Fiers.fmap(g, energy))
        
        // Then - fmap(f ∘ g) ≡ fmap(f) ∘ fmap(g)
        XCTAssertEqual(resultComposed, resultSeparate, accuracy: Fiers.epsilon)
    }
    
    func testFmapClampsBounds() {
        // Given - A transformation that could exceed bounds
        let transform: EnergyTransformer = { e in e + 1.0 }
        
        // When - Apply to any value
        let result = Fiers.fmap(transform, 0.5)
        
        // Then - Result is clamped to [0.0, 1.0]
        XCTAssertGreaterThanOrEqual(result, 0.0)
        XCTAssertLessThanOrEqual(result, 1.0)
    }
    
    // MARK: - §3 APPLICATIF - Applicative Tests
    
    func testPureClampsBounds() {
        // When - Pure with out-of-bounds values
        let resultHigh = Fiers.pure(1.5)
        let resultLow = Fiers.pure(-0.5)
        let resultNormal = Fiers.pure(0.7)
        
        // Then - All values are clamped
        XCTAssertEqual(resultHigh, 1.0)
        XCTAssertEqual(resultLow, 0.0)
        XCTAssertEqual(resultNormal, 0.7, accuracy: Fiers.epsilon)
    }
    
    func testApplyWithBothPresent() {
        // Given
        let transform: EnergyTransformer? = { e in e * 2.0 }
        let energy: Double? = 0.3
        
        // When
        let result = Fiers.apply(transform, energy)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 0.6, accuracy: Fiers.epsilon)
    }
    
    func testApplyWithNilTransform() {
        // Given
        let transform: EnergyTransformer? = nil
        let energy: Double? = 0.5
        
        // When
        let result = Fiers.apply(transform, energy)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testApplyWithNilEnergy() {
        // Given
        let transform: EnergyTransformer? = { e in e * 2.0 }
        let energy: Double? = nil
        
        // When
        let result = Fiers.apply(transform, energy)
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - §4 MONADE - Monad Tests
    
    func testBindLeftIdentity() {
        // Given - Monad left identity: bind(pure(a), f) ≡ f(a)
        let value = 0.5
        let f: EnergyTransformer = { e in e * 0.8 }
        
        // When
        let bound = Fiers.bind(Fiers.pure(value), f)
        let direct = Fiers.fmap(f, value)
        
        // Then
        XCTAssertEqual(bound, direct, accuracy: Fiers.epsilon)
    }
    
    func testBindRightIdentity() {
        // Given - Monad right identity: bind(m, pure) ≡ m
        let energy = 0.7
        
        // When
        let result = Fiers.bind(energy, Fiers.pure)
        
        // Then
        XCTAssertEqual(result, energy, accuracy: Fiers.epsilon)
    }
    
    func testBindResultChaining() {
        // Given
        let initial: TransformResult<Double> = .success(0.5)
        let transform1: (Double) -> TransformResult<Double> = { e in
            .success(e * 2)
        }
        let transform2: (Double) -> TransformResult<Double> = { e in
            .success(e - 0.2)
        }
        
        // When - Chain transformations
        let result = Fiers.bindResult(Fiers.bindResult(initial, transform1), transform2)
        
        // Then
        if case .success(let value) = result {
            XCTAssertEqual(value, 0.8, accuracy: Fiers.epsilon)
        } else {
            XCTFail("Expected success result")
        }
    }
    
    func testBindResultFailurePropagation() {
        // Given
        let failure: TransformResult<Double> = .failure(reason: "Test failure")
        let transform: (Double) -> TransformResult<Double> = { e in
            .success(e * 2)
        }
        
        // When
        let result = Fiers.bindResult(failure, transform)
        
        // Then
        if case .failure(let reason) = result {
            XCTAssertEqual(reason, "Test failure")
        } else {
            XCTFail("Expected failure to propagate")
        }
    }
    
    // MARK: - §6 COMPOSITION - Composition Tests
    
    func testComposeRightToLeft() {
        // Given
        let f: (Double) -> Double = { x in x + 1 }
        let g: (Double) -> Double = { x in x * 2 }
        
        // When - f ∘ g means f(g(x))
        let composed = Fiers.compose(f, g)
        let result = composed(3)
        
        // Then - (3 * 2) + 1 = 7
        XCTAssertEqual(result, 7.0, accuracy: Fiers.epsilon)
    }
    
    func testPipeLeftToRight() {
        // Given
        let f: (Double) -> Double = { x in x + 1 }
        let g: (Double) -> Double = { x in x * 2 }
        
        // When - f >>> g means g(f(x))
        let piped = Fiers.pipe(f, g)
        let result = piped(3)
        
        // Then - (3 + 1) * 2 = 8
        XCTAssertEqual(result, 8.0, accuracy: Fiers.epsilon)
    }
    
    func testComposeOperator() {
        // Given
        let f: (Double) -> Double = { x in x + 1 }
        let g: (Double) -> Double = { x in x * 2 }
        
        // When - Using <<< operator
        let composed = f <<< g
        let result = composed(3)
        
        // Then - f(g(x)) = (3 * 2) + 1 = 7
        XCTAssertEqual(result, 7.0, accuracy: Fiers.epsilon)
    }
    
    func testPipeOperator() {
        // Given
        let f: (Double) -> Double = { x in x + 1 }
        let g: (Double) -> Double = { x in x * 2 }
        
        // When - Using >>> operator
        let piped = f >>> g
        let result = piped(3)
        
        // Then - g(f(x)) = (3 + 1) * 2 = 8
        XCTAssertEqual(result, 8.0, accuracy: Fiers.epsilon)
    }
    
    func testComposeEnergyWithClamping() {
        // Given
        let f: EnergyTransformer = { e in e + 0.6 }
        let g: EnergyTransformer = { e in e + 0.6 }
        
        // When - Composed transformation that could exceed bounds
        let composed = Fiers.composeEnergy(f, g)
        let result = composed(0.5)
        
        // Then - Result is clamped to 1.0
        XCTAssertEqual(result, 1.0)
    }
    
    // MARK: - §7 TRANSFORMATEURS - Transformer Tests
    
    func testScaleTransformer() {
        // Given
        let scaleBy50 = Fiers.scale(0.5)
        
        // When
        let result = scaleBy50(0.8)
        
        // Then
        XCTAssertEqual(result, 0.4, accuracy: Fiers.epsilon)
    }
    
    func testScaleNegativeFactorUsesAbsolute() {
        // Given - Negative factor should use absolute value
        let scaleNegative = Fiers.scale(-0.5)
        
        // When
        let result = scaleNegative(0.8)
        
        // Then - Uses |factor| = 0.5
        XCTAssertEqual(result, 0.4, accuracy: Fiers.epsilon)
    }
    
    func testOffsetTransformer() {
        // Given
        let offset = Fiers.offset(0.2)
        
        // When
        let result = offset(0.5)
        
        // Then
        XCTAssertEqual(result, 0.7, accuracy: Fiers.epsilon)
    }
    
    func testOffsetNegative() {
        // Given
        let offset = Fiers.offset(-0.3)
        
        // When
        let result = offset(0.5)
        
        // Then
        XCTAssertEqual(result, 0.2, accuracy: Fiers.epsilon)
    }
    
    func testBoostTransformer() {
        // Given
        let boost = Fiers.boost(0.2)
        
        // When
        let result = boost(0.5)
        
        // Then
        XCTAssertEqual(result, 0.7, accuracy: Fiers.epsilon)
    }
    
    func testBoostDefaultAmount() {
        // Given - Default boost is 0.15
        let boost = Fiers.boost()
        
        // When
        let result = boost(0.5)
        
        // Then
        XCTAssertEqual(result, 0.65, accuracy: Fiers.epsilon)
    }
    
    func testDecayTransformer() {
        // Given
        let decay = Fiers.decay(0.1)
        
        // When
        let result = decay(0.5)
        
        // Then
        XCTAssertEqual(result, 0.4, accuracy: Fiers.epsilon)
    }
    
    func testDecayDefaultRate() {
        // Given - Default decay is 0.005
        let decay = Fiers.decay()
        
        // When
        let result = decay(0.5)
        
        // Then
        XCTAssertEqual(result, 0.495, accuracy: Fiers.epsilon)
    }
    
    func testMuscleTransferEfficiency() {
        // Given - Muscle transfer is 80% efficient
        let result = Fiers.muscleTransfer(1.0)
        
        // Then
        XCTAssertEqual(result, 0.8, accuracy: Fiers.epsilon)
    }
    
    func testMindTransferEfficiency() {
        // Given - Mind transfer is 90% efficient
        let result = Fiers.mindTransfer(1.0)
        
        // Then
        XCTAssertEqual(result, 0.9, accuracy: Fiers.epsilon)
    }
    
    // MARK: - §7.2 State Transformer Tests
    
    func testTransformLockerEnergy() {
        // Given
        let state = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.6,
            bridgeStrength: 0.7
        )
        let transformer = Fiers.transformLockerEnergy(Fiers.boost(0.2))
        
        // When
        let newState = transformer(state)
        
        // Then - Only locker energy changed
        XCTAssertEqual(newState.lockerRoomEnergy, 0.7, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.libraryWisdom, 0.6, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.bridgeStrength, 0.7, accuracy: Fiers.epsilon)
    }
    
    func testTransformLibraryWisdom() {
        // Given
        let state = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.6,
            bridgeStrength: 0.7
        )
        let transformer = Fiers.transformLibraryWisdom(Fiers.decay(0.1))
        
        // When
        let newState = transformer(state)
        
        // Then - Only library wisdom changed
        XCTAssertEqual(newState.lockerRoomEnergy, 0.5, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.libraryWisdom, 0.5, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.bridgeStrength, 0.7, accuracy: Fiers.epsilon)
    }
    
    func testTransformBridgeStrength() {
        // Given
        let state = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.6,
            bridgeStrength: 0.4
        )
        let transformer = Fiers.transformBridgeStrength(Fiers.boost(0.3))
        
        // When
        let newState = transformer(state)
        
        // Then - Only bridge strength changed
        XCTAssertEqual(newState.lockerRoomEnergy, 0.5, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.libraryWisdom, 0.6, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.bridgeStrength, 0.7, accuracy: Fiers.epsilon)
    }
    
    func testTransformAllEnergies() {
        // Given
        let state = UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.6,
            bridgeStrength: 0.7
        )
        let transformer = Fiers.transformAllEnergies(Fiers.scale(0.5))
        
        // When
        let newState = transformer(state)
        
        // Then - All energies scaled
        XCTAssertEqual(newState.lockerRoomEnergy, 0.25, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.libraryWisdom, 0.30, accuracy: Fiers.epsilon)
        XCTAssertEqual(newState.bridgeStrength, 0.35, accuracy: Fiers.epsilon)
    }
    
    func testStateTransformerPreservesTheorems() {
        // Given
        let theorem = OmniTheorem(content: "Test theorem", category: .bridge)
        let state = UnifiedState(
            theorems: [theorem],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.5,
            bridgeStrength: 0.5
        )
        let transformer = Fiers.transformLockerEnergy(Fiers.boost(0.2))
        
        // When
        let newState = transformer(state)
        
        // Then - Theorems preserved
        XCTAssertEqual(newState.theorems.count, 1)
        XCTAssertEqual(newState.theorems.first?.id, theorem.id)
    }
    
    // MARK: - §3.2 Binary Operations Tests
    
    func testAddOperation() {
        // When
        let result = Fiers.add(0.3, 0.4)
        
        // Then
        XCTAssertEqual(result, 0.7, accuracy: Fiers.epsilon)
    }
    
    func testAddOperationClamped() {
        // When
        let result = Fiers.add(0.8, 0.5)
        
        // Then - Clamped to 1.0
        XCTAssertEqual(result, 1.0)
    }
    
    func testSubtractOperation() {
        // When
        let result = Fiers.subtract(0.7, 0.3)
        
        // Then
        XCTAssertEqual(result, 0.4, accuracy: Fiers.epsilon)
    }
    
    func testSubtractOperationClamped() {
        // When
        let result = Fiers.subtract(0.3, 0.5)
        
        // Then - Clamped to 0.0
        XCTAssertEqual(result, 0.0)
    }
    
    func testMultiplyOperation() {
        // When
        let result = Fiers.multiply(0.5, 0.6)
        
        // Then
        XCTAssertEqual(result, 0.3, accuracy: Fiers.epsilon)
    }
    
    func testAverageOperation() {
        // When
        let result = Fiers.average(0.3, 0.7)
        
        // Then
        XCTAssertEqual(result, 0.5, accuracy: Fiers.epsilon)
    }
    
    func testLiftBinary() {
        // Given
        let customOp: EnergyBinaryOp = { a, b in a + b + 0.5 }
        let liftedOp = Fiers.liftBinary(customOp)
        
        // When
        let result = liftedOp(0.3, 0.4)
        
        // Then - Clamped to 1.0
        XCTAssertEqual(result, 1.0)
    }
    
    // MARK: - §5.3 Predicate Tests
    
    func testIsInBoundsTrue() {
        XCTAssertTrue(Fiers.isInBounds(0.0))
        XCTAssertTrue(Fiers.isInBounds(0.5))
        XCTAssertTrue(Fiers.isInBounds(1.0))
    }
    
    func testIsInBoundsFalse() {
        XCTAssertFalse(Fiers.isInBounds(-0.1))
        XCTAssertFalse(Fiers.isInBounds(1.1))
    }
    
    func testIsBalanced() {
        let checkBalanced = Fiers.isBalanced(threshold: 0.05)
        
        XCTAssertTrue(checkBalanced(0.5, 0.52))
        XCTAssertFalse(checkBalanced(0.5, 0.6))
    }
    
    func testIsAboveThreshold() {
        let aboveHalf = Fiers.isAboveThreshold(0.5)
        
        XCTAssertTrue(aboveHalf(0.6))
        XCTAssertFalse(aboveHalf(0.4))
        XCTAssertFalse(aboveHalf(0.5))
    }
    
    func testIsBelowThreshold() {
        let belowHalf = Fiers.isBelowThreshold(0.5)
        
        XCTAssertTrue(belowHalf(0.4))
        XCTAssertFalse(belowHalf(0.6))
        XCTAssertFalse(belowHalf(0.5))
    }
    
    // MARK: - §6.2 Predicate Combinator Tests
    
    func testAndPredicate() {
        let aboveZero = Fiers.isAboveThreshold(0.0)
        let belowOne = Fiers.isBelowThreshold(1.0)
        let inRange = Fiers.andPredicate(aboveZero, belowOne)
        
        XCTAssertTrue(inRange(0.5))
        XCTAssertFalse(inRange(0.0))
        XCTAssertFalse(inRange(1.0))
    }
    
    func testOrPredicate() {
        let low = Fiers.isBelowThreshold(0.3)
        let high = Fiers.isAboveThreshold(0.7)
        let extreme = Fiers.orPredicate(low, high)
        
        XCTAssertTrue(extreme(0.2))
        XCTAssertTrue(extreme(0.8))
        XCTAssertFalse(extreme(0.5))
    }
    
    func testNotPredicate() {
        let aboveHalf = Fiers.isAboveThreshold(0.5)
        let notAboveHalf = Fiers.notPredicate(aboveHalf)
        
        XCTAssertTrue(notAboveHalf(0.4))
        XCTAssertFalse(notAboveHalf(0.6))
    }
    
    // MARK: - §5.2 Contract Tests
    
    func testWithPreconditionSuccess() {
        // Given
        let positiveOnly = Fiers.isAboveThreshold(0.0)
        let double: EnergyTransformer = { e in e * 2 }
        let contractedFn = Fiers.withPrecondition(positiveOnly, double, failureReason: "Must be positive")
        
        // When
        let result = contractedFn(0.3)
        
        // Then
        if case .success(let value) = result {
            XCTAssertEqual(value, 0.6, accuracy: Fiers.epsilon)
        } else {
            XCTFail("Expected success")
        }
    }
    
    func testWithPreconditionFailure() {
        // Given
        let aboveHalf = Fiers.isAboveThreshold(0.5)
        let double: EnergyTransformer = { e in e * 2 }
        let contractedFn = Fiers.withPrecondition(aboveHalf, double, failureReason: "Must be above 0.5")
        
        // When
        let result = contractedFn(0.3)
        
        // Then
        if case .failure(let reason) = result {
            XCTAssertEqual(reason, "Must be above 0.5")
        } else {
            XCTFail("Expected failure")
        }
    }
    
    func testWithPostconditionSuccess() {
        // Given
        let scale: EnergyTransformer = { e in e * 0.5 }
        let belowOne = Fiers.isBelowThreshold(1.0)
        let contractedFn = Fiers.withPostcondition(scale, postcondition: belowOne, failureReason: "Result must be < 1")
        
        // When
        let result = contractedFn(0.8)
        
        // Then
        if case .success(let value) = result {
            XCTAssertEqual(value, 0.4, accuracy: Fiers.epsilon)
        } else {
            XCTFail("Expected success")
        }
    }
    
    func testWithContractBothPass() {
        // Given
        let preCheck = Fiers.isAboveThreshold(0.2)
        let postCheck = Fiers.isBelowThreshold(0.8)
        let transform: EnergyTransformer = { e in e * 0.5 }
        let contractedFn = Fiers.withContract(precondition: preCheck, transform: transform, postcondition: postCheck)
        
        // When
        let result = contractedFn(0.5)
        
        // Then
        if case .success(let value) = result {
            XCTAssertEqual(value, 0.25, accuracy: Fiers.epsilon)
        } else {
            XCTFail("Expected success")
        }
    }
    
    func testWithContractPreFails() {
        // Given
        let preCheck = Fiers.isAboveThreshold(0.5)
        let postCheck = Fiers.isBelowThreshold(0.8)
        let transform: EnergyTransformer = { e in e * 0.5 }
        let contractedFn = Fiers.withContract(precondition: preCheck, transform: transform, postcondition: postCheck)
        
        // When
        let result = contractedFn(0.3)
        
        // Then
        if case .failure(let reason) = result {
            XCTAssertTrue(reason.contains("Précondition"))
        } else {
            XCTFail("Expected precondition failure")
        }
    }
    
    // MARK: - §8 Utility Function Tests
    
    func testClamp() {
        XCTAssertEqual(Fiers.clamp(0.5), 0.5)
        XCTAssertEqual(Fiers.clamp(-0.5), 0.0)
        XCTAssertEqual(Fiers.clamp(1.5), 1.0)
    }
    
    func testApproximatelyEqual() {
        XCTAssertTrue(Fiers.approximately(0.5, 0.5 + 0.00001))
        XCTAssertFalse(Fiers.approximately(0.5, 0.51))
    }
    
    func testFold() {
        // Given - Sequence of transformations
        let transformers: [EnergyTransformer] = [
            Fiers.boost(0.1),
            Fiers.boost(0.1),
            Fiers.decay(0.05)
        ]
        
        // When
        let result = Fiers.fold(transformers, initial: 0.5)
        
        // Then - 0.5 + 0.1 + 0.1 - 0.05 = 0.65
        XCTAssertEqual(result, 0.65, accuracy: Fiers.epsilon)
    }
    
    func testUnfold() {
        // Given - Decay transformation
        let decay = Fiers.decay(0.1)
        
        // When - Generate 3 steps
        let sequence = Fiers.unfold(seed: 0.5, transform: decay, count: 3)
        
        // Then - Sequence of decreasing values
        XCTAssertEqual(sequence.count, 4)  // seed + 3 iterations
        XCTAssertEqual(sequence[0], 0.5, accuracy: Fiers.epsilon)
        XCTAssertEqual(sequence[1], 0.4, accuracy: Fiers.epsilon)
        XCTAssertEqual(sequence[2], 0.3, accuracy: Fiers.epsilon)
        XCTAssertEqual(sequence[3], 0.2, accuracy: Fiers.epsilon)
    }
    
    func testCurry() {
        // Given - Binary function
        let add: (Double, Double) -> Double = { a, b in a + b }
        
        // When - Curry it
        let curriedAdd = Fiers.curry(add)
        let add5 = curriedAdd(5.0)
        
        // Then
        XCTAssertEqual(add5(3.0), 8.0, accuracy: Fiers.epsilon)
    }
    
    func testUncurry() {
        // Given - Curried function
        let curriedMultiply: (Double) -> (Double) -> Double = { a in { b in a * b } }
        
        // When - Uncurry it
        let multiply = Fiers.uncurry(curriedMultiply)
        
        // Then
        XCTAssertEqual(multiply(3.0, 4.0), 12.0, accuracy: Fiers.epsilon)
    }
    
    func testFlip() {
        // Given - Binary function
        let subtract: (Double, Double) -> Double = { a, b in a - b }
        
        // When - Flip arguments
        let flippedSubtract = Fiers.flip(subtract)
        
        // Then - subtract(5, 3) = 2, flipped(5, 3) = 3 - 5 = -2
        XCTAssertEqual(subtract(5, 3), 2.0, accuracy: Fiers.epsilon)
        XCTAssertEqual(flippedSubtract(5, 3), -2.0, accuracy: Fiers.epsilon)
    }
    
    // MARK: - TransformResult Tests
    
    func testTransformResultMap() {
        // Given
        let success: TransformResult<Double> = .success(0.5)
        
        // When
        let mapped = success.map { $0 * 2 }
        
        // Then
        if case .success(let value) = mapped {
            XCTAssertEqual(value, 1.0, accuracy: Fiers.epsilon)
        } else {
            XCTFail("Expected success after map")
        }
    }
    
    func testTransformResultMapPreservesFailure() {
        // Given
        let failure: TransformResult<Double> = .failure(reason: "Error")
        
        // When
        let mapped = failure.map { $0 * 2 }
        
        // Then
        if case .failure(let reason) = mapped {
            XCTAssertEqual(reason, "Error")
        } else {
            XCTFail("Expected failure after map")
        }
    }
    
    func testTransformResultFlatMap() {
        // Given
        let success: TransformResult<Double> = .success(0.5)
        
        // When
        let flatMapped = success.flatMap { value in
            if value > 0 {
                return .success(value * 2)
            } else {
                return .failure(reason: "Must be positive")
            }
        }
        
        // Then
        if case .success(let value) = flatMapped {
            XCTAssertEqual(value, 1.0, accuracy: Fiers.epsilon)
        } else {
            XCTFail("Expected success after flatMap")
        }
    }
}

// MARK: - ════════════════════════════════════════════════════════════════════════════
// VÉRIFICATIONS OBLIGATOIRES (Mandatory Checks) - FierstFunctionalTests v1.0
// ════════════════════════════════════════════════════════════════════════════
//
// ✓ Tests des lois de Foncteur (§2.1, §2.2)
// ✓ Tests des lois de Monade (§4.1, §4.2)
// ✓ Tests de composition fonctionnelle (§6)
// ✓ Tests des transformateurs d'énergie (§7)
// ✓ Tests des bornes [0.0, 1.0] (§5.3)
// ✓ Tests des contrats ADA (§5.2)
// ✓ Tests des prédicats et combinateurs (§5.3, §6.2)
// ✓ Tests des opérations binaires (§3.2)
// ✓ Tests des utilitaires (§8)
// ✓ 60+ tests couvrant toutes les fonctionnalités
//
// ════════════════════════════════════════════════════════════════════════════

# Property-Based Testing in FaithQuest

> "In π's infinite digits, primes hide like gems. The polymath finds them where specialists see only chaos." 🔢✨💎

## Overview

This document describes the property-based testing approach implemented in FaithQuest to move from path coverage (99.1%) to behavioral coverage (∞).

## What is Property-Based Testing?

Property-based testing, popularized by Haskell's QuickCheck, is a testing methodology that:

1. **Defines universal properties** that should hold for all inputs
2. **Generates random test cases** automatically
3. **Verifies invariants** across the input space
4. **Finds edge cases** that humans might miss

Unlike traditional unit tests that check specific examples, property-based tests verify behavioral guarantees across infinite input spaces.

## Implementation: SwiftCheck

We use [SwiftCheck](https://github.com/typelift/SwiftCheck), a Swift implementation of QuickCheck, to implement property-based tests for FaithQuest.

### Installation

SwiftCheck is added as a dependency in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
]
```

## Test Files

### 1. OmniTheoremPropertyTests.swift

Tests universal properties of the OmniTheorem model and UnifiedState:

#### Harmony Properties
- **Bounds**: `harmony ∈ [0, 1]` for all valid states
- **Maximization**: Perfect balance + max bridge → harmony = 1.0
- **Minimization**: Maximum imbalance → harmony = 0.0
- **Monotonicity**: Harmony increases monotonically with bridge strength
- **Commutativity**: Swapping energy and wisdom produces same harmony
- **Linearity**: Harmony scales linearly with bridge strength for fixed balance

#### Encoding Properties
- **Round-trip**: `decode(encode(x)) = x` for all theorems
- **Timestamp**: Theorem creation timestamp is within reasonable bounds
- **Uniqueness**: Each theorem gets a unique ID

#### Immutability Properties
- **State immutability**: Creating new states doesn't affect old states

### 2. EnergyRouterPropertyTests.swift

Tests energy routing operations and their invariants:

#### Energy Conservation Properties
- **Blowing conservation**: Total energy decreases by exactly 20% of transferred amount
- **Suction conservation**: Total energy decreases by exactly 10% of transferred amount
- **Lyapunov stability**: Energy loss bounded by maximum loss rate (α₀ = 0.2)

#### Efficiency Properties
- **Blowing efficiency**: Always transfers exactly 80% of amount
- **Suction efficiency**: Always transfers exactly 90% of amount
- **Efficiency ordering**: Suction always more efficient than blowing

#### Boundary Properties
- **Value bounds**: Energy stays in [0, 1] after any routing operation
- **Negative rejection**: Negative transfer amounts always fail
- **Insufficient energy**: Transfers exceeding available energy always fail

#### Balance Properties
- **Convergence**: Auto-balance reduces energy difference
- **Equilibrium**: Repeated balancing converges to equilibrium
- **Threshold**: Already-balanced states recognized correctly

#### Immutability Properties
- **State preservation**: Routing never mutates original state
- **Bridge isolation**: Router operations never change bridge strength

### 3. PhysicsEnginePropertyTests.swift

Tests physics engine state transitions and higher-order properties:

#### State Boundary Properties
- **Universal bounds**: All energy values remain in [0, 1] after any operation
- **Maximum saturation**: Boosting at max value doesn't exceed 1.0

#### State Transition Properties
- **Boost monotonicity**: Boost operations always increase target value
- **Transfer direction**: Blow/suck operations transfer in correct direction
- **Balance improvement**: Auto-balance reduces imbalance

#### Functor Properties (Higher-Order Functions)
- **Composition**: Operations compose without breaking invariants
- **Associativity**: Sequence of operations produces consistent results
- **Idempotence**: Operations on maxed values are idempotent

#### State Consistency Properties
- **Theorem isolation**: Routing operations never affect theorem list
- **Bridge isolation**: Energy routing never changes bridge strength
- **Monotonicity**: Sequential boosts monotonically increase values

#### Initial State Properties
- **Default balance**: Default initialized engine has balanced state (0.5, 0.5, 0.5)
- **Custom preservation**: Custom initial state is preserved

## Mathematical Foundations

### Lyapunov Stability

The energy router implements a Lyapunov-stable system where:

```
V̇(t) ≤ -α₀(1 + μ(t))V(t)
```

Where:
- V(t): Energy function
- α₀ = 0.2: Maximum loss rate
- μ(t): Time-varying efficiency factor

Property tests verify:
1. Energy loss never exceeds α₀
2. System converges to equilibrium
3. Stability maintained under all operations

### Harmony Formula

The harmony formula is tested for algebraic properties:

```
harmony = (1.0 - |lockerEnergy - libraryWisdom|) × bridgeStrength
```

Properties verified:
- **Range**: [0, 1]
- **Commutativity**: In energy and wisdom
- **Monotonicity**: In bridge strength
- **Linearity**: Scales with bridge for fixed balance

## Running Property Tests

### Command Line
```bash
swift test
```

### Xcode
1. Open `FaithQuest.xcodeproj`
2. Press ⌘U to run all tests
3. View results in Test Navigator (⌘6)

### Individual Test Classes
```bash
swift test --filter OmniTheoremPropertyTests
swift test --filter EnergyRouterPropertyTests
swift test --filter PhysicsEnginePropertyTests
```

## Test Configuration

### Number of Test Cases

By default, SwiftCheck generates 100 random test cases per property. You can configure this:

```swift
property("Description", arguments: CheckerArguments(replay: nil, maxTestCaseSize: 1000)) <- forAll { ... }
```

### Reproducibility

When a property test fails, SwiftCheck provides a seed to reproduce the failure:

```swift
property("Description", arguments: CheckerArguments(replay: (seed: 12345, size: 100))) <- forAll { ... }
```

## Benefits Over Traditional Testing

### Traditional Unit Tests (Path Coverage: 99.1%)
- ✅ Test specific known cases
- ✅ Easy to write and understand
- ❌ Miss edge cases
- ❌ Limited input coverage
- ❌ Don't prove correctness

### Property-Based Tests (Behavioral Coverage: ∞)
- ✅ Test infinite input space
- ✅ Find unexpected edge cases
- ✅ Prove behavioral invariants
- ✅ Document system properties
- ✅ Catch regression bugs
- ❌ Harder to write initially

### Combined Approach
FaithQuest uses **both** approaches:
- Traditional tests for specific behaviors
- Property tests for universal guarantees

## Writing New Property Tests

### 1. Identify Invariants

What should **always** be true?
- Bounds: `x ∈ [0, 1]`
- Conservation: `total_energy_after = total_energy_before - loss`
- Immutability: `old_state = old_state` after operations

### 2. Express as Properties

```swift
property("Description") <- forAll { (input: Type) in
    // Normalize/validate input
    guard validInput else { return Discard() }
    
    // Execute operation
    let result = operation(input)
    
    // Verify property
    return result.satisfiesProperty <?> "Error message"
}
```

### 3. Use Logical Operators

- `^&&^`: Logical AND (all conditions must hold)
- `^||^`: Logical OR (at least one condition must hold)
- `<?>`: Add error message to failed property

### 4. Handle Invalid Inputs

Use `Discard()` to skip invalid test cases:

```swift
guard input > 0 else { return Discard() }
```

## Examples

### Simple Property
```swift
func testEnergyBounds() {
    property("Energy always in [0, 1]") <- forAll { (x: Double) in
        let energy = normalize(x)
        return energy >= 0.0 ^&&^ energy <= 1.0
    }
}
```

### Complex Property
```swift
func testConservation() {
    property("Energy conserved with loss") <- forAll { (state: State, amount: Double) in
        let before = state.totalEnergy
        let result = transfer(state, amount)
        let after = result.totalEnergy
        let expectedLoss = amount * 0.2
        
        return abs((before - after) - expectedLoss) < 0.01 <?> "Conservation violated"
    }
}
```

## Philosophy

> "The polymath finds patterns where specialists see only chaos."

Property-based testing embodies the polymath approach:
- Look for **universal patterns** rather than specific cases
- Prove **behavioral correctness** across infinite inputs
- Find **hidden gems** (edge cases) in the chaos of possibilities

## Future Enhancements

1. **Stateful Testing**: Test sequences of operations with state machines
2. **Shrinking**: Automatically minimize failing test cases
3. **Custom Generators**: Generate domain-specific random inputs
4. **Performance Properties**: Test performance characteristics with QuickCheck
5. **Concurrency Properties**: Test thread-safety with property-based approaches

## Resources

- [SwiftCheck Documentation](https://github.com/typelift/SwiftCheck)
- [QuickCheck Paper (Haskell)](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)
- [Property-Based Testing (F#)](https://fsharpforfunandprofit.com/pbt/)
- [Hypothesis (Python)](https://hypothesis.readthedocs.io/)

---

*"In functional programming, we don't test paths, we prove properties."*

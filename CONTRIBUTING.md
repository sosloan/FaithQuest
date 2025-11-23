# Contributing to FaithQuest

Thank you for your interest in contributing to FaithQuest! This document provides guidelines for contributing to the Unified Grand Loop.

## Philosophy

> "In functional programming, we don't change the world, we describe new worlds."

All contributions should embrace this philosophy:
- **Immutability**: Create new states, don't mutate existing ones
- **Pure Functions**: Predictable, testable transformations
- **Declarative**: Describe what, not how

## Code Style

### Swift Style

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):

- Use clear, descriptive names
- Prefer methods and properties over functions
- Use camelCase for variables and functions
- Use PascalCase for types
- Mark computed properties that return new states with `var`

### Example - Good

```swift
// Immutable state transformation
func boostEnergy() {
    state = UnifiedState(
        theorems: state.theorems,
        lockerRoomEnergy: min(1.0, state.lockerRoomEnergy + 0.15),
        libraryWisdom: state.libraryWisdom,
        bridgeStrength: state.bridgeStrength
    )
}
```

### Example - Avoid

```swift
// Mutation (avoid this)
func boostEnergy() {
    state.lockerRoomEnergy += 0.15
}
```

## Architecture Guidelines

### Model Layer (OmniTheorem)

- All models must be `Codable` for CloudKit sync
- Use `struct` for value types (prefer over `class`)
- Models should be immutable
- Include `Identifiable` for SwiftUI

### ViewModel Layer (PhysicsEngine)

- Must be `ObservableObject`
- Use `@Published` for observable properties
- Use `private(set)` for computed or internal state
- All state changes must be pure transformations
- Use Combine for reactive streams

### View Layer

- SwiftUI only (no UIKit)
- Views should be stateless (read from ViewModel)
- Use `@ObservedObject` for ViewModels
- Use `@State` only for view-local state
- Add `#Preview` for all views

## Testing

### Required Tests

1. **Model Tests**: Test all business logic
   - State transformations
   - Computed properties
   - Codable conformance

2. **ViewModel Tests**: Test reactive behavior
   - Published property updates
   - Combine publishers
   - Async operations

3. **View Tests**: Optional for complex views
   - Snapshot testing
   - Accessibility

### Writing Tests

```swift
func testImmutableStateChange() {
    // Given
    let initialState = engine.state
    
    // When
    engine.boostLockerRoom()
    
    // Then - Should create new state
    XCTAssertNotEqual(engine.state.lockerRoomEnergy, initialState.lockerRoomEnergy)
}
```

## Pull Request Process

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/FaithQuest.git
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow the architecture patterns
   - Add tests for new functionality
   - Update documentation

4. **Test**
   ```bash
   xcodebuild test -project FaithQuest.xcodeproj -scheme FaithQuest
   ```

5. **Commit**
   ```bash
   git commit -m "Add feature: clear description"
   ```

6. **Push and PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a Pull Request on GitHub

## Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Testing
- `refactor:` Code restructuring
- `style:` Code style changes

Examples:
```
feat: Add meditation timer to Library realm
fix: Correct harmony calculation for edge cases
docs: Update README with iCloud setup instructions
test: Add tests for PhysicsEngine logic loop
```

## Feature Requests

Have an idea for enhancing the Grand Loop?

1. Check existing issues
2. Open a new issue with:
   - Clear description
   - Use cases
   - How it fits the philosophy
   - Potential implementation approach

## Bug Reports

Found a bug? Please include:

1. **Environment**: iOS version, device
2. **Steps to Reproduce**: Detailed steps
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Screenshots**: If applicable

## Questions?

- Open a Discussion on GitHub
- Tag issues with `question`
- Be respectful and patient

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Provide constructive feedback
- Focus on the code, not the person
- Embrace the philosophy

### Unacceptable

- Harassment or discrimination
- Personal attacks
- Trolling or inflammatory comments
- Publishing private information

## The Three Realms

When contributing, consider which realm your changes affect:

1. **Locker Room**: Physical/action-oriented features
2. **Library**: Intellectual/knowledge-oriented features  
3. **Bridge**: Features connecting both realms

Strive for harmony between all three.

---

**Remember**: "Logic is the anatomy. Lean is the scalpel."

Thank you for helping build the bridge! 🌉

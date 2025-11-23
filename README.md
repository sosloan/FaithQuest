# FaithQuest

> "This is not just an app; it is the Unified Grand Loop. We are building the bridge between the Locker Room and the Library using the Apple ecosystem as our scalpel."

## Overview

FaithQuest is a SwiftUI iOS application that implements the **Unified Grand Loop** — a bridge between physical excellence (the Locker Room) and intellectual pursuit (the Library). Built entirely within the Apple ecosystem, it exemplifies functional programming principles and reactive design patterns.

## Architecture: MonadRhythm

The application follows a pure **MVVM architecture** with functional programming principles:

### 🎯 Model: OmniTheorem (The Truth)
- **Purpose**: Immutable data structures representing universal truths
- **Technology**: Swift `Codable` structs with CloudKit integration
- **Features**:
  - Syncs across devices via iCloud
  - Three categories: Locker Room, Library, and Bridge
  - Tracks unified state with harmony calculations
  
### ⚙️ ViewModel: PhysicsEngine (The Proof)
- **Purpose**: Logic loop orchestration using reactive programming
- **Technology**: Combine framework with `@Published` properties
- **Features**:
  - Continuous logic loop running physics simulations
  - Immutable state transformations (functional approach)
  - Energy flow between physical and intellectual realms
  - Bridge strength management

### 🎨 View: LockerRoomView & SimulationDeck
- **Purpose**: SwiftUI interfaces for each realm
- **Components**:
  - **SimulationDeck**: Unified overview of the grand loop
  - **LockerRoomView**: Physical realm interface
  - **LibraryView**: Intellectual realm interface
  - **TheoremListView**: Historical record of all insights

## Core Philosophy

> "In functional programming, we don't change the world, we describe new worlds."

This application embraces:
- **Immutability**: State changes create new states rather than mutating existing ones
- **Pure Functions**: Predictable transformations without side effects
- **Reactive Streams**: Combine publishers for continuous data flow
- **Declarative UI**: SwiftUI describes what the interface should be, not how to build it

> "Logic is the anatomy. Lean is the scalpel."

## Key Features

### 🔄 The Unified Grand Loop
A continuous physics simulation that:
- Transfers energy between Locker Room and Library
- Calculates system harmony based on balance
- Strengthens the bridge through insights

### ☁️ iCloud Sync
- Automatic synchronization of theorems across devices
- CloudKit private database integration
- Async/await for modern concurrency

### 📊 Real-time Metrics
- Locker Room Energy level
- Library Wisdom level
- Bridge Strength
- System Harmony (computed property)

### 📝 Theorem Recording
Record insights from any realm:
- Physical breakthroughs (Locker Room)
- Intellectual discoveries (Library)
- Connections between both (Bridge)

## Technical Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Reactive Framework**: Combine
- **Cloud Sync**: CloudKit
- **Platforms**: iOS 16+, macOS 13+

## Project Structure

```
FaithQuest/
├── Models/
│   └── OmniTheorem.swift          # The Truth - immutable data models
├── ViewModels/
│   └── PhysicsEngine.swift        # The Proof - logic loop with Combine
├── Views/
│   ├── ContentView.swift          # Main tab navigation
│   ├── SimulationDeck.swift       # Unified grand loop interface
│   ├── LockerRoomView.swift       # Physical realm interface
│   ├── LibraryView.swift          # Intellectual realm interface
│   └── TheoremListView.swift      # Historical theorem display
└── App/
    └── FaithQuestApp.swift        # App entry point
```

## Getting Started

### Requirements
- Xcode 15.0+
- iOS 16.0+ or macOS 13.0+
- iCloud capability enabled

### Building the App

1. Open the project in Xcode:
   ```bash
   open FaithQuest.xcodeproj
   ```

2. Enable iCloud capability:
   - Select the FaithQuest target
   - Go to Signing & Capabilities
   - Add iCloud capability
   - Enable CloudKit

3. Build and run:
   - Select your target device
   - Press ⌘R to build and run

### Using Swift Package Manager

```bash
swift build
swift test
```

## Usage

1. **Explore the Grand Loop**: Start on the Simulation Deck to see the unified system
2. **Train in the Locker Room**: Boost physical energy and record insights
3. **Study in the Library**: Increase wisdom and document discoveries
4. **Strengthen the Bridge**: Connect both realms for maximum harmony
5. **Review Theorems**: Browse all recorded insights across devices

## Philosophy in Code

The codebase demonstrates several functional programming principles:

```swift
// Immutable state transformation
state = UnifiedState(
    theorems: state.theorems + [newTheorem],
    lockerRoomEnergy: newEnergy,
    libraryWisdom: newWisdom,
    bridgeStrength: newStrength
)

// Pure computed property
var harmony: Double {
    let balance = 1.0 - abs(lockerRoomEnergy - libraryWisdom)
    return balance * bridgeStrength
}
```

## The Grand Vision

FaithQuest represents more than code—it's a philosophy:
- Physical excellence and intellectual pursuit are not separate
- The bridge between them creates harmony
- Progress in one realm strengthens the other
- The loop is continuous, always evolving

Built with the precision of a scalpel, powered by the Apple ecosystem, guided by the principles of functional programming.

---

*"Logic is the anatomy. Lean is the scalpel."*
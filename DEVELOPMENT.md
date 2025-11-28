# Development Guide

## Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 16.0 SDK or later
- Active Apple Developer account (for device deployment)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/sosloan/FaithQuest.git
cd FaithQuest
```

### 2. Open in Xcode

```bash
open FaithQuest.xcodeproj
```

Or double-click `FaithQuest.xcodeproj` in Finder.

### 3. Configure Signing

1. Select the **FaithQuest** project in the navigator
2. Select the **FaithQuest** target
3. Go to **Signing & Capabilities**
4. Select your **Team** from the dropdown
5. Xcode will automatically configure signing

### 4. Enable iCloud

The app requires iCloud capability for cross-device sync:

1. In **Signing & Capabilities**, click **+ Capability**
2. Add **iCloud**
3. Enable **CloudKit**
4. Xcode will create a default CloudKit container

### 5. Build and Run

- **Simulator**: Select any iOS 16.0+ simulator and press ⌘R
- **Device**: Connect your iPhone/iPad and select it, then press ⌘R

## Project Structure

```
FaithQuest/
├── FaithQuest/
│   ├── App/
│   │   └── FaithQuestApp.swift       # App entry point
│   ├── Models/
│   │   ├── OmniTheorem.swift         # Data models & CloudKit sync
│   │   ├── EnergyRouter.swift        # Erlang/OTP-inspired router
│   │   └── AdminPanel.swift          # Protocol-oriented admin model
│   ├── ViewModels/
│   │   ├── PhysicsEngine.swift       # Business logic with Combine
│   │   └── AdminPanelViewModel.swift # Admin panel reactive controller
│   ├── Views/
│   │   ├── ContentView.swift         # Tab navigation
│   │   ├── SimulationDeck.swift      # Grand Loop visualization
│   │   ├── RouterControlView.swift   # Energy router control
│   │   ├── LockerRoomView.swift      # Physical realm
│   │   ├── LibraryView.swift         # Intellectual realm
│   │   ├── TheoremListView.swift     # Theorem history
│   │   └── AdminPanelView.swift      # Admin panel interface
│   ├── Assets.xcassets/              # Images and colors
│   └── Info.plist                    # App configuration
├── FaithQuestTests/
│   ├── OmniTheoremTests.swift        # Model tests
│   ├── PhysicsEngineTests.swift      # ViewModel tests
│   ├── EnergyRouterTests.swift       # Router unit tests
│   ├── AdminPanelTests.swift         # Admin panel unit tests
│   ├── EnergyRouterPropertyTests.swift  # Router property tests
│   ├── AdminPanelPropertyTests.swift    # Admin panel property tests
│   ├── OmniTheoremPropertyTests.swift   # Theorem property tests
│   └── PhysicsEnginePropertyTests.swift # Engine property tests
└── FaithQuest.xcodeproj/             # Xcode project
```

## Testing

### Run All Tests

```bash
# Command line
xcodebuild test \
  -project FaithQuest.xcodeproj \
  -scheme FaithQuest \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Or press ⌘U in Xcode
```

### Run Specific Tests

1. Open the Test navigator (⌘6)
2. Click the play button next to any test class or method

## Architecture

### MonadRhythm Pattern

The app follows a strict MVVM architecture with functional programming principles:

**Model (OmniTheorem)**: Immutable data structures
- `OmniTheorem`: Individual insights from any realm
- `UnifiedState`: The complete system state
- `CloudKitSyncManager`: Handles iCloud synchronization

**ViewModel (PhysicsEngine)**: Reactive business logic
- Uses Combine for reactive streams
- Implements continuous logic loop
- All state changes are pure transformations

**View**: SwiftUI declarative UI
- Four main views for different perspectives
- All views observe `PhysicsEngine` via `@ObservedObject`
- Tab-based navigation

### Key Principles

1. **Immutability**: Never mutate state, create new instances
2. **Pure Functions**: Predictable, testable transformations
3. **Reactive**: Combine publishers for data flow
4. **Declarative**: SwiftUI describes the UI state

## Building for Release

### 1. Archive the App

1. Select **Any iOS Device** as the destination
2. Product → Archive
3. Wait for the archive to complete

### 2. Distribute

1. In the Archives organizer, select your archive
2. Click **Distribute App**
3. Choose your distribution method:
   - **App Store Connect**: For public release
   - **Ad Hoc**: For testing on registered devices
   - **Development**: For personal testing

### 3. TestFlight (Optional)

For beta testing:
1. Upload to App Store Connect
2. Configure TestFlight settings
3. Invite testers via email or public link

## Debugging

### Common Issues

**"No such module 'SwiftUI'"**
- Ensure you're using Xcode, not command-line Swift on Linux
- SwiftUI is only available with iOS SDK

**CloudKit sync not working**
- Check iCloud capability is enabled
- Verify you're signed into iCloud on the device
- Check CloudKit Dashboard for container status

**Tests failing**
- Clean build folder: ⇧⌘K
- Reset simulator: Device → Erase All Content and Settings
- Check for timing issues in async tests

### Logging

The app uses standard print statements for debugging. To see logs:

1. Run the app
2. Open the Debug console (⇧⌘C)
3. Filter by "FaithQuest" to see app-specific logs

## Continuous Integration

The project includes multiple CI/CD systems:

### GitHub Actions
A GitHub Actions workflow (`.github/workflows/ios-build.yml`) that:
- Builds the app on macOS runners
- Runs all unit tests
- Reports build status

### Xcode Cloud
Comprehensive Xcode Cloud workflows (`.xcode/workflows/*.ci.yml`) designed to maximize monthly compute for intensive property-based testing:
- **Continuous**: Run on every push for fast feedback
- **Intensive**: Every 6 hours with 50K test iterations
- **Daily**: Comprehensive testing 2x per day
- **Nightly**: Marathon stress tests 2x per day
- **Weekly**: Ultra-intensive testing 2x per week

See [XCODE_CLOUD.md](XCODE_CLOUD.md) for complete configuration and compute optimization strategy.

## Contributing

When adding new features:

1. Follow the existing architecture patterns
2. Add unit tests for new logic
3. Use functional programming principles
4. Document complex algorithms
5. Update this guide if needed

## Swift Version

The project uses Swift 5.9+ with the following features:
- Async/await for concurrency
- Combine for reactive programming
- Property wrappers (@Published, @ObservedObject)
- Modern Swift concurrency (MainActor)

## Resources

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework Guide](https://developer.apple.com/documentation/combine)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

**Remember**: "In functional programming, we don't change the world, we describe new worlds."

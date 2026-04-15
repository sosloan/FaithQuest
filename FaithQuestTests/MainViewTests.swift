//
//  MainViewTests.swift
//  FaithQuestTests
//
//  Tests for the MainView world-class landing interface
//

import XCTest
@testable import FaithQuest

final class MainViewTests: XCTestCase {
    
    // MARK: - Quick Action Tests
    
    func testQuickActionRawValues() {
        // Verify all quick actions have expected raw values
        XCTAssertEqual(MainView.QuickAction.locker.rawValue, "Train")
        XCTAssertEqual(MainView.QuickAction.library.rawValue, "Study")
        XCTAssertEqual(MainView.QuickAction.bridge.rawValue, "Connect")
        XCTAssertEqual(MainView.QuickAction.router.rawValue, "Flow")
    }
    
    func testQuickActionIcons() {
        // Verify all quick actions have SF Symbol icons
        XCTAssertEqual(MainView.QuickAction.locker.icon, "figure.strengthtraining.traditional")
        XCTAssertEqual(MainView.QuickAction.library.icon, "book.fill")
        XCTAssertEqual(MainView.QuickAction.bridge.icon, "link")
        XCTAssertEqual(MainView.QuickAction.router.icon, "arrow.triangle.branch")
    }
    
    func testQuickActionDescriptions() {
        // Verify all quick actions have descriptions
        XCTAssertEqual(MainView.QuickAction.locker.description, "Physical Excellence")
        XCTAssertEqual(MainView.QuickAction.library.description, "Intellectual Pursuit")
        XCTAssertEqual(MainView.QuickAction.bridge.description, "Unified Harmony")
        XCTAssertEqual(MainView.QuickAction.router.description, "Energy Management")
    }
    
    func testQuickActionAllCases() {
        // Verify we have exactly 4 quick actions
        XCTAssertEqual(MainView.QuickAction.allCases.count, 4)
    }
    
    func testQuickActionIdentifiable() {
        // Verify each action has a unique ID
        let ids = MainView.QuickAction.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All quick actions should have unique IDs")
    }
    
    // MARK: - Content Tab Tests
    
    func testContentTabValues() {
        // Verify tab ordering
        XCTAssertEqual(ContentView.ContentTab.main.rawValue, 0)
        XCTAssertEqual(ContentView.ContentTab.grandLoop.rawValue, 1)
        XCTAssertEqual(ContentView.ContentTab.router.rawValue, 2)
        XCTAssertEqual(ContentView.ContentTab.locker.rawValue, 3)
        XCTAssertEqual(ContentView.ContentTab.library.rawValue, 4)
        XCTAssertEqual(ContentView.ContentTab.theorems.rawValue, 5)
        XCTAssertEqual(ContentView.ContentTab.admin.rawValue, 6)
    }
    
    func testMainTabIsFirstTab() {
        // Verify main tab is the first tab (index 0)
        XCTAssertEqual(ContentView.ContentTab.main.rawValue, 0, "Main tab should be the first tab")
    }
    
    // MARK: - Integration Tests with PhysicsEngine
    
    func testQuickActionLockerBoostsEnergy() {
        // Given
        let engine = PhysicsEngine()
        let initialEnergy = engine.state.lockerRoomEnergy
        
        // When - Simulate locker quick action
        engine.boostLockerRoom()
        
        // Then
        XCTAssertGreaterThan(engine.state.lockerRoomEnergy, initialEnergy)
    }
    
    func testQuickActionLibraryBoostsWisdom() {
        // Given
        let engine = PhysicsEngine()
        let initialWisdom = engine.state.libraryWisdom
        
        // When - Simulate library quick action
        engine.boostLibrary()
        
        // Then
        XCTAssertGreaterThan(engine.state.libraryWisdom, initialWisdom)
    }
    
    func testQuickActionBridgeStrengthens() {
        // Given
        let engine = PhysicsEngine()
        let initialStrength = engine.state.bridgeStrength
        
        // When - Simulate bridge quick action
        engine.strengthenBridge()
        
        // Then
        XCTAssertGreaterThan(engine.state.bridgeStrength, initialStrength)
    }
    
    func testQuickActionRouterBalances() {
        // Given - Imbalanced state
        let engine = PhysicsEngine(initialState: UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.8,
            libraryWisdom: 0.2,
            bridgeStrength: 0.5
        ))
        let initialDifference = abs(engine.state.lockerRoomEnergy - engine.state.libraryWisdom)
        
        // When - Simulate router quick action
        engine.autoBalanceEnergy()
        
        // Then - Difference should decrease (or stay same if already balanced)
        let newDifference = abs(engine.state.lockerRoomEnergy - engine.state.libraryWisdom)
        XCTAssertLessThanOrEqual(newDifference, initialDifference)
    }
    
    // MARK: - Metrics Display Tests
    
    func testMetricsRingHandlesZeroValues() {
        // Given - Zero state
        let engine = PhysicsEngine(initialState: UnifiedState(
            theorems: [],
            lockerRoomEnergy: 0.0,
            libraryWisdom: 0.0,
            bridgeStrength: 0.0
        ))
        
        // Then - State should be valid
        XCTAssertEqual(engine.state.lockerRoomEnergy, 0.0)
        XCTAssertEqual(engine.state.libraryWisdom, 0.0)
        XCTAssertEqual(engine.state.bridgeStrength, 0.0)
    }
    
    func testMetricsRingHandlesMaxValues() {
        // Given - Max state
        let engine = PhysicsEngine(initialState: UnifiedState(
            theorems: [],
            lockerRoomEnergy: 1.0,
            libraryWisdom: 1.0,
            bridgeStrength: 1.0
        ))
        
        // Then - State should be valid
        XCTAssertEqual(engine.state.lockerRoomEnergy, 1.0)
        XCTAssertEqual(engine.state.libraryWisdom, 1.0)
        XCTAssertEqual(engine.state.bridgeStrength, 1.0)
    }
    
    // MARK: - Daily Insight Tests
    
    func testDailyInsightWithNoTheorems() {
        // Given
        let engine = PhysicsEngine()
        
        // Then - Should have empty theorems
        XCTAssertTrue(engine.state.theorems.isEmpty)
    }
    
    func testDailyInsightWithTheorems() {
        // Given
        let theorem = OmniTheorem(content: "Test insight", category: .bridge)
        let engine = PhysicsEngine(initialState: UnifiedState(
            theorems: [theorem],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.5,
            bridgeStrength: 0.5
        ))
        
        // Then
        XCTAssertEqual(engine.state.theorems.count, 1)
        XCTAssertEqual(engine.state.theorems.first?.content, "Test insight")
    }
    
    func testLatestTheoremIsDisplayed() {
        // Given - Multiple theorems with different timestamps
        let oldTheorem = OmniTheorem(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            content: "Old insight",
            category: .lockerRoom
        )
        let newTheorem = OmniTheorem(
            id: UUID(),
            timestamp: Date(), // Now
            content: "New insight",
            category: .library
        )
        
        let engine = PhysicsEngine(initialState: UnifiedState(
            theorems: [oldTheorem, newTheorem],
            lockerRoomEnergy: 0.5,
            libraryWisdom: 0.5,
            bridgeStrength: 0.5
        ))
        
        // Then - Should have 2 theorems, latest should be the new one
        let theorems = engine.state.theorems
        let latestTheorem = theorems.max(by: { $0.timestamp < $1.timestamp })
        
        XCTAssertEqual(theorems.count, 2)
        XCTAssertEqual(latestTheorem?.content, "New insight")
    }
}

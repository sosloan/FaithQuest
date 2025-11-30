//
//  FaithQuestApp.swift
//  FaithQuest
//
//  The Unified Grand Loop
//  Building the bridge between the Locker Room and the Library
//
//  WORLD-CLASS APP ENTRY POINT:
//  - Elegant app initialization with proper lifecycle management
//  - Seamless iCloud sync on launch
//  - Intelligent scene phase handling
//  - Optimized for performance and user experience
//

import SwiftUI

@main
struct FaithQuestApp: App {
    // The Physics Engine - our single source of truth
    @StateObject private var engine = PhysicsEngine()
    @Environment(\.scenePhase) private var scenePhase
    
    /// App color scheme preference
    @AppStorage("prefersDarkMode") private var prefersDarkMode: Bool = true
    
    /// Track if initial sync has completed
    @State private var hasPerformedInitialSync: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(engine: engine)
                .preferredColorScheme(prefersDarkMode ? .dark : .light)
                .onAppear {
                    performInitialSetup()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Private Methods
    
    /// Perform initial app setup
    private func performInitialSetup() {
        guard !hasPerformedInitialSync else { return }
        hasPerformedInitialSync = true
        
        // Sync from iCloud on app launch
        Task {
            await engine.syncFromCloud()
        }
    }
    
    /// Handle scene phase changes for optimal performance
    /// - Parameter phase: The new scene phase
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App is active and visible
            engine.resumeLogicLoop()
            
        case .inactive:
            // App is inactive but still visible
            // Keep running for smooth transitions
            break
            
        case .background:
            // App is in background
            engine.pauseLogicLoop()
            
        @unknown default:
            break
        }
    }
}

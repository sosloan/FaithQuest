//
//  FaithQuestApp.swift
//  FaithQuest
//
//  The Unified Grand Loop
//  Building the bridge between the Locker Room and the Library
//

import SwiftUI

@main
struct FaithQuestApp: App {
    // The Physics Engine - our single source of truth
    @StateObject private var engine = PhysicsEngine()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView(engine: engine)
                .onAppear {
                    // Sync from iCloud on app launch
                    Task {
                        await engine.syncFromCloud()
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                engine.resumeLogicLoop()
            case .inactive, .background:
                engine.pauseLogicLoop()
            @unknown default:
                break
            }
        }
    }
}

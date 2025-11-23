//
//  PhysicsEngine.swift
//  FaithQuest
//
//  The Proof - ViewModel layer that runs the logic loop using Combine
//  Logic is the anatomy. Lean is the scalpel.
//

import Foundation
import Combine
import CloudKit

/// PhysicsEngine: The Proof
/// Runs the logic loop and orchestrates the unified grand loop
class PhysicsEngine: ObservableObject {
    // Published state - observable by views
    @Published private(set) var state: UnifiedState
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    private let syncManager = CloudKitSyncManager.shared
    
    // The logic loop timer - runs continuously
    private var loopTimer: AnyCancellable?
    private var isLoopActive: Bool = true
    
    // Physics constants
    private let energyTransferRate: Double = 0.01
    private let logicLoopInterval: TimeInterval = 1.0
    
    init(initialState: UnifiedState = UnifiedState()) {
        self.state = initialState
        setupLogicLoop()
    }
    
    // MARK: - Logic Loop
    
    /// Setup the continuous logic loop that processes the unified state
    private func setupLogicLoop() {
        // Run the logic loop periodically
        loopTimer = Timer.publish(every: logicLoopInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isLoopActive else { return }
                self.processLogicLoop()
            }
    }
    
    /// Pause the logic loop (for background state or battery saving)
    func pauseLogicLoop() {
        isLoopActive = false
    }
    
    /// Resume the logic loop
    func resumeLogicLoop() {
        isLoopActive = true
    }
    
    /// Process one iteration of the logic loop
    /// In functional programming, we describe new worlds rather than mutating the current one
    private func processLogicLoop() {
        // Apply physics: Energy flows between locker room and library
        let newLockerEnergy = min(1.0, state.lockerRoomEnergy + energyTransferRate * state.bridgeStrength)
        let newLibraryWisdom = min(1.0, state.libraryWisdom + energyTransferRate * state.bridgeStrength)
        
        // Create new state (functional approach - immutability)
        state = UnifiedState(
            theorems: state.theorems,
            lockerRoomEnergy: newLockerEnergy,
            libraryWisdom: newLibraryWisdom,
            bridgeStrength: state.bridgeStrength
        )
    }
    
    // MARK: - Theorem Operations
    
    /// Add a new theorem to the unified state
    func addTheorem(content: String, category: OmniTheorem.Category) async {
        let theorem = OmniTheorem(content: content, category: category)
        
        // Sync to iCloud
        do {
            try await syncManager.save(theorem)
            
            // Create new state with added theorem (functional approach)
            let newTheorems = state.theorems + [theorem]
            
            // Update bridge strength based on category
            let bridgeBoost = category == .bridge ? 0.1 : 0.05
            let newBridgeStrength = min(1.0, state.bridgeStrength + bridgeBoost)
            
            await MainActor.run {
                state = UnifiedState(
                    theorems: newTheorems,
                    lockerRoomEnergy: state.lockerRoomEnergy,
                    libraryWisdom: state.libraryWisdom,
                    bridgeStrength: newBridgeStrength
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save theorem: \(error.localizedDescription)"
            }
        }
    }
    
    /// Sync theorems from iCloud
    func syncFromCloud() async {
        await MainActor.run { isLoading = true }
        
        do {
            let theorems = try await syncManager.fetchTheorems()
            
            await MainActor.run {
                state = UnifiedState(
                    theorems: theorems,
                    lockerRoomEnergy: state.lockerRoomEnergy,
                    libraryWisdom: state.libraryWisdom,
                    bridgeStrength: state.bridgeStrength
                )
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to sync from iCloud: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Strengthen the bridge between locker room and library
    func strengthenBridge() {
        let boost = 0.2
        let newBridgeStrength = min(1.0, state.bridgeStrength + boost)
        
        state = UnifiedState(
            theorems: state.theorems,
            lockerRoomEnergy: state.lockerRoomEnergy,
            libraryWisdom: state.libraryWisdom,
            bridgeStrength: newBridgeStrength
        )
    }
    
    /// Boost locker room energy
    func boostLockerRoom() {
        let boost = 0.15
        let newEnergy = min(1.0, state.lockerRoomEnergy + boost)
        
        state = UnifiedState(
            theorems: state.theorems,
            lockerRoomEnergy: newEnergy,
            libraryWisdom: state.libraryWisdom,
            bridgeStrength: state.bridgeStrength
        )
    }
    
    /// Boost library wisdom
    func boostLibrary() {
        let boost = 0.15
        let newWisdom = min(1.0, state.libraryWisdom + boost)
        
        state = UnifiedState(
            theorems: state.theorems,
            lockerRoomEnergy: state.lockerRoomEnergy,
            libraryWisdom: newWisdom,
            bridgeStrength: state.bridgeStrength
        )
    }
}

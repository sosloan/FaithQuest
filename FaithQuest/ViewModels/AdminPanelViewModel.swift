//
//  AdminPanelViewModel.swift
//  FaithQuest
//
//  Admin Panel ViewModel - Reactive admin control using Combine
//  Protocol-oriented design with test-driven development
//
//  ARCHITECTURE:
//  - ObservableObject for SwiftUI integration
//  - Combine publishers for reactive updates
//  - Delegates to PhysicsEngine for state changes
//  - AdminPanelManager for command execution
//

import Foundation
import Combine

/// AdminPanelViewModel: Reactive interface for admin operations
/// Bridges admin commands to the physics engine
class AdminPanelViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current admin panel state
    @Published private(set) var adminState: AdminPanelState
    
    /// Last command result for UI feedback
    @Published private(set) var lastResult: AdminCommandResult?
    
    /// Whether a command is being processed
    @Published private(set) var isProcessing: Bool = false
    
    /// Error message for display
    @Published var errorMessage: String?
    
    /// Confirmation dialog state
    @Published var showConfirmation: Bool = false
    @Published var pendingCommand: AdminCommand?
    
    // MARK: - Private Properties
    
    /// Reference to the physics engine for state modifications
    private weak var engine: PhysicsEngine?
    
    /// Admin panel manager for command execution
    private let adminManager: AdminPanelManager
    
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Start time for uptime tracking
    private let startTime: Date
    
    // MARK: - Initialization
    
    init(engine: PhysicsEngine) {
        self.engine = engine
        self.adminManager = AdminPanelManager()
        self.adminState = adminManager.adminState
        self.startTime = Date()
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Request to execute a command (may show confirmation dialog)
    func requestCommand(_ command: AdminCommand) {
        if command.requiresConfirmation {
            pendingCommand = command
            showConfirmation = true
        } else {
            executeCommand(command)
        }
    }
    
    /// Confirm and execute pending command
    func confirmPendingCommand() {
        guard let command = pendingCommand else { return }
        executeCommand(command)
        pendingCommand = nil
        showConfirmation = false
    }
    
    /// Cancel pending command
    func cancelPendingCommand() {
        pendingCommand = nil
        showConfirmation = false
    }
    
    /// Execute an admin command
    func executeCommand(_ command: AdminCommand) {
        guard !isProcessing else { return }
        
        isProcessing = true
        errorMessage = nil
        
        // Execute command on admin manager
        let result = adminManager.execute(command)
        
        // Apply to physics engine if successful
        if result.success {
            applyToEngine(command)
        }
        
        // Update state
        lastResult = result
        adminState = adminManager.adminState
        isProcessing = false
        
        if !result.success {
            errorMessage = result.message
        }
    }
    
    /// Refresh metrics from current engine state
    func refreshMetrics() {
        guard let engine = engine else { return }
        
        let uptime = Date().timeIntervalSince(startTime)
        let metrics = AdminMetrics(from: engine.state, uptime: uptime)
        adminState.metrics = metrics
    }
    
    /// Check if command can be executed
    func canExecute(_ command: AdminCommand) -> Bool {
        return adminManager.canExecute(command) && !isProcessing
    }
    
    /// Get command history
    var commandHistory: [AdminCommandRecord] {
        return adminState.commandHistory
    }
    
    /// Get current metrics
    var metrics: AdminMetrics {
        return adminState.metrics
    }
    
    /// Check if debug mode is enabled
    var isDebugMode: Bool {
        return adminState.isDebugModeEnabled
    }
    
    // MARK: - Private Methods
    
    /// Set up Combine bindings
    private func setupBindings() {
        // Subscribe to engine state changes to refresh metrics
        engine?.$state
            .sink { [weak self] _ in
                self?.refreshMetrics()
            }
            .store(in: &cancellables)
    }
    
    /// Apply command effects to the physics engine
    private func applyToEngine(_ command: AdminCommand) {
        guard let engine = engine else { return }
        
        switch command {
        case .resetEnergy:
            // Reset energy levels to defaults
            let newState = UnifiedState(
                theorems: engine.state.theorems,
                lockerRoomEnergy: 0.5,
                libraryWisdom: 0.5,
                bridgeStrength: engine.state.bridgeStrength
            )
            updateEngineState(newState)
            
        case .resetState:
            // Reset entire state
            let newState = UnifiedState()
            updateEngineState(newState)
            
        case .forceSync:
            // Trigger iCloud sync
            Task {
                await engine.syncFromCloud()
            }
            
        case .toggleDebugMode:
            // Debug mode is tracked in admin state, no engine change needed
            break
            
        case .exportMetrics:
            // Export handled separately
            break
            
        case .setEnergyLevel(let realm, let level):
            let clampedLevel = max(0.0, min(1.0, level))
            var newState = engine.state
            switch realm {
            case .lockerRoom:
                newState = UnifiedState(
                    theorems: engine.state.theorems,
                    lockerRoomEnergy: clampedLevel,
                    libraryWisdom: engine.state.libraryWisdom,
                    bridgeStrength: engine.state.bridgeStrength
                )
            case .library:
                newState = UnifiedState(
                    theorems: engine.state.theorems,
                    lockerRoomEnergy: engine.state.lockerRoomEnergy,
                    libraryWisdom: clampedLevel,
                    bridgeStrength: engine.state.bridgeStrength
                )
            case .bridge:
                newState = UnifiedState(
                    theorems: engine.state.theorems,
                    lockerRoomEnergy: engine.state.lockerRoomEnergy,
                    libraryWisdom: engine.state.libraryWisdom,
                    bridgeStrength: clampedLevel
                )
            }
            updateEngineState(newState)
            
        case .setBridgeStrength(let level):
            let clampedLevel = max(0.0, min(1.0, level))
            let newState = UnifiedState(
                theorems: engine.state.theorems,
                lockerRoomEnergy: engine.state.lockerRoomEnergy,
                libraryWisdom: engine.state.libraryWisdom,
                bridgeStrength: clampedLevel
            )
            updateEngineState(newState)
            
        case .clearTheorems:
            let newState = UnifiedState(
                theorems: [],
                lockerRoomEnergy: engine.state.lockerRoomEnergy,
                libraryWisdom: engine.state.libraryWisdom,
                bridgeStrength: engine.state.bridgeStrength
            )
            updateEngineState(newState)
            
        case .generateTestData(let count):
            generateTestTheorems(count: count)
        }
    }
    
    /// Update engine state on main queue for thread safety
    private func updateEngineState(_ newState: UnifiedState) {
        Task { @MainActor in
            engine?.resetState(to: newState)
        }
    }
    
    /// Generate test theorems for debugging
    private func generateTestTheorems(count: Int) {
        guard let engine = engine else { return }
        
        let categories: [OmniTheorem.Category] = [.lockerRoom, .library, .bridge]
        let sampleContents = [
            "Physical training insight #",
            "Intellectual discovery #",
            "Mind-body connection #",
            "Strength building principle #",
            "Knowledge synthesis #"
        ]
        
        Task {
            for i in 0..<count {
                let category = categories[i % categories.count]
                let contentIndex = i % sampleContents.count
                let content = "\(sampleContents[contentIndex])\(i + 1)"
                await engine.addTheorem(content: content, category: category)
            }
        }
    }
}

// MARK: - PhysicsEngine Extension for Admin Operations

extension PhysicsEngine {
    /// Reset state to a new value (for admin operations)
    /// This method enables admin control over the engine state
    /// Must be called on the main queue to ensure thread safety
    @MainActor
    func resetState(to newState: UnifiedState) {
        // Pause the loop during reset
        pauseLogicLoop()
        
        // Apply new state
        state = newState
        
        // Resume the loop
        resumeLogicLoop()
    }
}

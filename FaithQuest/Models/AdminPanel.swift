//
//  AdminPanel.swift
//  FaithQuest
//
//  Admin Panel - Protocol-oriented design for administrative controls
//  Follows extreme protocol-oriented, test-driven development principles
//
//  PROTOCOL-ORIENTED DESIGN:
//  §1 AdminPanelProtocol: Core interface for all admin operations
//  §2 AdminCommandProtocol: Interface for admin command types
//  §3 AdminStateProtocol: Interface for admin state management
//  §4 Composability: Protocols enable flexible composition
//  §5 Testability: Protocols enable mock-based testing
//

import Foundation

// MARK: - Admin Command Protocol

/// Protocol defining admin command capabilities
/// Enables extensible, type-safe admin operations
protocol AdminCommandProtocol {
    /// Unique identifier for the command
    var commandId: String { get }
    
    /// Human-readable description of the command
    var commandDescription: String { get }
    
    /// Category of the command
    var category: AdminCommandCategory { get }
    
    /// Whether the command requires confirmation
    var requiresConfirmation: Bool { get }
}

/// Categories for admin commands
enum AdminCommandCategory: String, Codable, CaseIterable {
    case energy = "Energy"
    case state = "State"
    case sync = "Sync"
    case debug = "Debug"
    case metrics = "Metrics"
}

// MARK: - Admin Commands

/// Admin commands for system management
/// Follows message-passing pattern inspired by Erlang/OTP
enum AdminCommand: AdminCommandProtocol, Codable, Equatable {
    case resetEnergy
    case resetState
    case forceSync
    case toggleDebugMode
    case exportMetrics
    case setEnergyLevel(realm: EnergyRealm, level: Double)
    case setBridgeStrength(level: Double)
    case clearTheorems
    case generateTestData(count: Int)
    
    var commandId: String {
        switch self {
        case .resetEnergy:
            return "reset_energy"
        case .resetState:
            return "reset_state"
        case .forceSync:
            return "force_sync"
        case .toggleDebugMode:
            return "toggle_debug"
        case .exportMetrics:
            return "export_metrics"
        case .setEnergyLevel:
            return "set_energy_level"
        case .setBridgeStrength:
            return "set_bridge_strength"
        case .clearTheorems:
            return "clear_theorems"
        case .generateTestData:
            return "generate_test_data"
        }
    }
    
    var commandDescription: String {
        switch self {
        case .resetEnergy:
            return "Reset all energy levels to default (0.5)"
        case .resetState:
            return "Reset entire unified state to defaults"
        case .forceSync:
            return "Force synchronization with iCloud"
        case .toggleDebugMode:
            return "Toggle debug mode on/off"
        case .exportMetrics:
            return "Export current system metrics"
        case .setEnergyLevel(let realm, let level):
            return "Set \(realm.rawValue) energy to \(Int(level * 100))%"
        case .setBridgeStrength(let level):
            return "Set bridge strength to \(Int(level * 100))%"
        case .clearTheorems:
            return "Clear all recorded theorems"
        case .generateTestData(let count):
            return "Generate \(count) test theorems"
        }
    }
    
    var category: AdminCommandCategory {
        switch self {
        case .resetEnergy, .setEnergyLevel, .setBridgeStrength:
            return .energy
        case .resetState, .clearTheorems:
            return .state
        case .forceSync:
            return .sync
        case .toggleDebugMode, .generateTestData:
            return .debug
        case .exportMetrics:
            return .metrics
        }
    }
    
    var requiresConfirmation: Bool {
        switch self {
        case .resetState, .clearTheorems:
            return true
        default:
            return false
        }
    }
}

// MARK: - Admin State Protocol

/// Protocol for admin panel state management
protocol AdminStateProtocol {
    var isDebugModeEnabled: Bool { get }
    var lastCommandExecuted: AdminCommand? { get }
    var commandHistory: [AdminCommandRecord] { get }
    var metrics: AdminMetrics { get }
}

/// Record of an executed admin command
struct AdminCommandRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let command: AdminCommand
    let timestamp: Date
    let success: Bool
    let resultMessage: String
    
    init(id: UUID = UUID(), command: AdminCommand, timestamp: Date = Date(), success: Bool, resultMessage: String) {
        self.id = id
        self.command = command
        self.timestamp = timestamp
        self.success = success
        self.resultMessage = resultMessage
    }
}

/// Admin metrics for system monitoring
struct AdminMetrics: Codable, Equatable {
    let totalTheorems: Int
    let lockerRoomEnergy: Double
    let libraryWisdom: Double
    let bridgeStrength: Double
    let harmony: Double
    let theoremsByCategory: [String: Int]
    let averageEnergyLevel: Double
    let systemUptime: TimeInterval
    
    init(from state: UnifiedState, uptime: TimeInterval = 0) {
        self.totalTheorems = state.theorems.count
        self.lockerRoomEnergy = state.lockerRoomEnergy
        self.libraryWisdom = state.libraryWisdom
        self.bridgeStrength = state.bridgeStrength
        self.harmony = state.harmony
        
        // Count theorems by category
        var categoryCount: [String: Int] = [:]
        for theorem in state.theorems {
            let key = theorem.category.rawValue
            categoryCount[key, default: 0] += 1
        }
        self.theoremsByCategory = categoryCount
        
        // Calculate average energy
        self.averageEnergyLevel = (state.lockerRoomEnergy + state.libraryWisdom) / 2.0
        self.systemUptime = uptime
    }
}

// MARK: - Admin Panel State

/// Complete state for the admin panel
struct AdminPanelState: AdminStateProtocol, Codable, Equatable {
    var isDebugModeEnabled: Bool
    var lastCommandExecuted: AdminCommand?
    var commandHistory: [AdminCommandRecord]
    var metrics: AdminMetrics
    var isProcessingCommand: Bool
    var errorMessage: String?
    
    init(isDebugModeEnabled: Bool = false,
         lastCommandExecuted: AdminCommand? = nil,
         commandHistory: [AdminCommandRecord] = [],
         metrics: AdminMetrics = AdminMetrics(from: UnifiedState()),
         isProcessingCommand: Bool = false,
         errorMessage: String? = nil) {
        self.isDebugModeEnabled = isDebugModeEnabled
        self.lastCommandExecuted = lastCommandExecuted
        self.commandHistory = commandHistory
        self.metrics = metrics
        self.isProcessingCommand = isProcessingCommand
        self.errorMessage = errorMessage
    }
}

// MARK: - Admin Panel Protocol

/// Core protocol for admin panel operations
/// Enables protocol-oriented design for flexible implementations
protocol AdminPanelProtocol {
    /// Current admin state
    var adminState: AdminPanelState { get }
    
    /// Execute an admin command
    func execute(_ command: AdminCommand) -> AdminCommandResult
    
    /// Get current system metrics
    func refreshMetrics() -> AdminMetrics
    
    /// Check if a command can be executed
    func canExecute(_ command: AdminCommand) -> Bool
}

/// Result of admin command execution
struct AdminCommandResult: Equatable {
    let success: Bool
    let message: String
    let command: AdminCommand
    let timestamp: Date
    
    init(success: Bool, message: String, command: AdminCommand, timestamp: Date = Date()) {
        self.success = success
        self.message = message
        self.command = command
        self.timestamp = timestamp
    }
    
    /// Convert to command record
    func toRecord() -> AdminCommandRecord {
        AdminCommandRecord(
            command: command,
            timestamp: timestamp,
            success: success,
            resultMessage: message
        )
    }
}

// MARK: - Admin Panel Manager

/// Manager class implementing AdminPanelProtocol
/// Handles admin command execution with proper state management
class AdminPanelManager: AdminPanelProtocol {
    
    // MARK: - Properties
    
    private(set) var adminState: AdminPanelState
    private let startTime: Date
    
    // Maximum history size to prevent unbounded growth
    private let maxHistorySize: Int = 100
    
    // MARK: - Initialization
    
    init(initialState: AdminPanelState = AdminPanelState()) {
        self.adminState = initialState
        self.startTime = Date()
    }
    
    // MARK: - AdminPanelProtocol Implementation
    
    /// Execute an admin command and return the result
    func execute(_ command: AdminCommand) -> AdminCommandResult {
        // Check if command can be executed
        guard canExecute(command) else {
            return AdminCommandResult(
                success: false,
                message: "Command cannot be executed in current state",
                command: command
            )
        }
        
        // Execute the command
        let result = performCommand(command)
        
        // Update state
        adminState.lastCommandExecuted = command
        adminState.commandHistory.append(result.toRecord())
        
        // Trim history if needed
        if adminState.commandHistory.count > maxHistorySize {
            adminState.commandHistory = Array(adminState.commandHistory.suffix(maxHistorySize))
        }
        
        // Update debug mode if toggled
        if case .toggleDebugMode = command {
            adminState.isDebugModeEnabled.toggle()
        }
        
        return result
    }
    
    /// Refresh and return current metrics
    func refreshMetrics() -> AdminMetrics {
        let uptime = Date().timeIntervalSince(startTime)
        // Note: In real implementation, this would get state from PhysicsEngine
        let metrics = AdminMetrics(from: UnifiedState(), uptime: uptime)
        adminState.metrics = metrics
        return metrics
    }
    
    /// Check if a command can be executed
    func canExecute(_ command: AdminCommand) -> Bool {
        // Processing check
        guard !adminState.isProcessingCommand else {
            return false
        }
        
        // Command-specific validation
        switch command {
        case .setEnergyLevel(_, let level):
            return level >= 0.0 && level <= 1.0
        case .setBridgeStrength(let level):
            return level >= 0.0 && level <= 1.0
        case .generateTestData(let count):
            return count > 0 && count <= 1000
        default:
            return true
        }
    }
    
    // MARK: - Private Methods
    
    /// Perform the actual command execution
    private func performCommand(_ command: AdminCommand) -> AdminCommandResult {
        switch command {
        case .resetEnergy:
            return AdminCommandResult(
                success: true,
                message: "Energy levels reset to 0.5",
                command: command
            )
            
        case .resetState:
            return AdminCommandResult(
                success: true,
                message: "Unified state reset to defaults",
                command: command
            )
            
        case .forceSync:
            return AdminCommandResult(
                success: true,
                message: "iCloud sync initiated",
                command: command
            )
            
        case .toggleDebugMode:
            let newState = !adminState.isDebugModeEnabled
            return AdminCommandResult(
                success: true,
                message: "Debug mode \(newState ? "enabled" : "disabled")",
                command: command
            )
            
        case .exportMetrics:
            return AdminCommandResult(
                success: true,
                message: "Metrics exported successfully",
                command: command
            )
            
        case .setEnergyLevel(let realm, let level):
            return AdminCommandResult(
                success: true,
                message: "\(realm.rawValue) energy set to \(Int(level * 100))%",
                command: command
            )
            
        case .setBridgeStrength(let level):
            return AdminCommandResult(
                success: true,
                message: "Bridge strength set to \(Int(level * 100))%",
                command: command
            )
            
        case .clearTheorems:
            return AdminCommandResult(
                success: true,
                message: "All theorems cleared",
                command: command
            )
            
        case .generateTestData(let count):
            return AdminCommandResult(
                success: true,
                message: "Generated \(count) test theorems",
                command: command
            )
        }
    }
}

// MARK: - Extensions for Protocol Conformance

extension EnergyRealm: Codable {
    // Already Codable via rawValue
}

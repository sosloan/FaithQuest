//
//  OmniTheorem.swift
//  FaithQuestCore
//
//  The Truth - Model layer representing the Unified Grand Loop
//  In functional programming, we don't change the world, we describe new worlds.
//

import Foundation

/// OmniTheorem: The Truth
/// Represents immutable truth that can be synced across devices
public struct OmniTheorem: Codable, Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let content: String
    public let category: Category
    
    public enum Category: String, Codable, CaseIterable, Sendable {
        case lockerRoom    // The physical realm
        case library       // The intellectual realm
        case bridge        // The connection between both
    }
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), content: String, category: Category) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.category = category
    }
}

/// Represents the state of the unified grand loop
public struct UnifiedState: Codable, Equatable, Sendable {
    public let theorems: [OmniTheorem]
    public let lockerRoomEnergy: Double
    public let libraryWisdom: Double
    public let bridgeStrength: Double
    
    /// Computed property: The balance between physical and intellectual
    public var harmony: Double {
        let balance = 1.0 - abs(lockerRoomEnergy - libraryWisdom)
        return balance * bridgeStrength
    }
    
    public init(theorems: [OmniTheorem] = [], 
         lockerRoomEnergy: Double = 0.5, 
         libraryWisdom: Double = 0.5, 
         bridgeStrength: Double = 0.5) {
        self.theorems = theorems
        self.lockerRoomEnergy = lockerRoomEnergy
        self.libraryWisdom = libraryWisdom
        self.bridgeStrength = bridgeStrength
    }
}

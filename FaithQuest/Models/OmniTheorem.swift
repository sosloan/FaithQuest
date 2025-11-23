//
//  OmniTheorem.swift
//  FaithQuest
//
//  The Truth - Model layer that syncs via iCloud
//  In functional programming, we don't change the world, we describe new worlds.
//

import Foundation
import CloudKit

/// OmniTheorem: The Truth
/// Represents immutable truth that syncs across devices via iCloud
struct OmniTheorem: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let content: String
    let category: Category
    
    enum Category: String, Codable {
        case lockerRoom    // The physical realm
        case library       // The intellectual realm
        case bridge        // The connection between both
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), content: String, category: Category) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.category = category
    }
}

/// Represents the state of the unified grand loop
struct UnifiedState: Codable {
    let theorems: [OmniTheorem]
    let lockerRoomEnergy: Double
    let libraryWisdom: Double
    let bridgeStrength: Double
    
    /// Computed property: The balance between physical and intellectual
    var harmony: Double {
        let balance = 1.0 - abs(lockerRoomEnergy - libraryWisdom)
        return balance * bridgeStrength
    }
    
    init(theorems: [OmniTheorem] = [], 
         lockerRoomEnergy: Double = 0.5, 
         libraryWisdom: Double = 0.5, 
         bridgeStrength: Double = 0.5) {
        self.theorems = theorems
        self.lockerRoomEnergy = lockerRoomEnergy
        self.libraryWisdom = libraryWisdom
        self.bridgeStrength = bridgeStrength
    }
}

/// CloudKit manager for syncing OmniTheorem across devices
class CloudKitSyncManager {
    static let shared = CloudKitSyncManager()
    private let container = CKContainer.default()
    private let recordType = "OmniTheorem"
    
    private init() {}
    
    /// Save a theorem to iCloud
    func save(_ theorem: OmniTheorem) async throws {
        let record = CKRecord(recordType: recordType)
        record["id"] = theorem.id.uuidString as CKRecordValue
        record["timestamp"] = theorem.timestamp as CKRecordValue
        record["content"] = theorem.content as CKRecordValue
        record["category"] = theorem.category.rawValue as CKRecordValue
        
        let database = container.privateCloudDatabase
        try await database.save(record)
    }
    
    /// Fetch all theorems from iCloud
    func fetchTheorems() async throws -> [OmniTheorem] {
        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let results = try await database.records(matching: query)
        
        return results.matchResults.compactMap { _, result in
            guard let record = try? result.get(),
                  let idString = record["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let timestamp = record["timestamp"] as? Date,
                  let content = record["content"] as? String,
                  let categoryString = record["category"] as? String,
                  let category = OmniTheorem.Category(rawValue: categoryString) else {
                return nil
            }
            
            return OmniTheorem(id: id, timestamp: timestamp, content: content, category: category)
        }
    }
}

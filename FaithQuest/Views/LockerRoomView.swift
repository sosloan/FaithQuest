//
//  LockerRoomView.swift
//  FaithQuest
//
//  The Locker Room - Physical realm interface
//

import SwiftUI

/// LockerRoomView: Interface for the physical realm
struct LockerRoomView: View {
    @ObservedObject var engine: PhysicsEngine
    @State private var newTheoremContent: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("🏋️ Locker Room")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("The Physical Realm")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Energy meter
            VStack(alignment: .leading, spacing: 8) {
                Text("Energy Level")
                    .font(.headline)
                
                ProgressView(value: engine.state.lockerRoomEnergy, total: 1.0)
                    .tint(.orange)
                
                Text("\(Int(engine.state.lockerRoomEnergy * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            // Action button
            Button(action: {
                engine.boostLockerRoom()
            }) {
                Label("Train Harder", systemImage: "figure.strengthtraining.traditional")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            
            // Add theorem from locker room
            VStack(alignment: .leading, spacing: 8) {
                Text("Record Physical Insight")
                    .font(.headline)
                
                TextField("What did you learn?", text: $newTheoremContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    Task {
                        await engine.addTheorem(content: newTheoremContent, category: .lockerRoom)
                        newTheoremContent = ""
                    }
                }) {
                    Text("Record")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
                .disabled(newTheoremContent.isEmpty)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}

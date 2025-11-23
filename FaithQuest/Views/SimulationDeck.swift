//
//  SimulationDeck.swift
//  FaithQuest
//
//  The Bridge - Unified interface showing the grand loop
//

import SwiftUI

/// SimulationDeck: The unified interface showing the entire system
struct SimulationDeck: View {
    @ObservedObject var engine: PhysicsEngine
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("🌉 Simulation Deck")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("The Unified Grand Loop")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Harmony indicator
            VStack(spacing: 12) {
                Text("System Harmony")
                    .font(.headline)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: engine.state.harmony)
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: engine.state.harmony)
                    
                    VStack {
                        Text("\(Int(engine.state.harmony * 100))%")
                            .font(.system(size: 48, weight: .bold))
                        Text("Harmony")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 200, height: 200)
            }
            .padding()
            
            // System status
            VStack(spacing: 16) {
                HStack {
                    Label("Locker Room", systemImage: "figure.strengthtraining.traditional")
                    Spacer()
                    Text("\(Int(engine.state.lockerRoomEnergy * 100))%")
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Label("Library", systemImage: "book.fill")
                    Spacer()
                    Text("\(Int(engine.state.libraryWisdom * 100))%")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Label("Bridge", systemImage: "arrow.left.arrow.right")
                    Spacer()
                    Text("\(Int(engine.state.bridgeStrength * 100))%")
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Bridge strengthening
            Button(action: {
                engine.strengthenBridge()
            }) {
                Label("Strengthen Bridge", systemImage: "link")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            
            // Theorems count
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
                Text("\(engine.state.theorems.count) Theorems Recorded")
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SimulationDeck(engine: PhysicsEngine())
}

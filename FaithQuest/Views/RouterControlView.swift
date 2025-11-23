//
//  RouterControlView.swift
//  FaithQuest
//
//  Router Control Panel - Demonstrates Erlang/OTP inspired routing
//  With Blowing (push) and Suction (pull) mechanics
//

import SwiftUI

/// RouterControlView: Interface for the EnergyRouter
/// Allows direct control over energy flows with Blowing and Suction
struct RouterControlView: View {
    @ObservedObject var engine: PhysicsEngine
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("⚡️ Energy Router")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Erlang/OTP Inspired")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Current state display
                VStack(spacing: 12) {
                    Text("Current Energy Levels")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Locker Room", systemImage: "figure.strengthtraining.traditional")
                                .font(.subheadline)
                            ProgressView(value: engine.state.lockerRoomEnergy, total: 1.0)
                                .tint(.orange)
                            Text("\(Int(engine.state.lockerRoomEnergy * 100))%")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Library", systemImage: "book.fill")
                                .font(.subheadline)
                            ProgressView(value: engine.state.libraryWisdom, total: 1.0)
                                .tint(.blue)
                            Text("\(Int(engine.state.libraryWisdom * 100))%")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Blowing Controls
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "wind")
                            .foregroundColor(.orange)
                        Text("Blowing (Push)")
                            .font(.headline)
                        Text("80% efficient")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            engine.blowLockerToLibrary(amount: 0.1)
                        }) {
                            VStack {
                                Image(systemName: "arrow.right")
                                Text("Locker → Library")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            engine.blowLibraryToLocker(amount: 0.1)
                        }) {
                            VStack {
                                Image(systemName: "arrow.left")
                                Text("Library → Locker")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Suction Controls
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "tornado")
                            .foregroundColor(.purple)
                        Text("Suction (Pull)")
                            .font(.headline)
                        Text("90% efficient")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            engine.suckLockerToLibrary(amount: 0.1)
                        }) {
                            VStack {
                                Image(systemName: "arrow.right.circle")
                                Text("Pull to Library")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            engine.suckLibraryToLocker(amount: 0.1)
                        }) {
                            VStack {
                                Image(systemName: "arrow.left.circle")
                                Text("Pull to Locker")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                
                // Auto-Balance Control
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.green)
                        Text("Auto-Balance")
                            .font(.headline)
                    }
                    
                    Button(action: {
                        engine.autoBalanceEnergy()
                    }) {
                        Label("Balance Energies", systemImage: "equal.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Text("Automatically equilibrates energy between realms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    Text("About the Router")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Inspired by Erlang/OTP process routing")
                        Text("• Blowing: Active push (80% efficiency)")
                        Text("• Suction: Active pull (90% efficiency)")
                        Text("• Message-based energy distribution")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

#Preview {
    RouterControlView(engine: PhysicsEngine())
}

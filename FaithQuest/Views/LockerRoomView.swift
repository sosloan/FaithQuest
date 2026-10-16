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
        ScrollView {
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
            
            healthSection
            
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
            
            Spacer(minLength: 0)
        }
        .padding()
        }
        .task {
            await engine.refreshHealth()
        }
    }
    
    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple Health")
                .font(.headline)
            
            Text(healthStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Activity floor")
                    Spacer()
                    Text("\(Int(engine.healthSnapshot.activityScore * 100))%")
                        .foregroundColor(.orange)
                }
                .font(.subheadline)
                
                ProgressView(value: engine.healthSnapshot.activityScore, total: 1.0)
                    .tint(.orange)
                
                Text("From active energy, exercise time, steps, and sleep. Body mass and heart rate are shown only.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ForEach(HealthMetric.allCases) { metric in
                let reading = engine.healthSnapshot.reading(for: metric)
                HStack(spacing: 12) {
                    Image(systemName: metric.systemImage)
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.displayName)
                            .font(.subheadline)
                        if !metric.contributesToActivityFloor {
                            Text("Displayed only")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text(reading?.formattedValue ?? "—")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(metric.displayName), \(reading?.formattedValue ?? "no reading")")
            }
            
            Button(action: {
                Task {
                    await engine.refreshHealth()
                }
            }) {
                Label(engine.isSyncingHealth ? "Syncing..." : "Sync from Health", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .disabled(engine.isSyncingHealth || engine.healthSnapshot.access == .unavailable)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var healthStatusText: String {
        if engine.isSyncingHealth {
            return "Reading Apple Health. Readings stay on this device."
        }
        if let healthStatusMessage = engine.healthStatusMessage {
            return healthStatusMessage
        }
        switch engine.healthSnapshot.access {
        case .notDetermined:
            return "Sync to read activity, recovery, and body metrics. Readings stay on this device."
        case .unavailable:
            return "Apple Health is not available on this device."
        case .denied:
            return "Apple Health access is off. Enable sharing for FaithQuest in the Health app."
        case .authorized:
            if let capturedAt = engine.healthSnapshot.capturedAt {
                return "Updated \(capturedAt.formatted(date: .omitted, time: .shortened)). Readings stay on this device."
            }
            return "Readings stay on this device."
        }
    }
}

#Preview {
    LockerRoomView(engine: PhysicsEngine())
}

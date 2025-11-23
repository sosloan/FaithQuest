//
//  LibraryView.swift
//  FaithQuest
//
//  The Library - Intellectual realm interface
//

import SwiftUI

/// LibraryView: Interface for the intellectual realm
struct LibraryView: View {
    @ObservedObject var engine: PhysicsEngine
    @State private var newTheoremContent: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("📚 Library")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("The Intellectual Realm")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Wisdom meter
            VStack(alignment: .leading, spacing: 8) {
                Text("Wisdom Level")
                    .font(.headline)
                
                ProgressView(value: engine.state.libraryWisdom, total: 1.0)
                    .tint(.blue)
                
                Text("\(Int(engine.state.libraryWisdom * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Action button
            Button(action: {
                engine.boostLibrary()
            }) {
                Label("Study Deeper", systemImage: "book.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            // Add theorem from library
            VStack(alignment: .leading, spacing: 8) {
                Text("Record Intellectual Insight")
                    .font(.headline)
                
                TextField("What did you discover?", text: $newTheoremContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    Task {
                        await engine.addTheorem(content: newTheoremContent, category: .library)
                        newTheoremContent = ""
                    }
                }) {
                    Text("Record")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
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

#Preview {
    LibraryView(engine: PhysicsEngine())
}

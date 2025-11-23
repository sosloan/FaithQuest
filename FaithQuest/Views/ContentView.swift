//
//  ContentView.swift
//  FaithQuest
//
//  Main view with tab navigation between realms
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var engine: PhysicsEngine
    
    var body: some View {
        TabView {
            SimulationDeck(engine: engine)
                .tabItem {
                    Label("Grand Loop", systemImage: "circle.hexagongrid.fill")
                }
            
            LockerRoomView(engine: engine)
                .tabItem {
                    Label("Locker Room", systemImage: "figure.strengthtraining.traditional")
                }
            
            LibraryView(engine: engine)
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
            
            TheoremListView(engine: engine)
                .tabItem {
                    Label("Theorems", systemImage: "doc.text.fill")
                }
        }
        .overlay(alignment: .top) {
            if engine.isLoading {
                ProgressView("Syncing with iCloud...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding()
            }
        }
        .alert("Error", isPresented: .constant(engine.errorMessage != nil), presenting: engine.errorMessage) { _ in
            Button("OK") {
                engine.errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }
}

#Preview {
    ContentView(engine: PhysicsEngine())
}

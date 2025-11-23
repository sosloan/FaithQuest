//
//  ContentView.swift
//  FaithQuest
//
//  Main view with tab navigation between realms
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var engine: PhysicsEngine
    @State private var showError: Bool = false
    
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
        .onChange(of: engine.errorMessage) { newValue in
            showError = newValue != nil
        }
        .alert("Error", isPresented: $showError, presenting: engine.errorMessage) { _ in
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

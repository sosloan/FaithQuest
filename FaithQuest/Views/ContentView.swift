//
//  ContentView.swift
//  FaithQuest
//
//  Main view with tab navigation between realms
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var engine: PhysicsEngine
    @StateObject private var adminViewModel: AdminPanelViewModel
    @State private var showError: Bool = false
    
    init(engine: PhysicsEngine) {
        self._engine = ObservedObject(wrappedValue: engine)
        self._adminViewModel = StateObject(wrappedValue: AdminPanelViewModel(engine: engine))
    }
    
    var body: some View {
        TabView {
            SimulationDeck(engine: engine)
                .tabItem {
                    Label("Grand Loop", systemImage: "circle.hexagongrid.fill")
                }
            
            RouterControlView(engine: engine)
                .tabItem {
                    Label("Router", systemImage: "arrow.triangle.branch")
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
            
            AdminPanelView(viewModel: adminViewModel)
                .tabItem {
                    Label("Admin", systemImage: "gearshape.2.fill")
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

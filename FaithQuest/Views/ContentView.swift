//
//  ContentView.swift
//  FaithQuest
//
//  Main view with tab navigation between realms
//  World-class design with MainView as the primary landing interface
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var engine: PhysicsEngine
    @StateObject private var adminViewModel: AdminPanelViewModel
    @State private var showError: Bool = false
    @State private var selectedTab: ContentTab = .main
    
    /// Tab identifiers for navigation
    enum ContentTab: Int, Hashable {
        case main = 0
        case grandLoop = 1
        case router = 2
        case locker = 3
        case library = 4
        case theorems = 5
        case admin = 6
    }
    
    init(engine: PhysicsEngine) {
        self._engine = ObservedObject(wrappedValue: engine)
        self._adminViewModel = StateObject(wrappedValue: AdminPanelViewModel(engine: engine))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MAIN - World-class entry point
            MainView(engine: engine)
                .tabItem {
                    Label("Main", systemImage: "infinity")
                }
                .tag(ContentTab.main)
            
            SimulationDeck(engine: engine)
                .tabItem {
                    Label("Grand Loop", systemImage: "circle.hexagongrid.fill")
                }
                .tag(ContentTab.grandLoop)
            
            RouterControlView(engine: engine)
                .tabItem {
                    Label("Router", systemImage: "arrow.triangle.branch")
                }
                .tag(ContentTab.router)
            
            LockerRoomView(engine: engine)
                .tabItem {
                    Label("Locker Room", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(ContentTab.locker)
            
            LibraryView(engine: engine)
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(ContentTab.library)
            
            TheoremListView(engine: engine)
                .tabItem {
                    Label("Theorems", systemImage: "doc.text.fill")
                }
                .tag(ContentTab.theorems)
            
            AdminPanelView(viewModel: adminViewModel)
                .tabItem {
                    Label("Admin", systemImage: "gearshape.2.fill")
                }
                .tag(ContentTab.admin)
        }
        .overlay(alignment: .top) {
            if engine.isLoading {
                LoadingOverlay()
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

// MARK: - Loading Overlay

/// World-class loading overlay with elegant design
struct LoadingOverlay: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated infinity symbol
            Image(systemName: "infinity")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Syncing with iCloud...")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.top, 8)
    }
}

#Preview {
    ContentView(engine: PhysicsEngine())
}

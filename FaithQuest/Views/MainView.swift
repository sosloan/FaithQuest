//
//  MainView.swift
//  FaithQuest
//
//  The MAIN View - World-class entry point for the Unified Grand Loop
//  "This is not just an app; it is the Unified Grand Loop."
//
//  DESIGN PHILOSOPHY:
//  - Elegant minimalism with purposeful animations
//  - Immersive visual storytelling
//  - Seamless transition between realms
//  - Accessible and inclusive design
//

import SwiftUI

// MARK: - MainView

/// MainView: The world-class entry point to FaithQuest
/// Showcases the Unified Grand Loop philosophy with elegant design
struct MainView: View {
    @ObservedObject var engine: PhysicsEngine
    @State private var showingOnboarding: Bool = false
    @State private var hasCompletedOnboarding: Bool = false
    @State private var selectedQuickAction: QuickAction? = nil
    @State private var pulseAnimation: Bool = false
    
    /// Quick actions available from the main view
    enum QuickAction: String, CaseIterable, Identifiable {
        case locker = "Train"
        case library = "Study"
        case bridge = "Connect"
        case router = "Flow"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .locker: return "figure.strengthtraining.traditional"
            case .library: return "book.fill"
            case .bridge: return "link"
            case .router: return "arrow.triangle.branch"
            }
        }
        
        var color: Color {
            switch self {
            case .locker: return .orange
            case .library: return .blue
            case .bridge: return .purple
            case .router: return .green
            }
        }
        
        var description: String {
            switch self {
            case .locker: return "Physical Excellence"
            case .library: return "Intellectual Pursuit"
            case .bridge: return "Unified Harmony"
            case .router: return "Energy Management"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            MainBackgroundView(harmony: engine.state.harmony)
            
            VStack(spacing: 0) {
                // Hero Section
                MainHeroSection(
                    harmony: engine.state.harmony,
                    theoremCount: engine.state.theorems.count,
                    pulseAnimation: $pulseAnimation
                )
                .padding(.top, 20)
                
                Spacer()
                
                // Live Metrics Ring
                MainMetricsRing(
                    lockerEnergy: engine.state.lockerRoomEnergy,
                    libraryWisdom: engine.state.libraryWisdom,
                    bridgeStrength: engine.state.bridgeStrength,
                    harmony: engine.state.harmony
                )
                
                Spacer()
                
                // Quick Actions Grid
                MainQuickActionsView(
                    engine: engine,
                    selectedAction: $selectedQuickAction
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Daily Insight
                MainDailyInsightView(theorems: engine.state.theorems)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Start pulse animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Background View

/// Animated gradient background that responds to harmony
struct MainBackgroundView: View {
    let harmony: Double
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.7 - (harmony * 0.2), saturation: 0.3, brightness: 0.15),
                Color(hue: 0.6 - (harmony * 0.1), saturation: 0.4, brightness: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.0), value: harmony)
    }
}

// MARK: - Hero Section

/// Hero section with app title and philosophy
struct MainHeroSection: View {
    let harmony: Double
    let theoremCount: Int
    @Binding var pulseAnimation: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // App Icon with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .purple.opacity(0.6),
                                .blue.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                
                // Main icon
                Image(systemName: "infinity")
                    .font(.system(size: 50, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Title
            Text("FaithQuest")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Tagline
            Text("The Unified Grand Loop")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
            
            // Philosophy quote
            Text("\"Building the bridge between the Locker Room and the Library\"")
                .font(.caption)
                .italic()
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Metrics Ring

/// Circular metrics display showing all key metrics
struct MainMetricsRing: View {
    let lockerEnergy: Double
    let libraryWisdom: Double
    let bridgeStrength: Double
    let harmony: Double
    
    var body: some View {
        ZStack {
            // Outer ring - Bridge Strength
            Circle()
                .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                .frame(width: 220, height: 220)
            
            Circle()
                .trim(from: 0, to: bridgeStrength)
                .stroke(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: bridgeStrength)
            
            // Middle ring - Library Wisdom
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                .frame(width: 180, height: 180)
            
            Circle()
                .trim(from: 0, to: libraryWisdom)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: libraryWisdom)
            
            // Inner ring - Locker Room Energy
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: 8)
                .frame(width: 140, height: 140)
            
            Circle()
                .trim(from: 0, to: lockerEnergy)
                .stroke(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: lockerEnergy)
            
            // Center - Harmony Display
            VStack(spacing: 4) {
                Text("\(Int(harmony * 100))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("HARMONY")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
            }
        }
        .overlay(
            // Legend
            VStack(spacing: 4) {
                MetricLegendItem(color: .orange, label: "Physical", value: lockerEnergy)
                MetricLegendItem(color: .blue, label: "Wisdom", value: libraryWisdom)
                MetricLegendItem(color: .purple, label: "Bridge", value: bridgeStrength)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .offset(x: 130, y: 0),
            alignment: .trailing
        )
    }
}

/// Legend item for metrics
struct MetricLegendItem: View {
    let color: Color
    let label: String
    let value: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text("\(Int(value * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(width: 100)
    }
}

// MARK: - Quick Actions View

/// Grid of quick action buttons
struct MainQuickActionsView: View {
    @ObservedObject var engine: PhysicsEngine
    @Binding var selectedAction: MainView.QuickAction?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(MainView.QuickAction.allCases) { action in
                QuickActionButton(action: action) {
                    handleAction(action)
                }
            }
        }
    }
    
    private func handleAction(_ action: MainView.QuickAction) {
        selectedAction = action
        
        // Perform quick boost based on action
        switch action {
        case .locker:
            engine.boostLockerRoom()
        case .library:
            engine.boostLibrary()
        case .bridge:
            engine.strengthenBridge()
        case .router:
            engine.autoBalanceEnergy()
        }
        
        // Reset selection after animation using Task for proper lifecycle management
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            selectedAction = nil
        }
    }
}

/// Individual quick action button
struct QuickActionButton: View {
    let action: MainView.QuickAction
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            onTap()
            
            // Reset press state using Task for proper lifecycle management
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 24))
                        .foregroundColor(action.color)
                }
                .scaleEffect(isPressed ? 1.1 : 1.0)
                
                Text(action.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(action.description)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Daily Insight View

/// Shows the most recent theorem or a motivational message
struct MainDailyInsightView: View {
    let theorems: [OmniTheorem]
    
    private var latestTheorem: OmniTheorem? {
        theorems.max(by: { $0.timestamp < $1.timestamp })
    }
    
    private var displayText: String {
        if let theorem = latestTheorem {
            return "\"" + theorem.content + "\""
        } else {
            return "\"In functional programming, we don't change the world, we describe new worlds.\""
        }
    }
    
    private var categoryColor: Color {
        guard let theorem = latestTheorem else { return .purple }
        
        switch theorem.category {
        case .lockerRoom:
            return .orange
        case .library:
            return .blue
        case .bridge:
            return .purple
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text(latestTheorem != nil ? "Latest Insight" : "Daily Wisdom")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if let theorem = latestTheorem {
                    Text(theorem.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            Text(displayText)
                .font(.subheadline)
                .italic()
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    MainView(engine: PhysicsEngine(
        initialState: UnifiedState(
            theorems: [
                OmniTheorem(content: "Consistency builds character", category: .lockerRoom),
                OmniTheorem(content: "Knowledge compounds daily", category: .library)
            ],
            lockerRoomEnergy: 0.7,
            libraryWisdom: 0.6,
            bridgeStrength: 0.8
        )
    ))
}

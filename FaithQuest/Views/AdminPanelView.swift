//
//  AdminPanelView.swift
//  FaithQuest
//
//  Admin Panel View - SwiftUI interface for administrative controls
//  Protocol-oriented, test-driven development with reactive design
//

import SwiftUI

/// AdminPanelView: Main admin interface
struct AdminPanelView: View {
    @ObservedObject var viewModel: AdminPanelViewModel
    @State private var selectedCategory: AdminCommandCategory? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    AdminHeaderView(isDebugMode: viewModel.isDebugMode)
                    
                    // Quick Stats
                    AdminQuickStatsView(metrics: viewModel.metrics)
                    
                    // Category Filter
                    AdminCategoryFilterView(selectedCategory: $selectedCategory)
                    
                    // Command Buttons
                    AdminCommandListView(
                        viewModel: viewModel,
                        selectedCategory: selectedCategory
                    )
                    
                    // Command History
                    if !viewModel.commandHistory.isEmpty {
                        AdminHistoryView(history: viewModel.commandHistory)
                    }
                }
                .padding()
            }
            .navigationTitle("Admin Panel")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshMetrics()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .confirmationDialog(
                "Confirm Action",
                isPresented: $viewModel.showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Confirm", role: .destructive) {
                    viewModel.confirmPendingCommand()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelPendingCommand()
                }
            } message: {
                Text(viewModel.pendingCommand?.commandDescription ?? "Are you sure?")
            }
        }
    }
}

// MARK: - Admin Header View

struct AdminHeaderView: View {
    let isDebugMode: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                
                Text("Admin Panel")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            if isDebugMode {
                HStack {
                    Image(systemName: "ant.fill")
                        .foregroundColor(.orange)
                    Text("Debug Mode Active")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(20)
            }
            
            Text("System Administration")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Stats View

struct AdminQuickStatsView: View {
    let metrics: AdminMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Metrics")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Theorems",
                    value: "\(metrics.totalTheorems)",
                    icon: "doc.text.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Harmony",
                    value: "\(Int(metrics.harmony * 100))%",
                    icon: "circle.hexagongrid.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Avg Energy",
                    value: "\(Int(metrics.averageEnergyLevel * 100))%",
                    icon: "bolt.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Bridge",
                    value: "\(Int(metrics.bridgeStrength * 100))%",
                    icon: "link",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Category Filter View

struct AdminCategoryFilterView: View {
    @Binding var selectedCategory: AdminCommandCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryButton(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }
                
                ForEach(AdminCommandCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: colorFor(category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func colorFor(_ category: AdminCommandCategory) -> Color {
        switch category {
        case .energy:
            return .orange
        case .state:
            return .red
        case .sync:
            return .blue
        case .debug:
            return .purple
        case .metrics:
            return .green
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.2))
                .cornerRadius(20)
        }
    }
}

// MARK: - Command List View

struct AdminCommandListView: View {
    @ObservedObject var viewModel: AdminPanelViewModel
    let selectedCategory: AdminCommandCategory?
    
    private var commands: [(AdminCommand, String, String, Color)] {
        let allCommands: [(AdminCommand, String, String, Color)] = [
            (.resetEnergy, "Reset Energy", "bolt.trianglebadge.exclamationmark.fill", .orange),
            (.resetState, "Reset State", "arrow.counterclockwise.circle.fill", .red),
            (.forceSync, "Force Sync", "icloud.and.arrow.down.fill", .blue),
            (.toggleDebugMode, "Toggle Debug", "ant.fill", .purple),
            (.exportMetrics, "Export Metrics", "square.and.arrow.up.fill", .green),
            (.clearTheorems, "Clear Theorems", "trash.fill", .red),
            (.generateTestData(count: 10), "Generate Test Data", "plus.circle.fill", .purple)
        ]
        
        if let category = selectedCategory {
            return allCommands.filter { $0.0.category == category }
        }
        return allCommands
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commands")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(commands, id: \.1) { command, title, icon, color in
                    AdminCommandButton(
                        title: title,
                        icon: icon,
                        color: color,
                        isEnabled: viewModel.canExecute(command),
                        requiresConfirmation: command.requiresConfirmation
                    ) {
                        viewModel.requestCommand(command)
                    }
                }
            }
            
            // Energy Level Sliders
            EnergyLevelControlView(viewModel: viewModel)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AdminCommandButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let requiresConfirmation: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if requiresConfirmation {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? color : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Energy Level Control View

struct EnergyLevelControlView: View {
    @ObservedObject var viewModel: AdminPanelViewModel
    @State private var lockerRoomLevel: Double = 0.5
    @State private var libraryLevel: Double = 0.5
    @State private var bridgeLevel: Double = 0.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Energy Controls")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                EnergySlider(
                    label: "Locker Room",
                    value: $lockerRoomLevel,
                    color: .orange
                ) {
                    viewModel.executeCommand(.setEnergyLevel(realm: .lockerRoom, level: lockerRoomLevel))
                }
                
                EnergySlider(
                    label: "Library",
                    value: $libraryLevel,
                    color: .blue
                ) {
                    viewModel.executeCommand(.setEnergyLevel(realm: .library, level: libraryLevel))
                }
                
                EnergySlider(
                    label: "Bridge",
                    value: $bridgeLevel,
                    color: .purple
                ) {
                    viewModel.executeCommand(.setBridgeStrength(level: bridgeLevel))
                }
            }
        }
        .onAppear {
            lockerRoomLevel = viewModel.metrics.lockerRoomEnergy
            libraryLevel = viewModel.metrics.libraryWisdom
            bridgeLevel = viewModel.metrics.bridgeStrength
        }
    }
}

struct EnergySlider: View {
    let label: String
    @Binding var value: Double
    let color: Color
    let onApply: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            HStack {
                Slider(value: $value, in: 0...1, step: 0.05)
                    .accentColor(color)
                
                Button(action: onApply) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                }
            }
        }
    }
}

// MARK: - Command History View

struct AdminHistoryView: View {
    let history: [AdminCommandRecord]
    @State private var isExpanded: Bool = false
    
    var displayedHistory: [AdminCommandRecord] {
        isExpanded ? history : Array(history.suffix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Command History")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show Less" : "Show All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(displayedHistory.reversed()) { record in
                    HistoryRow(record: record)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HistoryRow: View {
    let record: AdminCommandRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(record.success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.command.commandDescription)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(record.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    AdminPanelView(viewModel: AdminPanelViewModel(engine: PhysicsEngine()))
}

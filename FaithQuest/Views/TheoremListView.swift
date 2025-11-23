//
//  TheoremListView.swift
//  FaithQuest
//
//  View for displaying all recorded theorems
//

import SwiftUI

struct TheoremListView: View {
    @ObservedObject var engine: PhysicsEngine
    @State private var selectedCategory: OmniTheorem.Category? = nil
    
    var filteredTheorems: [OmniTheorem] {
        if let category = selectedCategory {
            return engine.state.theorems.filter { $0.category == category }
        }
        return engine.state.theorems
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(nil as OmniTheorem.Category?)
                    Text("Locker Room").tag(OmniTheorem.Category.lockerRoom as OmniTheorem.Category?)
                    Text("Library").tag(OmniTheorem.Category.library as OmniTheorem.Category?)
                    Text("Bridge").tag(OmniTheorem.Category.bridge as OmniTheorem.Category?)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Theorems list
                if filteredTheorems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Theorems Yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Record insights from the Locker Room or Library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(filteredTheorems) { theorem in
                        TheoremRow(theorem: theorem)
                    }
                }
            }
            .navigationTitle("Theorems")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await engine.syncFromCloud()
                        }
                    }) {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
}

struct TheoremRow: View {
    let theorem: OmniTheorem
    
    var categoryColor: Color {
        switch theorem.category {
        case .lockerRoom:
            return .orange
        case .library:
            return .blue
        case .bridge:
            return .purple
        }
    }
    
    var categoryIcon: String {
        switch theorem.category {
        case .lockerRoom:
            return "figure.strengthtraining.traditional"
        case .library:
            return "book.fill"
        case .bridge:
            return "link"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                
                Text(theorem.category.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
                
                Spacer()
                
                Text(theorem.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(theorem.content)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

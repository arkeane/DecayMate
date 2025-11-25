//
//  CustomIsotopeView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

struct CustomIsotopeView: View {
    @ObservedObject var store: IsotopeStore
    
    // Form State
    @State private var name: String = ""
    @State private var symbol: String = ""
    @State private var halfLifeValue: Double?
    @State private var timeUnit: TimeUnit = .hours
    
    // Editing State
    @State private var editingId: UUID? = nil
    @FocusState private var isFocused: Bool
    
    enum TimeUnit: String, CaseIterable, Identifiable {
        case minutes, hours, days
        var id: String { self.rawValue }
        var multiplier: Double {
            switch self {
            case .minutes: return 60
            case .hours: return 3600
            case .days: return 86400
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Section 1: Creator / Editor
                Section {
                    VStack(spacing: 16) {
                        // Header Logic inside the form
                        HStack {
                            Text(editingId == nil ? "Create New Isotope" : "Editing \(name)")
                                .font(.headline)
                                .foregroundColor(Theme.accent)
                            Spacer()
                            if editingId != nil {
                                Button("Cancel") {
                                    withAnimation { resetForm() }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .buttonStyle(.borderless)
                            }
                        }
                        
                        // Input Fields
                        VStack(spacing: 12) {
                            TextField("Name (e.g. Cobalt-60)", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .focused($isFocused)
                            
                            TextField("Symbol (e.g. Co-60)", text: $symbol)
                                .textFieldStyle(.roundedBorder)
                                .focused($isFocused)
                            
                            HStack {
                                TextField("Half-Life", value: $halfLifeValue, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .focused($isFocused)
                                
                                Picker("Unit", selection: $timeUnit) {
                                    ForEach(TimeUnit.allCases) { unit in
                                        Text(unit.rawValue.capitalized).tag(unit)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 80)
                            }
                        }
                        
                        // Action Button
                        Button(action: saveIsotope) {
                            Text(editingId == nil ? "Add to Library" : "Update Isotope")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isValid ? Theme.accent : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(!isValid)
                        .buttonStyle(.borderless) // Essential for buttons inside Lists
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Editor")
                }
                
                // MARK: - Section 2: Library
                Section {
                    ForEach(store.isotopes) { iso in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(iso.symbol)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text(iso.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(iso.halfLifeString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                        // NATIVE SWIPE ACTIONS
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Delete Button
                            Button(role: .destructive) {
                                deleteIsotope(iso)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red) // Explicitly set to red
                            
                            // Edit Button
                            Button {
                                startEditing(iso)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Theme.accent)
                        }
                    }
                } header: {
                    Text("Library")
                } footer: {
                    Text("Swipe left on a row to edit or delete it.")
                }
            }
            .listStyle(.insetGrouped) // This gives the native "Card" look automatically
            .navigationTitle("Manager")
            .scrollDismissesKeyboard(.interactively) // Native keyboard dismissal
        }
    }
    
    // MARK: - Logic
    
    var isValid: Bool {
        return !name.isEmpty && !symbol.isEmpty && halfLifeValue != nil
    }
    
    func startEditing(_ isotope: Isotope) {
        withAnimation {
            name = isotope.name
            symbol = isotope.symbol
            editingId = isotope.id
            
            // Convert seconds back to selected unit for display
            let seconds = isotope.halfLifeSeconds
            if seconds.truncatingRemainder(dividingBy: 86400) == 0 {
                timeUnit = .days
                halfLifeValue = seconds / 86400
            } else if seconds.truncatingRemainder(dividingBy: 3600) == 0 {
                timeUnit = .hours
                halfLifeValue = seconds / 3600
            } else {
                timeUnit = .minutes
                halfLifeValue = seconds / 60
            }
            
            // Focus the first field to invite editing
            isFocused = true
        }
    }
    
    func deleteIsotope(_ isotope: Isotope) {
        withAnimation {
            store.delete(id: isotope.id)
            if editingId == isotope.id {
                resetForm()
            }
        }
    }
    
    func resetForm() {
        name = ""
        symbol = ""
        halfLifeValue = nil
        editingId = nil
        isFocused = false
    }
    
    func saveIsotope() {
        guard let val = halfLifeValue else { return }
        let seconds = val * timeUnit.multiplier
        
        if let id = editingId {
            // Update existing
            let updatedIso = Isotope(id: id, name: name, symbol: symbol, halfLifeSeconds: seconds)
            store.update(updatedIso)
        } else {
            // Create new
            let newIso = Isotope(name: name, symbol: symbol, halfLifeSeconds: seconds)
            store.add(isotope: newIso)
        }
        
        withAnimation {
            resetForm()
        }
    }
}

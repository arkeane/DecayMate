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
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                // Tap to dismiss keyboard
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFocused = false
                    }
                
                ScrollView {
                    VStack(spacing: 12) {
                        
                        // Editor/Creator Card
                        ModernCard {
                            HStack {
                                Text(editingId == nil ? "Create New Isotope" : "Edit Isotope")
                                    .font(.headline)
                                Spacer()
                                if editingId != nil {
                                    Button("Cancel") {
                                        resetForm()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                            .padding(.bottom, 4)
                            
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
                            }
                            
                            Button(action: saveIsotope) {
                                Text(editingId == nil ? "Add to Database" : "Update Isotope")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isValid ? Theme.accent : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(!isValid)
                        }
                        
                        // Library List Card
                        ModernCard {
                            Text("Library")
                                .font(.headline)
                            
                            ForEach(store.isotopes) { iso in
                                VStack {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(iso.symbol)
                                                .font(.system(.body, design: .rounded))
                                                .fontWeight(.bold)
                                            Text(iso.name)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(iso.halfLifeString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.trailing, 8)
                                        
                                        // Edit Button
                                        Button {
                                            startEditing(iso)
                                        } label: {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(Theme.accent)
                                        }
                                        
                                        // Delete Button
                                        Button {
                                            deleteIsotope(iso)
                                        } label: {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(Theme.danger)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if iso.id != store.isotopes.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 100)
                }
            }
            .onTapGesture {
                isFocused = false
            }
            .navigationTitle("Manager")
        }
    }
    
    var isValid: Bool {
        return !name.isEmpty && !symbol.isEmpty && halfLifeValue != nil
    }
    
    func startEditing(_ isotope: Isotope) {
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
        
        // Scroll to top or give focus (Optional, but nice UX)
        isFocused = true
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
        
        resetForm()
    }
}

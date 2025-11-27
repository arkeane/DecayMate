//
//  CustomIsotopeView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

struct CustomIsotopeView: View {
    @ObservedObject var store: IsotopeStore
    
    // State for Sheet Presentation
    @State private var showingSheet = false
    @State private var isotopeToEdit: Isotope? = nil
    
    var body: some View {
        NavigationView {
            List {
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
                        
                        // Swipe Actions
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation { store.delete(id: iso.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                            
                            Button {
                                isotopeToEdit = iso
                                showingSheet = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Theme.accent)
                        }
                    }
                } header: {
                    Text("Library")
                } footer: {
                    Text("Swipe left to edit or delete custom isotopes.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isotopeToEdit = nil // Create Mode
                        showingSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingSheet) {
                // By adding the ID here, we force the sheet to recreate whenever the target isotope changes.
                // This guarantees that 'onAppear' runs and populates the data.
                IsotopeEditorSheet(store: store, isotopeToEdit: isotopeToEdit)
                    .id(isotopeToEdit?.id ?? UUID())
            }
        }
    }
}

// MARK: - Editor Sheet

struct IsotopeEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: IsotopeStore
    
    // Data State
    let isotopeToEdit: Isotope?
    @State private var name: String = ""
    @State private var symbol: String = ""
    @State private var halfLifeValue: Double?
    @State private var timeUnit: TimeUnit = .hours
    
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
    
    init(store: IsotopeStore, isotopeToEdit: Isotope?) {
        self.store = store
        self.isotopeToEdit = isotopeToEdit
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Isotope Details") {
                    TextField("Name (e.g. Cobalt-60)", text: $name)
                        .focused($isFocused)
                    
                    TextField("Symbol (e.g. Co-60)", text: $symbol)
                        .focused($isFocused)
                }
                
                Section("Half-Life") {
                    HStack {
                        TextField("Value", value: $halfLifeValue, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                        
                        Picker("Unit", selection: $timeUnit) {
                            ForEach(TimeUnit.allCases) { unit in
                                Text(unit.rawValue.capitalized).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle(isotopeToEdit == nil ? "New Isotope" : "Edit Isotope")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isotopeToEdit == nil ? "Add" : "Save") {
                        saveIsotope()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let iso = isotopeToEdit {
                    loadData(from: iso)
                }
            }
        }
    }
    
    // Logic
    var isValid: Bool {
        return !name.isEmpty && !symbol.isEmpty && halfLifeValue != nil
    }
    
    func loadData(from isotope: Isotope) {
        name = isotope.name
        symbol = isotope.symbol
        
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
    }
    
    func saveIsotope() {
        guard let val = halfLifeValue else { return }
        let seconds = val * timeUnit.multiplier
        
        if let existing = isotopeToEdit {
            let updated = Isotope(id: existing.id, name: name, symbol: symbol, halfLifeSeconds: seconds)
            store.update(updated)
        } else {
            let newIso = Isotope(name: name, symbol: symbol, halfLifeSeconds: seconds)
            store.add(isotope: newIso)
        }
        dismiss()
    }
}

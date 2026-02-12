//
//  TargetActivityView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

struct TargetActivityView: View {
    @ObservedObject var store: IsotopeStore
    
    @State private var selectedIsotope: Isotope
    @State private var targetActivity: Double?
    @State private var unit: ActivityUnit = .mCi
    @State private var startTime = Date()
    @State private var targetTime = Date().addingTimeInterval(3600 * 2) // Default +2 hr
    
    @FocusState private var isInputFocused: Bool
    
    init(store: IsotopeStore) {
        self.store = store
        _selectedIsotope = State(initialValue: store.isotopes.first ?? Isotope.defaults[0])
    }
    
    var requiredActivity: Double {
        let dose = targetActivity ?? 0.0
        let duration = targetTime.timeIntervalSince(startTime)
        
        // FIXED: Use DecayMath instead of DecayEngine
        return DecayMath.solveForInitial(
            targetActivity: dose,
            halfLife: selectedIsotope.halfLifeSeconds,
            durationSeconds: duration
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    IsotopeSelectorHeader(selection: $selectedIsotope, isotopes: store.isotopes)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            
                            // Card 1: The Goal
                            ModernCard {
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundColor(.green)
                                    Text("Target Activity")
                                        .font(.headline)
                                    Spacer()
                                    UnitSelector(selectedUnit: $unit)
                                }
                                
                                TextField("Required Activity", value: $targetActivity, format: .number)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold))
                                    .focused($isInputFocused)
                                    .padding()
                                    .background(Color(uiColor: .systemFill))
                                    .cornerRadius(12)
                            }
                            
                            // Card 2: Logistics
                            ModernCard {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.green)
                                    Text("Logistics")
                                        .font(.headline)
                                }
                                Divider()
                                
                                DatePicker("Start Time", selection: $startTime)
                                    .font(.system(.body, design: .rounded))
                                
                                DatePicker("Target Time", selection: $targetTime)
                                    .font(.system(.body, design: .rounded))
                            }
                            
                            // Card 3: Reference
                            ModernCard {
                                ResultDisplay(
                                    title: "Starting at \(startTime.formatted(date: .omitted, time: .shortened)) with:",
                                    value: requiredActivity,
                                    unit: unit.label,
                                    date: nil
                                )
                                Text("This amount will decay to exactly \(String(format: "%.1f", targetActivity ?? 0)) \(unit.label) by target time.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onTapGesture {
                isInputFocused = false
            }
            // Smart Conversion Logic
            .onChange(of: unit) { oldValue, newValue in
                if let currentVal = targetActivity {
                    // FIXED: Use DecayMath instead of DecayEngine
                    let converted = DecayMath.convert(currentVal, from: oldValue, to: newValue)
                    targetActivity = (converted * 10000).rounded() / 10000
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

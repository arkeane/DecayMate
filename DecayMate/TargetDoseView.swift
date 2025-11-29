//
//  TargetDoseView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

struct TargetDoseView: View {
    @ObservedObject var store: IsotopeStore
    
    @State private var selectedIsotope: Isotope
    @State private var targetDose: Double?
    @State private var unit: ActivityUnit = .mCi
    @State private var prepTime = Date()
    @State private var adminTime = Date().addingTimeInterval(3600 * 2) // Default +2 hr
    
    @FocusState private var isInputFocused: Bool
    
    init(store: IsotopeStore) {
        self.store = store
        _selectedIsotope = State(initialValue: store.isotopes.first ?? Isotope.defaults[0])
    }
    
    var requiredActivity: Double {
        let dose = targetDose ?? 0.0
        // We need X amount at Admin Time. How much at Prep Time?
        // Duration is Prep -> Admin
        let duration = adminTime.timeIntervalSince(prepTime)
        
        return DecayEngine.shared.calculateRequiredSource(
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
                                
                                TextField("Required Activity", value: $targetDose, format: .number)
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
                                
                                DatePicker("Preparation Time", selection: $prepTime)
                                    .font(.system(.body, design: .rounded))
                                
                                DatePicker("Target Time", selection: $adminTime)
                                    .font(.system(.body, design: .rounded))
                            }
                            
                            // Card 3: The Order
                            ModernCard {
                                ResultDisplay(
                                    title: "Prepare at \(prepTime.formatted(date: .omitted, time: .shortened))",
                                    value: requiredActivity,
                                    unit: unit.label,
                                    date: nil
                                )
                                Text("This amount will decay to exactly \(String(format: "%.1f", targetDose ?? 0)) \(unit.label) by target time.")
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
            // Smart Conversion Logic (Updated for iOS 17+)
            .onChange(of: unit) { oldValue, newValue in
                if let currentVal = targetDose {
                    let converted = DecayEngine.shared.convert(currentVal, from: oldValue, to: newValue)
                    targetDose = (converted * 10000).rounded() / 10000
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

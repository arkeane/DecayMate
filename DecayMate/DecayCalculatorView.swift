//
//  DecayCalculatorView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

struct DecayCalculatorView: View {
    @ObservedObject var store: IsotopeStore
    
    // State
    @State private var selectedIsotope: Isotope
    @State private var initialActivity: Double?
    @State private var unit: ActivityUnit = .mCi
    @State private var referenceDate = Date()
    @State private var targetDate = Date().addingTimeInterval(3600)
    
    @FocusState private var isInputFocused: Bool
    
    init(store: IsotopeStore) {
        self.store = store
        _selectedIsotope = State(initialValue: store.isotopes.first ?? Isotope.defaults[0])
    }
    
    // MARK: - Computations
    
    var resultActivity: Double {
        let act = initialActivity ?? 0.0
        let timeDiff = targetDate.timeIntervalSince(referenceDate)
        return DecayMath.solveForActivity(A0: act, halfLife: selectedIsotope.halfLifeSeconds, elapsedSeconds: timeDiff)
    }
    
    var decayFactor: Double {
        let timeDiff = targetDate.timeIntervalSince(referenceDate)
        let lambda = PhysicsConstants.ln2 / selectedIsotope.halfLifeSeconds
        return exp(-lambda * timeDiff)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    IsotopeSelectorHeader(selection: $selectedIsotope, isotopes: store.isotopes)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            
                            // 1. Input Card
                            ModernCard {
                                HStack {
                                    Image(systemName: "flask.fill")
                                        .foregroundColor(Theme.accent)
                                    Text("Initial Source")
                                        .font(.headline)
                                    Spacer()
                                    UnitSelector(selectedUnit: $unit)
                                }
                                
                                TextField("Enter Activity", value: $initialActivity, format: .number)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold))
                                    .focused($isInputFocused)
                                    .padding()
                                    .background(Color(uiColor: .systemFill))
                                    .cornerRadius(12)
                            }
                            
                            // 2. Dates Card
                            ModernCard {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(Theme.accent)
                                    Text("Timeline")
                                        .font(.headline)
                                }
                                Divider()
                                DatePicker("Reference Date", selection: $referenceDate)
                                DatePicker("Calculate For", selection: $targetDate)
                            }
                            
                            // 3. Result Card
                            ModernCard {
                                ResultDisplay(
                                    title: "Remaining Activity",
                                    value: resultActivity,
                                    unit: unit.label,
                                    date: targetDate
                                )
                                HStack {
                                    Text("Decay Factor:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.4f", decayFactor))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onTapGesture { isInputFocused = false }
            .onChange(of: unit) { oldValue, newValue in
                if let currentVal = initialActivity {
                    let converted = DecayMath.convert(currentVal, from: oldValue, to: newValue)
                    initialActivity = (converted * 10000).rounded() / 10000
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Calculator")
        }
    }
}

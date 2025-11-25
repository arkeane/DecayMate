//
//  DecayCalculatorView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

struct DecayCalculatorView: View {
    // Data Source
    @ObservedObject var store: IsotopeStore
    
    // State
    @State private var selectedIsotope: Isotope
    @State private var initialActivity: Double?
    @State private var unit: ActivityUnit = .mCi
    @State private var referenceDate = Date()
    @State private var targetDate = Date().addingTimeInterval(3600) // Default +1 hr
    
    // Focus State for Keyboard
    @FocusState private var isInputFocused: Bool
    
    init(store: IsotopeStore) {
        self.store = store
        _selectedIsotope = State(initialValue: store.isotopes.first ?? Isotope.defaults[0])
    }
    
    // Computed Result
    var result: Double {
        let act = initialActivity ?? 0.0
        let timeDiff = targetDate.timeIntervalSince(referenceDate)
        return DecayEngine.shared.calculateDecay(
            A0: act,
            halfLife: selectedIsotope.halfLifeSeconds,
            elapsedSeconds: timeDiff
        )
    }
    
    var decayFactor: Double {
        let timeDiff = targetDate.timeIntervalSince(referenceDate)
        let decayConstant = 0.69314718056 / selectedIsotope.halfLifeSeconds
        return exp(-decayConstant * timeDiff)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Selector
                    IsotopeSelectorHeader(selection: $selectedIsotope, isotopes: store.isotopes)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            
                            // Card 1: Input
                            ModernCard {
                                HStack {
                                    Image(systemName: "flask.fill")
                                        .foregroundColor(Theme.accent)
                                    Text("Initial Activity")
                                        .font(.headline)
                                    Spacer()
                                    UnitSelector(selectedUnit: $unit)
                                }
                                
                                TextField("Enter value", value: $initialActivity, format: .number)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold))
                                    .focused($isInputFocused)
                                    .padding()
                                    .background(Color(uiColor: .systemFill))
                                    .cornerRadius(12)
                            }
                            
                            // Card 2: Time
                            ModernCard {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(Theme.accent)
                                    Text("Timeline")
                                        .font(.headline)
                                }
                                
                                Divider()
                                
                                DatePicker("Calibration Time", selection: $referenceDate)
                                    .font(.system(.body, design: .rounded))
                                
                                DatePicker("Target Time", selection: $targetDate)
                                    .font(.system(.body, design: .rounded))
                                
                                let diff = targetDate.timeIntervalSince(referenceDate)
                                Text("Delta: \(Formatters.durationFormatter.string(from: diff) ?? "0 min")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            
                            // Card 3: Result
                            ModernCard {
                                ResultDisplay(
                                    title: "Remaining Activity",
                                    value: result,
                                    unit: unit.label,
                                    date: targetDate
                                )
                                
                                HStack {
                                    Text("Decay Factor:")
                                    Spacer()
                                    Text(String(format: "%.4f", decayFactor))
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 100) // Spacing for tab bar
                    }
                }
            }
            // Moved .onTapGesture here to cover the entire ZStack (screen)
            .onTapGesture {
                isInputFocused = false
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Helper formatter
struct Formatters {
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

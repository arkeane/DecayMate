//
//  DecayCalculatorView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI
import Charts

struct DecayCalculatorView: View {
    @ObservedObject var store: IsotopeStore
    
    // State
    @State private var selectedIsotope: Isotope
    @State private var initialActivity: Double?
    @State private var unit: ActivityUnit = .mCi
    @State private var referenceDate = Date()
    @State private var targetDate = Date().addingTimeInterval(3600)
    
    // Advanced State: Inverse Calculation
    @State private var desiredActivity: Double?
    @State private var showInverseCalc = false
    
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
    
    // Calculates when the source will decay to 'desiredActivity'
    var timeToReachDesired: Date? {
        guard let current = initialActivity, let target = desiredActivity, target < current else { return nil }
        let secondsNeeded = DecayMath.solveForTime(currentActivity: current, targetActivity: target, halfLife: selectedIsotope.halfLifeSeconds)
        return referenceDate.addingTimeInterval(secondsNeeded)
    }
    
    // Data points for the Chart
    var chartData: [DecayDataPoint] {
        guard let startAct = initialActivity, startAct > 0 else { return [] }
        
        let totalDuration = max(abs(targetDate.timeIntervalSince(referenceDate)), selectedIsotope.halfLifeSeconds * 2)
        let steps = 20
        let interval = totalDuration / Double(steps)
        
        return (0...steps).map { i in
            let timeOffset = Double(i) * interval
            let activity = DecayMath.solveForActivity(A0: startAct, halfLife: selectedIsotope.halfLifeSeconds, elapsedSeconds: timeOffset)
            return DecayDataPoint(secondsOffset: timeOffset, activity: activity)
        }
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
                            
                            // 3. Visualization Chart (iOS 16+)
                            if let act = initialActivity, act > 0 {
                                ModernCard {
                                    Text("Decay Curve")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Chart(chartData) { point in
                                        LineMark(
                                            x: .value("Time", point.secondsOffset),
                                            y: .value("Activity", point.activity)
                                        )
                                        .foregroundStyle(Theme.accent.gradient)
                                        .interpolationMethod(.catmullRom)
                                        
                                        AreaMark(
                                            x: .value("Time", point.secondsOffset),
                                            y: .value("Activity", point.activity)
                                        )
                                        .foregroundStyle(Theme.accent.opacity(0.1))
                                    }
                                    .chartXAxis {
                                        AxisMarks(format: .dateTime.hour()) // Simplification
                                    }
                                    .frame(height: 150)
                                }
                            }
                            
                            // 4. Result Card
                            ModernCard {
                                ResultDisplay(
                                    title: "Remaining Activity",
                                    value: resultActivity,
                                    unit: unit.label,
                                    date: targetDate
                                )
                                HStack {
                                    Text("Factor: \(String(format: "%.4f", decayFactor))")
                                    Spacer()
                                    // Toggle for inverse calc
                                    Button("Time to reach X?") {
                                        withAnimation { showInverseCalc.toggle() }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            // 5. Inverse Calculation (Conditional)
                            if showInverseCalc {
                                ModernCard {
                                    Text("When will it reach...")
                                        .font(.headline)
                                    
                                    TextField("Target Activity", value: $desiredActivity, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($isInputFocused)
                                    
                                    if let date = timeToReachDesired {
                                        HStack {
                                            Text("Date:")
                                            Spacer()
                                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.accent)
                                        }
                                        .padding(.top, 4)
                                    } else if let d = desiredActivity, let i = initialActivity, d >= i {
                                        Text("Target must be lower than initial activity")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
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
        }
    }
}

// Helper for Charts
struct DecayDataPoint: Identifiable {
    var id = UUID()
    let secondsOffset: Double
    let activity: Double
}

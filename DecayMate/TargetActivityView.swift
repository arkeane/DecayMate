//
//  TargetActivityView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI
import Charts

struct TargetActivityView: View {
    @ObservedObject var store: IsotopeStore
    
    // Modes for this View
    enum CalculationMode: String, CaseIterable {
        case ordering = "Required Activity"   // Renamed to remove "Order"
        case disposal = "Time to Limit"
    }
    
    @State private var mode: CalculationMode = .ordering
    @State private var selectedIsotope: Isotope
    @State private var unit: ActivityUnit = .mCi
    
    // Inputs
    @State private var activityA: Double? // Target Activity (Mode 1) or Current Activity (Mode 2)
    @State private var activityB: Double? // N/A (Mode 1) or Limit Activity (Mode 2)
    
    @State private var dateA = Date() // Start/Ref Date
    @State private var dateB = Date().addingTimeInterval(3600 * 24) // Target Date (Mode 1 only)
    
    @FocusState private var isInputFocused: Bool
    
    init(store: IsotopeStore) {
        self.store = store
        _selectedIsotope = State(initialValue: store.isotopes.first ?? Isotope.defaults[0])
    }
    
    // MARK: - Logic
    
    // Mode 1: We want to reach 'activityA' at 'dateB'. What do we need at 'dateA'?
    var requiredInitialActivity: Double {
        let target = activityA ?? 0.0
        let duration = dateB.timeIntervalSince(dateA)
        guard duration > 0 else { return 0 }
        
        return DecayMath.solveForInitial(
            targetActivity: target,
            halfLife: selectedIsotope.halfLifeSeconds,
            durationSeconds: duration
        )
    }
    
    // Mode 2: We have 'activityA' at 'dateA'. When does it hit 'activityB'?
    var timeToReachLimit: Date? {
        guard let current = activityA, let limit = activityB,
              current > 0, limit > 0, limit < current else { return nil }
        
        let seconds = DecayMath.solveForTime(
            currentActivity: current,
            targetActivity: limit,
            halfLife: selectedIsotope.halfLifeSeconds
        )
        return dateA.addingTimeInterval(seconds)
    }
    
    // MARK: - Chart Logic
    
    struct ChartPoint: Identifiable {
        var id = UUID()
        let date: Date
        let activity: Double
        let type: PointType
        
        enum PointType: String, Plottable {
            case curve = "Decay"
            case limit = "Target"
        }
    }
    
    var chartData: [ChartPoint] {
        let steps = 40
        var points: [ChartPoint] = []
        
        if mode == .ordering {
            // Plot from calculated Start -> Target
            guard let target = activityA, target > 0 else { return [] }
            let duration = dateB.timeIntervalSince(dateA)
            let startAct = requiredInitialActivity
            
            // Safety check for valid duration
            let safeDuration = max(duration, selectedIsotope.halfLifeSeconds)
            let stepSize = safeDuration / Double(steps)
            
            for i in 0...steps {
                let t = Double(i) * stepSize
                // If duration is negative (dateB < dateA), math handles it, but chart might look weird.
                // We assume user puts dateB > dateA.
                let act = DecayMath.solveForActivity(A0: startAct, halfLife: selectedIsotope.halfLifeSeconds, elapsedSeconds: t)
                let date = dateA.addingTimeInterval(t)
                points.append(ChartPoint(date: date, activity: act, type: .curve))
            }
        } else {
            // Plot from Current -> Limit (calculated time)
            guard let start = activityA, let limit = activityB, start > limit else { return [] }
            let secondsNeeded = DecayMath.solveForTime(currentActivity: start, targetActivity: limit, halfLife: selectedIsotope.halfLifeSeconds)
            
            // Add a bit of buffer (20%) to the right of the chart
            let totalTime = secondsNeeded * 1.2
            let stepSize = totalTime / Double(steps)
            
            for i in 0...steps {
                let t = Double(i) * stepSize
                let act = DecayMath.solveForActivity(A0: start, halfLife: selectedIsotope.halfLifeSeconds, elapsedSeconds: t)
                let date = dateA.addingTimeInterval(t)
                points.append(ChartPoint(date: date, activity: act, type: .curve))
            }
        }
        
        return points
    }
    
    var targetLineValue: Double {
        switch mode {
        case .ordering: return activityA ?? 0
        case .disposal: return activityB ?? 0
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    IsotopeSelectorHeader(selection: $selectedIsotope, isotopes: store.isotopes)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            
                            // 1. Mode Selector
                            Picker("Mode", selection: $mode) {
                                ForEach(CalculationMode.allCases, id: \.self) { m in
                                    Text(m.rawValue).tag(m)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Theme.padding)
                            .padding(.vertical, 8)
                            
                            // 2. Main Logic Card
                            ModernCard {
                                HStack {
                                    // Removed logistics/shipping icon, using generic calc icons
                                    Image(systemName: mode == .ordering ? "arrow.left.arrow.right" : "hourglass.bottomhalf.filled")
                                        .foregroundColor(Theme.accent)
                                    // Removed "Logistics" terminology
                                    Text(mode == .ordering ? "Target Parameters" : "Limit Parameters")
                                        .font(.headline)
                                    Spacer()
                                    UnitSelector(selectedUnit: $unit)
                                }
                                Divider()
                                
                                if mode == .ordering {
                                    // ORDERING INPUTS
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("I need to have:")
                                            .font(.caption).foregroundColor(.secondary)
                                        TextField("Target Amount", value: $activityA, format: .number)
                                            .keyboardType(.decimalPad)
                                            .font(.system(size: 24, weight: .bold))
                                            .focused($isInputFocused)
                                        
                                        DatePicker("By Date", selection: $dateB)
                                        DatePicker("Reference Date", selection: $dateA) // Renamed from "Ordering/Ref Date"
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    // DISPOSAL INPUTS
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Current Status:")
                                            .font(.caption).foregroundColor(.secondary)
                                        TextField("Current Activity", value: $activityA, format: .number)
                                            .keyboardType(.decimalPad)
                                            .font(.system(size: 24, weight: .bold))
                                            .focused($isInputFocused)
                                        
                                        Divider()
                                        
                                        Text("Desired Limit:")
                                            .font(.caption).foregroundColor(.secondary)
                                        TextField("Limit Activity", value: $activityB, format: .number)
                                            .keyboardType(.decimalPad)
                                            .font(.system(size: 24, weight: .bold))
                                            .focused($isInputFocused)
                                        
                                        DatePicker("Start Date", selection: $dateA)
                                    }
                                }
                            }
                            
                            // 3. Visualizer (Chart)
                            if (mode == .ordering && (activityA ?? 0) > 0) ||
                                (mode == .disposal && (activityA ?? 0) > (activityB ?? 0) && (activityB ?? 0) > 0) {
                                ModernCard {
                                    Text("Decay Projection")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Chart {
                                        // The Curve
                                        ForEach(chartData) { point in
                                            LineMark(
                                                x: .value("Time", point.date),
                                                y: .value("Activity", point.activity)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(Theme.accent.gradient)
                                            
                                            AreaMark(
                                                x: .value("Time", point.date),
                                                y: .value("Activity", point.activity)
                                            )
                                            .foregroundStyle(Theme.accent.opacity(0.1))
                                        }
                                        
                                        // The Target Line
                                        RuleMark(y: .value("Target", targetLineValue))
                                            .foregroundStyle(.orange)
                                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                            .annotation(position: .top, alignment: .leading) {
                                                Text("Target: \(String(format: "%.1f", targetLineValue))")
                                                    .font(.caption2)
                                                    .foregroundColor(.orange)
                                            }
                                    }
                                    .chartXAxis {
                                        AxisMarks(values: .automatic) {
                                            AxisGridLine()
                                            AxisTick()
                                            AxisValueLabel(format: .dateTime.hour().minute().day())
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { value in
                                            AxisGridLine()
                                            AxisTick()
                                            if let doubleValue = value.as(Double.self) {
                                                AxisValueLabel {
                                                    Text("\(doubleValue.formatted(.number.precision(.fractionLength(0...2)).notation(.compactName)))")
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 200)
                                }
                            }
                            
                            // 4. Result Card
                            ModernCard {
                                if mode == .ordering {
                                    ResultDisplay(
                                        title: "Required Initial Source",
                                        value: requiredInitialActivity,
                                        unit: unit.label,
                                        date: dateA
                                    )
                                } else {
                                    if let date = timeToReachLimit {
                                        VStack(spacing: 8) {
                                            Text("Limit Reached On")
                                                .font(.headline)
                                                .foregroundColor(.secondary)
                                            
                                            Text(date.formatted(date: .long, time: .shortened))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.accent)
                                                .multilineTextAlignment(.center)
                                            
                                            Text("Wait Time: \(date.timeIntervalSince(dateA).formattedDuration)")
                                                .font(.caption)
                                                .padding(6)
                                                .background(Color.secondary.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                    } else {
                                        Text(activityB == nil ? "Enter limit" : "Current activity must be higher than limit")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                                
                                Divider().padding(.top, 8)
                                
                                // Explanation Footer
                                Text(mode == .ordering
                                     ? "Calculates how much activity you need to start with to have a specific amount remaining at a future date."
                                     : "Calculates the exact date and time when your current source will decay down to a specific limit."
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onTapGesture { isInputFocused = false }
            .navigationBarTitleDisplayMode(.inline)
            // Renamed to "Planning" as requested
            .navigationTitle("Planning")
        }
    }
}

// Helper for duration formatting
extension TimeInterval {
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: self) ?? "0m"
    }
}

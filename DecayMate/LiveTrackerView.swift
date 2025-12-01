//
//  LiveTrackerView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 26/11/25.
//

import SwiftUI
import Combine

struct LiveTrackerView: View {
    @ObservedObject var isotopeStore: IsotopeStore
    @StateObject private var referencesStore = OrderStore()
    
    @State private var showingAddSheet = false
    @State private var currentTime = Date()
    
    // Global Timer: Updates 'currentTime' every second.
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(store: IsotopeStore) {
        self.isotopeStore = store
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                if referencesStore.references.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(referencesStore.references) { order in
                            ZStack {
                                // Navigation Link hidden behind the card content
                                // We pass orderStore so the DetailView can update the unit
                                NavigationLink(destination: OrderDetailView(order: order, currentTime: $currentTime, orderStore: referencesStore)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                // The Visual Card
                                LiveOrderCard(order: order, now: currentTime)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    referencesStore.delete(order)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Live Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddOrderSheet(isotopeStore: isotopeStore, orderStore: referencesStore)
            }
            .onReceive(timer) { input in
                currentTime = input
            }
        }
    }
}

// MARK: - Components

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.3))
            Text("No Active Trackers")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Add an activity to monitor its decay in real-time.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct LiveOrderCard: View {
    let order: Reference
    let now: Date
    
    var currentActivity: Double {
        let elapsed = now.timeIntervalSince(order.calibrationDate)
        return DecayEngine.shared.calculateDecay(
            A0: order.calibrationActivity,
            halfLife: order.isotope.halfLifeSeconds,
            elapsedSeconds: elapsed
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(order.referenceName.isEmpty ? "Reference #\(order.id.uuidString.prefix(4))" : order.referenceName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(order.isotope.symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.1))
                        .foregroundColor(Theme.accent)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Live Blinker
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .opacity(Int(now.timeIntervalSince1970) % 2 == 0 ? 1.0 : 0.4)
                    .animation(.default, value: now)
            }
            
            // Calibration Info (Compact One-Line)
            HStack(spacing: 6) {
                Image(systemName: "gauge.with.needle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Start: \(String(format: "%.1f", order.calibrationActivity)) \(order.unit.label) @ \(order.calibrationDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
            .padding(.vertical, 2)
            
            Divider()
            
            // Numbers
            HStack(alignment: .lastTextBaseline) {
                // ROUNDED TO 1 DIGIT
                Text(String(format: "%.1f", currentActivity))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(value: currentActivity))
                    .animation(.default, value: currentActivity)
                
                Text(order.unit.label)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Add Order Sheet

struct AddOrderSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var isotopeStore: IsotopeStore
    @ObservedObject var orderStore: OrderStore
    
    @State private var referenceName = ""
    @State private var selectedIsotope: Isotope
    @State private var activity: Double?
    @State private var unit: ActivityUnit = .mCi
    @State private var calibrationDate = Date()
    @FocusState private var isFocused: Bool
    
    init(isotopeStore: IsotopeStore, orderStore: OrderStore) {
        self.isotopeStore = isotopeStore
        self.orderStore = orderStore
        _selectedIsotope = State(initialValue: isotopeStore.isotopes.first ?? Isotope.defaults[0])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Reference", text: $referenceName)
                        .focused($isFocused)
                    
                    Picker("Isotope", selection: $selectedIsotope) {
                        ForEach(isotopeStore.isotopes) { iso in
                            Text("\(iso.name) (\(iso.symbol))").tag(iso)
                        }
                    }
                }
                
                Section("Calibration") {
                    HStack {
                        TextField("Initial Activity", value: $activity, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(ActivityUnit.allCases) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 100)
                    }
                    
                    DatePicker("Calibrated At", selection: $calibrationDate)
                }
            }
            .navigationTitle("New Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Tracking") {
                        if let act = activity {
                            let newOrder = Reference(
                                referenceName: referenceName,
                                isotope: selectedIsotope,
                                calibrationActivity: act,
                                unit: unit,
                                calibrationDate: calibrationDate
                            )
                            orderStore.add(newOrder)
                            dismiss()
                        }
                    }
                    .disabled(activity == nil)
                }
            }
        }
    }
}

// MARK: - Detail View

struct OrderDetailView: View {
    let order: Reference
    @Binding var currentTime: Date
    @ObservedObject var orderStore: OrderStore
    
    @State private var selectedUnit: ActivityUnit
    
    init(order: Reference, currentTime: Binding<Date>, orderStore: OrderStore) {
        self.order = order
        self._currentTime = currentTime
        self.orderStore = orderStore
        // Initialize state with the order's unit
        self._selectedUnit = State(initialValue: order.unit)
    }
    
    var currentActivity: Double {
        let elapsed = currentTime.timeIntervalSince(order.calibrationDate)
        return DecayEngine.shared.calculateDecay(
            A0: order.calibrationActivity,
            halfLife: order.isotope.halfLifeSeconds,
            elapsedSeconds: elapsed
        )
    }
    
    var elapsedString: String {
        let diff = currentTime.timeIntervalSince(order.calibrationDate)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return diff >= 0 ? "+ \(formatter.string(from: diff) ?? "")" : "- \(formatter.string(from: abs(diff)) ?? "")"
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    ModernCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reference")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.referenceName.isEmpty ? "Unnamed" : order.referenceName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Divider()
                            
                            HStack {
                                Label(order.isotope.name, systemImage: "atom")
                                Spacer()
                                Text(order.isotope.symbol).fontWeight(.bold)
                            }
                        }
                    }
                    
                    // Live Stats
                    ModernCard {
                        VStack(spacing: 8) {
                            // Header Row with Title and Switch
                            HStack {
                                Text("CURRENT ACTIVITY")
                                    .font(.caption)
                                    .fontWeight(.black)
                                    .foregroundColor(.secondary)
                                    .tracking(1)
                                
                                Spacer()
                                
                                // Unit Selector Moved Here
                                UnitSelector(selectedUnit: $selectedUnit)
                                    .scaleEffect(0.9) // Slight scale down to fit header nicely
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                // ROUNDED TO 1 DIGIT
                                Text(String(format: "%.1f", currentActivity))
                                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                                    .foregroundColor(Theme.accent)
                                    .contentTransition(.numericText(value: currentActivity))
                                
                                // Added Text label back since Selector moved
                                Text(selectedUnit.label)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    
                    // Info Grid
                    ModernCard {
                        VStack(spacing: 0) {
                            // Using order.calibrationActivity ensures we show the updated value
                            row(icon: "gauge.with.needle", title: "Original Activity", value: "\(String(format: "%.2f", order.calibrationActivity)) \(order.unit.label)")
                            Divider().padding(.leading, 36)
                            row(icon: "calendar", title: "Calibration Time", value: order.calibrationDate.formatted(date: .numeric, time: .shortened))
                            Divider().padding(.leading, 36)
                            row(icon: "clock", title: "Elapsed Time", value: elapsedString)
                        }
                    }
                }
                .padding(.top)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Ensure state stays in sync if order changes externally
        .onAppear {
            selectedUnit = order.unit
        }
        // Conversion Logic: When unit changes, update the Order in the Store
        .onChange(of: selectedUnit) { oldValue, newValue in
            // Prevent redundant updates if unit hasn't effectively changed
            guard oldValue != newValue else { return }
            
            let currentCalibrationVal = order.calibrationActivity
            let convertedVal = DecayEngine.shared.convert(currentCalibrationVal, from: oldValue, to: newValue)
            
            // Create updated order
            var updatedOrder = order
            updatedOrder.unit = newValue
            updatedOrder.calibrationActivity = (convertedVal * 10000).rounded() / 10000
            
            // Save to store (this will trigger View updates)
            orderStore.update(updatedOrder)
        }
    }
    
    func row(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(Theme.accent)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 12)
    }
}

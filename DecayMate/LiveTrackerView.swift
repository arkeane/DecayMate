//
//  LiveTrackerView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI
import Combine
import ActivityKit

struct LiveTrackerView: View {
    @ObservedObject var isotopeStore: IsotopeStore
    @StateObject private var referencesStore = OrderStore()
    
    @State private var showingAddSheet = false
    @State private var currentTime = Date()
    
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
                                NavigationLink(destination: OrderDetailView(order: order, currentTime: $currentTime, orderStore: referencesStore)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
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
                    Button { showingAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddOrderSheet(isotopeStore: isotopeStore, orderStore: referencesStore)
            }
            .onReceive(timer) { input in currentTime = input }
        }
    }
}

// MARK: - Components (EmptyState, LiveOrderCard)

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
        }
    }
}

struct LiveOrderCard: View {
    let order: Reference
    let now: Date
    
    var currentActivity: Double {
        let elapsed = now.timeIntervalSince(order.calibrationDate)
        return DecayMath.solveForActivity(
            A0: order.calibrationActivity,
            halfLife: order.isotope.halfLifeSeconds,
            elapsedSeconds: elapsed
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(order.referenceName.isEmpty ? "Reference" : order.referenceName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if order.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
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
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .opacity(Int(now.timeIntervalSince1970) % 2 == 0 ? 1.0 : 0.4)
            }
            
            HStack(alignment: .lastTextBaseline) {
                Text(String(format: "%.2f", currentActivity))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(value: currentActivity))
                
                Text(order.unit.label)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Detail View

struct OrderDetailView: View {
    let order: Reference
    @Binding var currentTime: Date
    @ObservedObject var orderStore: OrderStore
    
    @State private var selectedUnit: ActivityUnit
    
    @State private var isEditingName = false
    @State private var newName = ""
    @State private var isAddingTarget = false
    @State private var newTargetName = ""
    @State private var newTargetValue: Double?
    
    init(order: Reference, currentTime: Binding<Date>, orderStore: OrderStore) {
        self.order = order
        self._currentTime = currentTime
        self.orderStore = orderStore
        self._selectedUnit = State(initialValue: order.unit)
    }
    
    var currentActivity: Double {
        let elapsed = currentTime.timeIntervalSince(order.calibrationDate)
        return DecayMath.solveForActivity(A0: order.calibrationActivity, halfLife: order.isotope.halfLifeSeconds, elapsedSeconds: elapsed)
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    
                    // HEADER CARD
                    ModernCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reference Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text(order.referenceName.isEmpty ? "Unnamed Source" : order.referenceName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Button {
                                        newName = order.referenceName
                                        isEditingName = true
                                    } label: {
                                        Image(systemName: "pencil.circle.fill").foregroundColor(.secondary)
                                    }
                                }
                                Divider()
                                HStack {
                                    Label(order.isotope.name, systemImage: "atom")
                                    Spacer()
                                    // PIN BUTTON
                                    Button(action: togglePin) {
                                        HStack {
                                            Text(order.isPinned ? "Unpin" : "Pin")
                                            Image(systemName: order.isPinned ? "pin.slash.fill" : "pin")
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(order.isPinned ? Color.orange.opacity(0.15) : Color.clear)
                                        .foregroundColor(order.isPinned ? .orange : .secondary)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // ACTIVITY CARD
                    ModernCard {
                        VStack(spacing: 8) {
                            HStack {
                                Text("CURRENT ACTIVITY")
                                    .font(.caption)
                                    .fontWeight(.black)
                                    .foregroundColor(.secondary)
                                    .tracking(1)
                                Spacer()
                                UnitSelector(selectedUnit: $selectedUnit)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(String(format: "%.2f", currentActivity))
                                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                                    .foregroundColor(Theme.accent)
                                    .contentTransition(.numericText(value: currentActivity))
                                Text(selectedUnit.label)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // TARGETS
                    ModernCard {
                        HStack {
                            Text("Smart Targets")
                                .font(.headline)
                            Spacer()
                            Button {
                                newTargetName = ""
                                newTargetValue = nil
                                isAddingTarget = true
                            } label: {
                                Label("Add", systemImage: "plus").font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                        Text("Track when this source will reach specific activity levels.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Divider()
                        if order.savedTargets.isEmpty {
                            Text("No targets saved.")
                                .italic()
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(order.savedTargets) { target in
                                TargetRow(target: target, currentActivity: currentActivity, currentUnit: selectedUnit, isotope: order.isotope)
                                Divider()
                            }
                        }
                    }
                }
                .padding(.top)
                .padding(.bottom, 50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedUnit = order.unit }
        
        .alert("Rename Source", isPresented: $isEditingName) {
            TextField("Name", text: $newName)
            Button("Save") {
                var updated = order
                updated.referenceName = newName
                orderStore.update(updated)
            }
            Button("Cancel", role: .cancel) {}
        }
        
        .alert("Add Target", isPresented: $isAddingTarget) {
            TextField("Label", text: $newTargetName)
            TextField("Activity", value: $newTargetValue, format: .number).keyboardType(.decimalPad)
            Button("Save") {
                guard let val = newTargetValue, !newTargetName.isEmpty else { return }
                var updated = order
                let newT = SavedTarget(name: newTargetName, targetActivity: val, unit: selectedUnit)
                updated.savedTargets.append(newT)
                orderStore.update(updated)
            }
            Button("Cancel", role: .cancel) {}
        }
        
        .onChange(of: selectedUnit) { oldValue, newValue in
            guard oldValue != newValue else { return }
            var updated = order
            updated.unit = newValue
            updated.calibrationActivity = DecayMath.convert(updated.calibrationActivity, from: oldValue, to: newValue)
            orderStore.update(updated)
        }
    }
    
    // MARK: - Activity Logic
    func togglePin() {
        var updated = order
        updated.isPinned.toggle()
        orderStore.update(updated)
        
        if updated.isPinned {
            startActivity(for: updated)
        } else {
            stopActivity()
        }
    }
    
    // In LiveTrackerView.swift

    func startActivity(for reference: Reference) {
        // Wrap everything in a Task to ensure we wait for cleanup
        Task {
            // Await the cleanup of OLD activities first
            for activity in Activity<DecayMateWidgetAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            
            // NOW create the new one safely
            let attributes = DecayMateWidgetAttributes(
                isotopeName: reference.isotope.name,
                isotopeSymbol: reference.isotope.symbol,
                referenceName: reference.referenceName,
                calibrationDate: reference.calibrationDate,
                calibrationActivity: reference.calibrationActivity,
                halfLife: reference.isotope.halfLifeSeconds
            )
            
            // Calculate initial state
            let currentAct = DecayMath.solveForActivity(
                A0: reference.calibrationActivity,
                halfLife: reference.isotope.halfLifeSeconds,
                elapsedSeconds: Date().timeIntervalSince(reference.calibrationDate)
            )
            
            let contentState = DecayMateWidgetAttributes.ContentState(
                currentActivity: currentAct,
                unit: reference.unit.label
            )
            
            let activityContent = ActivityContent(state: contentState, staleDate: nil)
            
            do {
                let activity = try Activity.request(attributes: attributes, content: activityContent, pushType: nil)
                print("Live Activity Started Safely: \(activity.id)")
            } catch {
                print("Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    func stopActivity() {
        Task {
            for activity in Activity<DecayMateWidgetAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}

// (Helper Structs - AddOrderSheet, TargetRow)
struct TargetRow: View {
    let target: SavedTarget
    let currentActivity: Double
    let currentUnit: ActivityUnit
    let isotope: Isotope
    
    var body: some View {
        let targetInCurrentUnit = DecayMath.convert(target.targetActivity, from: target.unit, to: currentUnit)
        HStack {
            VStack(alignment: .leading) {
                Text(target.name).font(.body).fontWeight(.medium)
                Text("\(String(format: "%.1f", target.targetActivity)) \(target.unit.label)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                if currentActivity < targetInCurrentUnit {
                    Text("Passed").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                } else {
                    let seconds = DecayMath.solveForTime(currentActivity: currentActivity, targetActivity: targetInCurrentUnit, halfLife: isotope.halfLifeSeconds)
                    let futureDate = Date().addingTimeInterval(seconds)
                    Text(futureDate, style: .time).font(.callout).fontWeight(.bold).foregroundColor(Theme.accent)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

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
                    TextField("Reference Name", text: $referenceName).focused($isFocused)
                    Picker("Isotope", selection: $selectedIsotope) {
                        ForEach(isotopeStore.isotopes) { iso in Text("\(iso.name) (\(iso.symbol))").tag(iso) }
                    }
                }
                Section("Calibration") {
                    HStack {
                        TextField("Activity", value: $activity, format: .number).keyboardType(.decimalPad).focused($isFocused)
                        UnitSelector(selectedUnit: $unit)
                    }
                    DatePicker("Date", selection: $calibrationDate)
                }
            }
            .navigationTitle("New Tracker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        if let act = activity {
                            let newOrder = Reference(referenceName: referenceName, isotope: selectedIsotope, calibrationActivity: act, unit: unit, calibrationDate: calibrationDate)
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

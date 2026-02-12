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
    
    // Timer to update UI and Live Activity while app is in foreground
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
                                    // Stop activity if this specific order was live
                                    if order.isLive {
                                        stopActivity()
                                    }
                                    // Always cancel notifications on delete
                                    NotificationManager.shared.cancelNotifications(for: order)
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
            .onReceive(timer) { input in
                currentTime = input
                // Periodically update the Live Activity if it's running
                updateLiveActivityIfRunning()
            }
        }
    }
    
    // MARK: - Live Activity Management
    
    func updateLiveActivityIfRunning() {
        guard let liveOrder = referencesStore.references.first(where: { $0.isLive }) else { return }
        
        Task {
            for activity in Activity<DecayMateWidgetAttributes>.activities {
                let currentAct = DecayMath.solveForActivity(
                    A0: liveOrder.calibrationActivity,
                    halfLife: liveOrder.isotope.halfLifeSeconds,
                    elapsedSeconds: Date().timeIntervalSince(liveOrder.calibrationDate)
                )
                
                // Find next target logic
                let targetInfo = findNextTarget(for: liveOrder, currentActivity: currentAct)
                
                let contentState = DecayMateWidgetAttributes.ContentState(
                    currentActivity: currentAct,
                    unit: liveOrder.unit.label,
                    nextTargetName: targetInfo.name,
                    nextTargetActivity: targetInfo.activity,
                    nextTargetDate: targetInfo.date
                )
                
                await activity.update(
                    ActivityContent(state: contentState, staleDate: nil)
                )
            }
        }
    }
    
    // Shared Logic to find the closest upcoming target
    func findNextTarget(for reference: Reference, currentActivity: Double) -> (name: String?, activity: Double?, date: Date?) {
        let now = Date()
        var closestDate: Date? = nil
        var closestTarget: SavedTarget? = nil
        
        for target in reference.savedTargets {
            let targetInRefUnit = DecayMath.convert(target.targetActivity, from: target.unit, to: reference.unit)
            if currentActivity > targetInRefUnit {
                let seconds = DecayMath.solveForTime(
                    currentActivity: currentActivity,
                    targetActivity: targetInRefUnit,
                    halfLife: reference.isotope.halfLifeSeconds
                )
                let date = now.addingTimeInterval(seconds)
                
                if closestDate == nil || date < closestDate! {
                    closestDate = date
                    closestTarget = target
                }
            }
        }
        
        if let t = closestTarget, let d = closestDate {
            return (t.name, t.targetActivity, d)
        }
        return (nil, nil, nil)
    }
    
    func stopActivity() {
        Task {
            for activity in Activity<DecayMateWidgetAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
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
                        
                        // Status Icons
                        if order.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        if order.isLive {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        // Notification Icon (if targets exist)
                        if !order.savedTargets.isEmpty {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
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
    
    let parentView = LiveTrackerView(store: IsotopeStore()) // Helper instantiation
    
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
        // Changed from ScrollView + VStack to List + .insetGrouped for swipe support
        List {
            // SECTION 1: Reference Details (formerly ModernCard 1)
            Section {
                VStack(alignment: .leading, spacing: 12) {
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
                                .buttonStyle(.borderless) // FIX: Apply borderless button style
                            }
                            Divider()
                            
                            // Decoupled Controls
                            HStack(spacing: 12) {
                                Label(order.isotope.name, systemImage: "atom")
                                Spacer()
                                
                                // 1. Widget Pin Button
                                Button(action: toggleWidgetPin) {
                                    Image(systemName: order.isPinned ? "pin.fill" : "pin")
                                        .font(.caption)
                                        .frame(width: 32, height: 32)
                                        .background(order.isPinned ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                                        .foregroundColor(order.isPinned ? .blue : .secondary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.borderless) // FIX: Apply borderless button style
                                
                                // 2. Live Activity Button
                                Button(action: toggleLiveActivity) {
                                    Image(systemName: order.isLive ? "dot.radiowaves.left.and.right" : "iphone")
                                        .font(.caption)
                                        .frame(width: 32, height: 32)
                                        .background(order.isLive ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.1))
                                        .foregroundColor(order.isLive ? .orange : .secondary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.borderless) // FIX: Apply borderless button style
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // SECTION 2: Current Activity (formerly ModernCard 2)
            Section {
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
            
            // SECTION 3: Smart Targets (formerly ModernCard 3)
            Section {
                // Header Row
                HStack {
                    Text("Smart Targets")
                        .font(.headline)
                    Spacer()
                    Button {
                        isAddingTarget = true
                    } label: {
                        Label("Add", systemImage: "plus").font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonStyle(.borderless) // Ensure this one is also safe
                }
                
                Text("Track when this source will reach specific activity levels.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Targets List with Swipe to Delete
                if order.savedTargets.isEmpty {
                    Text("No targets saved.")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(order.savedTargets) { target in
                        TargetRow(target: target, currentActivity: currentActivity, currentUnit: selectedUnit, isotope: order.isotope)
                    }
                    .onDelete(perform: deleteTarget)
                }
            }
        }
        .listStyle(.insetGrouped) // Provides the card-like look with swipe support
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedUnit = order.unit }
        
        .alert("Rename Source", isPresented: $isEditingName) {
            TextField("Name", text: $newName)
            Button("Save") {
                var updated = order
                updated.referenceName = newName
                orderStore.update(updated)
                NotificationManager.shared.scheduleNotifications(for: updated)
                if updated.isLive { startActivity(for: updated) }
            }
            Button("Cancel", role: .cancel) {}
        }
        
        // REPLACED ALERT WITH SHEET FOR CONSISTENCY
        .sheet(isPresented: $isAddingTarget) {
            AddTargetSheet(currentUnit: selectedUnit) { newTarget in
                var updated = order
                updated.savedTargets.append(newTarget)
                orderStore.update(updated)
                
                // Schedule notifications
                NotificationManager.shared.scheduleNotifications(for: updated)
                
                // Update live activity if active
                if updated.isLive { startActivity(for: updated) }
            }
        }
        
        .onChange(of: selectedUnit) { oldValue, newValue in
            guard oldValue != newValue else { return }
            var updated = order
            updated.unit = newValue
            updated.calibrationActivity = DecayMath.convert(updated.calibrationActivity, from: oldValue, to: newValue)
            orderStore.update(updated)
            NotificationManager.shared.scheduleNotifications(for: updated)
        }
    }
    
    // MARK: - Actions
    
    func deleteTarget(at offsets: IndexSet) {
        var updated = order
        updated.savedTargets.remove(atOffsets: offsets)
        orderStore.update(updated)
        
        // Refresh notifications (clears deleted ones, keeps others)
        NotificationManager.shared.scheduleNotifications(for: updated)
        
        // Refresh live activity if needed
        if updated.isLive {
            startActivity(for: updated)
        }
    }
    
    func toggleWidgetPin() {
        var updated = order
        updated.isPinned.toggle()
        orderStore.update(updated)
    }
    
    func toggleLiveActivity() {
        var updated = order
        updated.isLive.toggle()
        orderStore.update(updated)
        
        if updated.isLive {
            startActivity(for: updated)
        } else {
            stopActivity()
        }
    }
    
    func startActivity(for reference: Reference) {
        Task {
            // Clean up old activities
            for activity in Activity<DecayMateWidgetAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            
            // Setup Attributes
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
            
            // Calculate Next Target
            let targetInfo = parentView.findNextTarget(for: reference, currentActivity: currentAct)
            
            let contentState = DecayMateWidgetAttributes.ContentState(
                currentActivity: currentAct,
                unit: reference.unit.label,
                nextTargetName: targetInfo.name,
                nextTargetActivity: targetInfo.activity,
                nextTargetDate: targetInfo.date
            )
            
            let activityContent = ActivityContent(state: contentState, staleDate: nil)
            
            do {
                let activity = try Activity.request(attributes: attributes, content: activityContent, pushType: nil)
                print("Live Activity Started: \(activity.id)")
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

// (Helper Structs)

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

// NEW: Dedicated Sheet for Adding Targets
struct AddTargetSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentUnit: ActivityUnit
    let onSave: (SavedTarget) -> Void
    
    @State private var name = ""
    @State private var activity: Double?
    @State private var unit: ActivityUnit
    @FocusState private var isFocused: Bool
    
    init(currentUnit: ActivityUnit, onSave: @escaping (SavedTarget) -> Void) {
        self.currentUnit = currentUnit
        self.onSave = onSave
        _unit = State(initialValue: currentUnit)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Target Details") {
                    TextField("Label (e.g. Disposal Limit)", text: $name)
                        .focused($isFocused)
                    
                    HStack {
                        TextField("Activity", value: $activity, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                        UnitSelector(selectedUnit: $unit)
                    }
                }
            }
            .navigationTitle("New Target")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let act = activity, !name.isEmpty {
                            let newTarget = SavedTarget(name: name, targetActivity: act, unit: unit)
                            onSave(newTarget)
                            dismiss()
                        }
                    }
                    .disabled(activity == nil || name.isEmpty)
                }
            }
        }
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
                            
                            // Schedule notifications on creation
                            NotificationManager.shared.scheduleNotifications(for: newOrder)
                            
                            dismiss()
                        }
                    }
                    .disabled(activity == nil)
                }
            }
        }
    }
}

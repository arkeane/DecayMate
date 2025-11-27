//
//  ContentView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

// MARK: - Main Tab Entry
struct ContentView: View {
    @StateObject private var isotopeStore = IsotopeStore()
    
    // We set the default selection to '1', which corresponds to the Decay tab below
    @State private var selection = 1
    
    init() {
        // Customizing Tab Bar appearance for that "Modern" look
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selection) {
            
            // 0: NEW Live Tracker (Leftmost)
            LiveTrackerView(store: isotopeStore)
                .tabItem {
                    Label("Tracker", systemImage: "timer")
                }
                .tag(0)
            
            // 1: Decay Calculator (Default)
            DecayCalculatorView(store: isotopeStore)
                .tabItem {
                    Label("Decay", systemImage: "waveform.path.ecg")
                }
                .tag(1)
            
            // 2: Target Dose
            TargetDoseView(store: isotopeStore)
                .tabItem {
                    Label("Target Dose", systemImage: "cross.case.fill")
                }
                .tag(2)
            
            // 3: Manager
            CustomIsotopeView(store: isotopeStore)
                .tabItem {
                    Label("Manager", systemImage: "flask")
                }
                .tag(3)
            
            // 4: Info
            InfoView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(4)
        }
        .tint(Theme.accent)
    }
}

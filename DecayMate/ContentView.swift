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
    
    init() {
        // Customizing Tab Bar appearance for that "Modern" look
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            DecayCalculatorView(store: isotopeStore)
                .tabItem {
                    Label("Decay", systemImage: "waveform.path.ecg")
                }
            
            TargetDoseView(store: isotopeStore)
                .tabItem {
                    Label("Target Dose", systemImage: "cross.case.fill")
                }
            
            CustomIsotopeView(store: isotopeStore)
                .tabItem {
                    Label("Manager", systemImage: "flask")
                }
            
            InfoView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .tint(Theme.accent)
    }
}

//
//  InfoView.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

struct InfoView: View {
    
    // Computed property to fetch version dynamically from Bundle
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (Build \(build))"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        
                        // Disclaimer Card
                        ModernCard {
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                    .padding(.trailing, 4)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Medical Disclaimer")
                                        .font(.headline)
                                    
                                    Text("This application is intended for educational and reference purposes only. It is not a certified medical device.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Do not use this application for clinical decision-making or patient dose calculations without verifying results with certified equipment and protocols.")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.danger)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        // Developer Info Card
                        ModernCard {
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(Theme.accent)
                                
                                VStack(alignment: .leading) {
                                    Text("Ludovico Pestarino")
                                        .font(.headline)
                                    // UPDATED: Now uses the dynamic variable
                                    Text(appVersion)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Built with SwiftUI", systemImage: "swift")
                                Label("Secure Local Storage", systemImage: "lock.shield")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        
                        Text("© 2025 Ludovico Pestarino")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("About")
        }
    }
}

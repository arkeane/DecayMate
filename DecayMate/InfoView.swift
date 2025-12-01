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
                                    Text("Disclaimer")
                                        .font(.headline)
                                    
                                    Text("This application is a physics utility designed to calculate the radioactive decay of isotopes based on standard half-life data.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("It is for educational and reference purposes only.")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary) // Less aggressive color than danger/red
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
                        
                        // NEW: Connect / Links Card
                        ModernCard {
                            Text("Connect")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 0) {
                                // Contact Button (Mailto)
                                LinkRow(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    url: URL(string: "mailto:ludovico@pestarino.io")!
                                )
                                
                                Divider().padding(.leading, 32)
                                
                                // Privacy Policy
                                LinkRow(
                                    icon: "hand.raised.fill",
                                    title: "Privacy Policy",
                                    url: URL(string: "https://dev.pestarino.io/privacy")!
                                )
                                
                                Divider().padding(.leading, 32)
                                
                                // GitHub
                                LinkRow(
                                    icon: "chevron.left.forwardslash.chevron.right",
                                    title: "GitHub Repository",
                                    url: URL(string: "https://github.com/arkeane/DecayMate")!
                                )
                            }
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
    
    // Helper View for the links
    func LinkRow(icon: String, title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(Theme.accent)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.tertiaryLabel)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // Makes the whole row tappable
        }
    }
}

// Helper extension for color support in LinkRow
extension Color {
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
}

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
                                        .foregroundColor(.secondary)
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
                        
                        // Connect & Legal Card
                        ModernCard {
                            Text("Connect & Legal")
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
                                
                                Divider().padding(.leading, 32)
                                
                                // Open Source License
                                NavigationLink(destination: LicenseView()) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .frame(width: 24)
                                            .foregroundColor(Theme.accent)
                                        Text("Open Source License")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                                    }
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                            }
                        }
                        
                        Text("© 2026 Ludovico Pestarino")
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
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // Makes the whole row tappable
        }
    }
}

// MARK: - License View
struct LicenseView: View {
    let licenseText = """
    BSD 3-Clause License

    Copyright (c) 2026, Ludovico Pestarino

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its
       contributors may be used to endorse or promote products derived from
       this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    """
    
    var body: some View {
        ScrollView {
            Text(licenseText)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding()
        }
        .navigationTitle("License")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.bg.ignoresSafeArea())
    }
}

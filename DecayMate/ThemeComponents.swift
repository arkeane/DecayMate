//
//  ThemeComponents.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import SwiftUI

// MARK: - Design System Constants
struct Theme {
    static let bg = Color(uiColor: .systemGroupedBackground)
    static let cardBg = Color(uiColor: .secondarySystemGroupedBackground)
    static let accent = Color.blue
    static let danger = Color.red
    static let cornerRadius: CGFloat = 20
    static let shadowRadius: CGFloat = 8
    static let padding: CGFloat = 16
}

// MARK: - Modern Card View
struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBg)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: Theme.shadowRadius, x: 0, y: 4)
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 8)
    }
}

// MARK: - Unit Selector
struct UnitSelector: View {
    @Binding var selectedUnit: ActivityUnit
    
    var body: some View {
        Picker("Unit", selection: $selectedUnit) {
            ForEach(ActivityUnit.allCases) { unit in
                Text(unit.label).tag(unit)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 150)
    }
}

// MARK: - Isotope Selector Header
struct IsotopeSelectorHeader: View {
    @Binding var selection: Isotope
    var isotopes: [Isotope]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Select Radionuclide")
                .font(.caption)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            Menu {
                ForEach(isotopes) { iso in
                    Button {
                        selection = iso
                    } label: {
                        HStack {
                            Text(iso.name)
                            Spacer()
                            Text(iso.symbol).foregroundColor(.secondary)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "atom")
                        .font(.system(size: 20))
                    Text(selection.symbol)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(selection.name)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Material.regular)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Text("Half-life: \(selection.halfLifeString)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

// MARK: - Result View
struct ResultDisplay: View {
    let title: String
    let value: Double
    let unit: String
    let date: Date?
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", value))
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
                
                Text(unit)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            
            if let date = date {
                Text("at \(date.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
}

//
//  RadionuclideModels.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Enums & Data Types

enum ActivityUnit: String, CaseIterable, Identifiable {
    case mCi
    case MBq
    
    var id: String { self.rawValue }
    
    var label: String {
        switch self {
        case .mCi: return "mCi"
        case .MBq: return "MBq"
        }
    }
}

// MARK: - Isotope Model

struct Isotope: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let symbol: String
    let halfLifeSeconds: Double
    
    var halfLifeString: String {
        if halfLifeSeconds < 3600 {
            return String(format: "%.1f min", halfLifeSeconds / 60)
        } else if halfLifeSeconds < 86400 {
            return String(format: "%.2f hours", halfLifeSeconds / 3600)
        } else {
            return String(format: "%.2f days", halfLifeSeconds / 86400)
        }
    }
    
    // Default Medical Isotopes
    static let defaults: [Isotope] = [
        Isotope(name: "Technetium-99m", symbol: "Tc-99m", halfLifeSeconds: 6.0067 * 3600),
        Isotope(name: "Fluorine-18", symbol: "F-18", halfLifeSeconds: 109.77 * 60),
        Isotope(name: "Iodine-131", symbol: "I-131", halfLifeSeconds: 8.02 * 86400),
        Isotope(name: "Gallium-68", symbol: "Ga-68", halfLifeSeconds: 67.71 * 60),
        Isotope(name: "Lutetium-177", symbol: "Lu-177", halfLifeSeconds: 6.647 * 86400),
        Isotope(name: "Iodine-123", symbol: "I-123", halfLifeSeconds: 13.22 * 3600),
        Isotope(name: "Thallium-201", symbol: "Tl-201", halfLifeSeconds: 72.91 * 3600)
    ]
}

// MARK: - Data Store
class IsotopeStore: ObservableObject {
    @Published var isotopes: [Isotope] = []
    
    private let saveKey = "SavedIsotopes"
    
    init() {
        load()
    }
    
    func add(isotope: Isotope) {
        isotopes.append(isotope)
        save()
    }
    
    func update(_ isotope: Isotope) {
        if let index = isotopes.firstIndex(where: { $0.id == isotope.id }) {
            isotopes[index] = isotope
            save()
        }
    }
    
    func delete(id: UUID) {
        isotopes.removeAll { $0.id == id }
        save()
    }
    
    func delete(at offsets: IndexSet) {
        isotopes.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Persistence Logic
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(isotopes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Isotope].self, from: data) {
            self.isotopes = decoded
        } else {
            // First run: Load defaults
            self.isotopes = Isotope.defaults
        }
    }
}

// MARK: - Physics Engine

class DecayEngine {
    
    static let shared = DecayEngine()
    
    func convert(_ value: Double, from source: ActivityUnit, to target: ActivityUnit) -> Double {
        if source == target { return value }
        switch source {
        case .mCi: return value * 37.0
        case .MBq: return value / 37.0
        }
    }
    
    func calculateDecay(A0: Double, halfLife: Double, elapsedSeconds: Double) -> Double {
        let decayConstant = 0.69314718056 / halfLife
        return A0 * exp(-decayConstant * elapsedSeconds)
    }
    
    func calculateRequiredSource(targetActivity: Double, halfLife: Double, durationSeconds: Double) -> Double {
        let decayConstant = 0.69314718056 / halfLife
        return targetActivity * exp(decayConstant * durationSeconds)
    }
}

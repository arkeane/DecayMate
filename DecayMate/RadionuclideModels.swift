//
//  RadionuclideModels.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import Foundation
import Combine
import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Constants & Config
struct PhysicsConstants {
    static let ln2 = 0.69314718056
}

struct AppConfig {
    // IMPORTANT: Enable "App Groups" in Xcode Signing & Capabilities
    static let appGroupSuiteName = "group.pestarino.io.DecayMate"
}

// MARK: - Live Activity Attributes
struct DecayMateWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentActivity: Double
        var unit: String
        var nextTargetName: String?
        var nextTargetActivity: Double?
        var nextTargetDate: Date?
    }

    var isotopeName: String
    var isotopeSymbol: String
    var referenceName: String
    var calibrationDate: Date
    var calibrationActivity: Double
    var halfLife: Double
}

// MARK: - Units
enum ActivityUnit: String, CaseIterable, Codable, Identifiable {
    case Ci = "Ci"
    case mCi = "mCi"
    case uCi = "µCi"
    case TBq = "TBq"
    case GBq = "GBq"
    case MBq = "MBq"
    case kBq = "kBq"
    
    var id: String { self.rawValue }
    var label: String { self.rawValue }
    
    var toMBqFactor: Double {
        switch self {
        case .Ci: return 37000.0
        case .mCi: return 37.0
        case .uCi: return 0.037
        case .TBq: return 1000000.0
        case .GBq: return 1000.0
        case .MBq: return 1.0
        case .kBq: return 0.001
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
    
    static let defaults: [Isotope] = [
        Isotope(name: "Technetium-99m", symbol: "Tc-99m", halfLifeSeconds: 21624),
        Isotope(name: "Fluorine-18", symbol: "F-18", halfLifeSeconds: 6586),
        Isotope(name: "Iodine-131", symbol: "I-131", halfLifeSeconds: 692928),
        Isotope(name: "Lutetium-177", symbol: "Lu-177", halfLifeSeconds: 574300),
        Isotope(name: "Gallium-68", symbol: "Ga-68", halfLifeSeconds: 4063),
        Isotope(name: "Iodine-123", symbol: "I-123", halfLifeSeconds: 47592),
        Isotope(name: "Thallium-201", symbol: "Tl-201", halfLifeSeconds: 262476),
        Isotope(name: "Cobalt-57", symbol: "Co-57", halfLifeSeconds: 23483520),
        Isotope(name: "Cesium-137", symbol: "Cs-137", halfLifeSeconds: 946700000)
    ]
}

// MARK: - Saved Targets
struct SavedTarget: Identifiable, Codable {
    var id = UUID()
    var name: String
    var targetActivity: Double
    var unit: ActivityUnit
}

// MARK: - Reference/Order Model
struct Reference: Identifiable, Codable {
    var id = UUID()
    var referenceName: String
    var isotope: Isotope
    var calibrationActivity: Double
    var unit: ActivityUnit
    var calibrationDate: Date
    
    var isPinned: Bool = false // Widget
    var isLive: Bool = false   // Live Activity
    var savedTargets: [SavedTarget] = []
}

// MARK: - Data Stores
class IsotopeStore: ObservableObject {
    @Published var isotopes: [Isotope] = []
    private let saveKey = "SavedIsotopes"
    private let defaults: UserDefaults
    
    init() {
        self.defaults = UserDefaults(suiteName: AppConfig.appGroupSuiteName) ?? .standard
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
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(isotopes) {
            defaults.set(encoded, forKey: saveKey)
        }
    }
    
    private func load() {
        if let data = defaults.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Isotope].self, from: data) {
            self.isotopes = decoded
        } else {
            self.isotopes = Isotope.defaults
        }
    }
}

class OrderStore: ObservableObject {
    @Published var references: [Reference] = []
    private let saveKey = "SavedReferences"
    private let defaults: UserDefaults
    
    init() {
        self.defaults = UserDefaults(suiteName: AppConfig.appGroupSuiteName) ?? .standard
        load()
    }
    
    func add(_ order: Reference) {
        references.append(order)
        save()
    }
    
    func update(_ order: Reference) {
        if let index = references.firstIndex(where: { $0.id == order.id }) {
            references[index] = order
            save()
        }
        
        // Exclusivity: Widget (isPinned)
        if order.isPinned {
            for i in 0..<references.count {
                if references[i].id != order.id {
                    references[i].isPinned = false
                }
            }
            save()
        }
        
        // Exclusivity: Live Activity (isLive)
        if order.isLive {
            for i in 0..<references.count {
                if references[i].id != order.id {
                    references[i].isLive = false
                }
            }
            save()
        }
    }
    
    func delete(_ order: Reference) {
        references.removeAll { $0.id == order.id }
        save()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(references) {
            defaults.set(encoded, forKey: saveKey)
            // Reload Widgets
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func load() {
        if let data = defaults.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Reference].self, from: data) {
            self.references = decoded
        }
    }
}

// MARK: - Physics Engine
struct DecayMath {
    static func convert(_ value: Double, from source: ActivityUnit, to target: ActivityUnit) -> Double {
        if source == target { return value }
        let valueInMBq = value * source.toMBqFactor
        return valueInMBq / target.toMBqFactor
    }
    
    static func solveForActivity(A0: Double, halfLife: Double, elapsedSeconds: Double) -> Double {
        let lambda = PhysicsConstants.ln2 / halfLife
        return A0 * exp(-lambda * elapsedSeconds)
    }
    
    static func solveForInitial(targetActivity: Double, halfLife: Double, durationSeconds: Double) -> Double {
        let lambda = PhysicsConstants.ln2 / halfLife
        return targetActivity * exp(lambda * durationSeconds)
    }
    
    static func solveForTime(currentActivity: Double, targetActivity: Double, halfLife: Double) -> Double {
        guard currentActivity > 0, targetActivity > 0 else { return 0 }
        let lambda = PhysicsConstants.ln2 / halfLife
        return -log(targetActivity / currentActivity) / lambda
    }
}

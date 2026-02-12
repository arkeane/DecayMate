//
//  NotificationManager.swift
//  DecayMate
//
//  Created by Ludovico Pestarino on 26/11/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedules notifications for all valid targets in a reference
    func scheduleNotifications(for reference: Reference) {
        // 1. Always clear old notifications for this reference first to avoid duplicates
        cancelNotifications(for: reference)
        
        let now = Date()
        let currentActivity = DecayMath.solveForActivity(
            A0: reference.calibrationActivity,
            halfLife: reference.isotope.halfLifeSeconds,
            elapsedSeconds: now.timeIntervalSince(reference.calibrationDate)
        )
        
        // 2. Loop through targets and schedule
        for target in reference.savedTargets {
            // Convert target activity to reference unit for comparison
            let targetInRefUnit = DecayMath.convert(target.targetActivity, from: target.unit, to: reference.unit)
            
            // Only schedule if we haven't reached it yet (Current > Target)
            if currentActivity > targetInRefUnit {
                let secondsRemaining = DecayMath.solveForTime(
                    currentActivity: currentActivity,
                    targetActivity: targetInRefUnit,
                    halfLife: reference.isotope.halfLifeSeconds
                )
                
                // Add a small buffer (e.g. 1 second) to ensure calculation stability
                let fireDate = now.addingTimeInterval(secondsRemaining)
                
                // Only schedule if the date is in the future
                if fireDate > now {
                    scheduleSingleNotification(reference: reference, target: target, fireDate: fireDate)
                }
            }
        }
    }
    
    private func scheduleSingleNotification(reference: Reference, target: SavedTarget, fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Target Reached: \(target.name)"
        content.body = "\(reference.isotope.symbol) has decayed to \(String(format: "%.2f", target.targetActivity)) \(target.unit.label)."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        // Create date components trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Unique identifier: RefID + TargetID
        let id = "\(reference.id.uuidString)-\(target.id.uuidString)"
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Scheduled '\(target.name)' for \(fireDate.formatted())")
            }
        }
    }
    
    func cancelNotifications(for reference: Reference) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let refPrefix = reference.id.uuidString
            let idsToRemove = requests
                .filter { $0.identifier.starts(with: refPrefix) }
                .map { $0.identifier }
            
            if !idsToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
                print("Cancelled \(idsToRemove.count) notifications for \(reference.referenceName)")
            }
        }
    }
}

//
//  DecayMateWidget.swift
//  DecayMateWidget
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import WidgetKit
import SwiftUI

// MARK: - TIMELINE PROVIDER
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DecayEntry {
        DecayEntry(date: Date(), reference: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (DecayEntry) -> ()) {
        let entry = DecayEntry(date: Date(), reference: loadPinnedReference())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DecayEntry>) -> ()) {
        let currentDate = Date()
        let pinnedRef = loadPinnedReference()
        
        var entries: [DecayEntry] = []
        // Generate entries for the next 15 minutes to keep it updated
        for minuteOffset in 0 ..< 15 {
            if let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) {
                entries.append(DecayEntry(date: entryDate, reference: pinnedRef))
            }
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadPinnedReference() -> Reference? {
        guard let defaults = UserDefaults(suiteName: AppConfig.appGroupSuiteName),
              let data = defaults.data(forKey: "SavedReferences"),
              let references = try? JSONDecoder().decode([Reference].self, from: data)
        else { return nil }
        
        return references.first(where: { $0.isPinned })
    }
}

// MARK: - TIMELINE ENTRY
struct DecayEntry: TimelineEntry {
    let date: Date
    let reference: Reference?
}

// MARK: - WIDGET VIEW
struct DecayMateWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            if let ref = entry.reference {
                // Top Row: Isotope Symbol & Icon
                HStack {
                    Text(ref.isotope.symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Spacer()
                    Image(systemName: "atom")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                // Middle Row: Calculated Activity
                let currentAct = DecayMath.solveForActivity(
                    A0: ref.calibrationActivity,
                    halfLife: ref.isotope.halfLifeSeconds,
                    elapsedSeconds: entry.date.timeIntervalSince(ref.calibrationDate)
                )
                
                Text(String(format: "%.1f", currentAct))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                
                Text(ref.unit.label)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Bottom Row: Reference Name
                if !ref.referenceName.isEmpty {
                    Text(ref.referenceName)
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            } else {
                // Empty State
                VStack(spacing: 8) {
                    Image(systemName: "pin.slash")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No Pinned Source")
                        .font(.headline)
                    Text("Pin a source in the app to track it here.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // REQUIRED FOR iOS 17+
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

// MARK: - WIDGET CONFIGURATION
struct DecayMateWidget: Widget {
    let kind: String = "DecayMateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DecayMateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Live Source Tracker")
        .description("Track your pinned source activity in real-time.")
        .supportedFamilies([.systemSmall])
    }
}

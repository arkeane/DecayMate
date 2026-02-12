//
//  DecayMateWidgetLiveActivity.swift
//  DecayMateWidget
//
//  Created by Ludovico Pestarino on 12/02/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DecayMateWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        // We use the shared attributes defined in RadionuclideModels.swift
        ActivityConfiguration(for: DecayMateWidgetAttributes.self) { context in
            // MARK: - Lock Screen / Banner UI
            VStack(spacing: 0) {
                // Top Row: Info
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(context.attributes.isotopeSymbol)
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(context.attributes.referenceName.isEmpty ? "Source" : context.attributes.referenceName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f", context.state.currentActivity))
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .contentTransition(.numericText(value: context.state.currentActivity))
                        Text(context.state.unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
                
                // Bottom Row: Target Timer (Uber Style)
                if let targetDate = context.state.nextTargetDate,
                   let targetName = context.state.nextTargetName {
                    Divider()
                        .padding(.bottom, 10)
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                        Text("Reaching \(targetName)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        // THIS IS THE KEY: A native counting down timer
                        Text(targetDate, style: .timer)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(UIColor.systemBackground))
            .activitySystemActionForegroundColor(Color.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Island
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.isotopeSymbol)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("\(String(format: "%.1f", context.state.currentActivity)) \(context.state.unit)")
                            .monospacedDigit()
                            .font(.headline)
                            .padding(.trailing, 8)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if let targetDate = context.state.nextTargetDate {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                                .font(.caption2)
                            Text(targetDate, style: .timer)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .monospacedDigit()
                        }
                        .padding(.top, 4)
                    } else {
                        Text(context.attributes.referenceName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                // MARK: - Compact Island
                Text(context.attributes.isotopeSymbol)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            } compactTrailing: {
                if let targetDate = context.state.nextTargetDate {
                    Text(targetDate, style: .timer)
                        .monospacedDigit()
                        .foregroundColor(.orange)
                        .frame(maxWidth: 40)
                } else {
                    Text(String(format: "%.1f", context.state.currentActivity))
                        .monospacedDigit()
                }
            } minimal: {
                // Minimal view
                Image(systemName: "atom.fill")
                    .foregroundColor(.blue)
            }
            .keylineTint(Color.blue)
        }
    }
}

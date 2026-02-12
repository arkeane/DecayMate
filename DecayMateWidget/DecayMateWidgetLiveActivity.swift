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
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.isotopeSymbol)
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text(context.attributes.referenceName.isEmpty ? "Source" : context.attributes.referenceName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f", context.state.currentActivity))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                    Text(context.state.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color(.secondarySystemBackground))
            .activitySystemActionForegroundColor(Color.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Dynamic Island Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.isotopeSymbol)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(String(format: "%.1f", context.state.currentActivity)) \(context.state.unit)")
                        .monospacedDigit()
                        .font(.headline)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.referenceName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } compactLeading: {
                // MARK: - Compact Island
                Text(context.attributes.isotopeSymbol)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(String(format: "%.1f", context.state.currentActivity))
                    .monospacedDigit()
            } minimal: {
                // Ensure minimal view is distinct
                Image(systemName: "atom.fill")
                    .foregroundColor(.blue)
            }
            .keylineTint(Color.blue)
        }
    }
}

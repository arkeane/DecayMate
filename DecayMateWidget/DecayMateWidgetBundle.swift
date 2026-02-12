//
//  DecayMateWidgetBundle.swift
//  DecayMateWidget
//
//  Created by Ludovico Pestarino on 25/11/25.
//

import WidgetKit
import SwiftUI

@main
struct DecayMateWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 1. The Standard Home Screen Widget
        DecayMateWidget()
        
        // 2. The Dynamic Island / Lock Screen Activity
        DecayMateWidgetLiveActivity()
    }
}

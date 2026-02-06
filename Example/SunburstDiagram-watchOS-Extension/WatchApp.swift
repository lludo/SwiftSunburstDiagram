//
//  WatchApp.swift
//  SunburstDiagramDemoWatch Watch App
//
//  Created by Ludo on 2/4/26.
//  Copyright © 2026 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI

@main
struct SunburstDiagramDemoWatchApp: App {
    @StateObject private var configuration: SunburstConfiguration

    init() {
        let configuration = SunburstConfiguration(nodes: SampleData.nodes(), calculationMode: .ordinalFromLeaves)
        configuration.expandedArcThickness = 52.0
        configuration.maximumExpandedRingsShownCount = 2
        configuration.maximumRingsShownCount = 4
        _configuration = StateObject(wrappedValue: configuration)
    }

    var body: some Scene {
        WindowGroup {
            SunburstView(configuration: configuration)
                .padding()
        }
    }
}

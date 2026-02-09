//
//  AppDelegate.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI

@main
struct SunburstDiagramDemoApp: App {
    @StateObject private var configuration: SunburstConfiguration
    @StateObject private var dataStore: DemoDataStore

    init() {
        let configuration = SunburstConfiguration(nodes: SampleData.nodes(), calculationMode: .ordinalFromLeaves)
        let dataStore = DemoDataStore(configuration: configuration)
        _configuration = StateObject(wrappedValue: configuration)
        _dataStore = StateObject(wrappedValue: dataStore)
    }

    var body: some Scene {
        WindowGroup {
            RootView(configuration: configuration, dataStore: dataStore)
        }
    }
}

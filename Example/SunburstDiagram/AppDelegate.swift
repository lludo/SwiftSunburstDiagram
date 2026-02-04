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

    init() {
        let configuration = SunburstConfiguration(nodes: SampleData.nodes(), calculationMode: .ordinalFromLeaves)
        configuration.expandedArcThickness = 52.0
        configuration.maximumExpandedRingsShownCount = 2
        configuration.maximumRingsShownCount = 4
        _configuration = StateObject(wrappedValue: configuration)
    }

    var body: some Scene {
        WindowGroup {
            RootView(configuration: configuration)
        }
    }
}

private enum SampleData {
    static func nodes() -> [Node] {
        [
            Node(name: "Walking", showName: false, image: .asset(name: "walking"), value: 10.0, backgroundColor: .system(.blue)),
            Node(name: "Restaurant", showName: false, image: .asset(name: "eating"), value: 30.0, backgroundColor: .system(.red), children: [
                Node(name: "Dessert", showName: false, image: .asset(name: "croissant"), value: 10.0, backgroundColor: .system(.yellow), children: [
                    Node(name: "Creme Brulee", showName: false, value: 3.0, backgroundColor: .system(.yellow)),
                    Node(name: "Crepes", showName: false, value: 6.0, backgroundColor: .system(.yellow), children: [
                        Node(name: "Nutella Crepe", showName: false, value: 4.0, backgroundColor: .system(.yellow)),
                    ]),
                ]),
                Node(name: "Dinner", showName: false, image: .asset(name: "poultry"), value: 5.0, backgroundColor: .system(.orange), children: [
                    Node(name: "Pizza", showName: false, value: 4.0, backgroundColor: .system(.orange)),
                ]),
            ]),
            Node(name: "Transport", showName: false, image: .asset(name: "sailing"), value: 10.0, backgroundColor: .system(.purple)),
            Node(name: "Home", showName: false, image: .asset(name: "house"), value: 45.0, backgroundColor: .system(.teal), children: [
                Node(name: "San Francisco", showName: false, image: .asset(name: "house"), value: 15.0, backgroundColor: .system(.teal), children: [
                    Node(name: "Twin Peaks", showName: false, value: 3.0, backgroundColor: .system(.teal)),
                    Node(name: "Hayes Valley", showName: false, value: 1.5, backgroundColor: .system(.teal)),
                    Node(name: "Nob Hill", showName: false, value: 8.0, backgroundColor: .system(.teal)),
                ]),
                Node(name: "Lyon", showName: false, image: .asset(name: "house"), value: 6.0, backgroundColor: .system(.teal)),
            ]),
        ]
    }
}

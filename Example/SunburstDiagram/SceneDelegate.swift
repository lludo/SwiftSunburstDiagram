//
//  SceneDelegate.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import UIKit
import SunburstDiagram
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        let nodes = sampleNodes()
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .ordinalFromLeaves)

        configuration.expandedArcThickness = 56.0
        configuration.maximumExpandedRingsShownCount = 2
        configuration.maximumRingsShownCount = 4

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: RootView(configuration: configuration))
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sampleNodes() -> [Node] {
        let nodes = [
            Node(name: "Walking", showName: false, image: UIImage(named: "walking"), value: 10.0, backgroundColor: .systemBlue),
            Node(name: "Restaurant", showName: false, image: UIImage(named: "eating"), value: 30.0, backgroundColor: .systemRed, children: [
                Node(name: "Dessert", showName: false, image: UIImage(named: "croissant"), value: 10.0, backgroundColor: .systemYellow, children: [
                    Node(name: "Creme Brulee", showName: false, value: 3.0, backgroundColor: .systemYellow),
                    Node(name: "Crepes", showName: false, value: 6.0, backgroundColor: .systemYellow, children: [
                        Node(name: "Nutella Crepe", showName: false, value: 4.0, backgroundColor: .systemYellow),
                    ]),
                ]),
                Node(name: "Dinner", showName: false, image: UIImage(named: "poultry"), value: 5.0, backgroundColor: .systemOrange, children: [
                    Node(name: "Pizza", showName: false, value: 4.0, backgroundColor: .systemOrange),
                ]),
            ]),
            Node(name: "Transport", showName: false, image: UIImage(named: "sailing"), value: 10.0, backgroundColor: .systemPurple),
            Node(name: "Home", showName: false, image: UIImage(named: "house"), value: 45.0, backgroundColor: .systemTeal, children: [
                Node(name: "San Francisco", showName: false, image: UIImage(named: "house"), value: 15.0, backgroundColor: .systemTeal, children: [
                    Node(name: "Twin Peaks", showName: false, value: 3.0, backgroundColor: .systemTeal),
                    Node(name: "Hayes Valley", showName: false, value: 1.5, backgroundColor: .systemTeal),
                    Node(name: "Nob Hill", showName: false, value: 8.0, backgroundColor: .systemTeal),
                ]),
                Node(name: "Lyon", showName: false, image: UIImage(named: "house"), value: 6.0, backgroundColor: .systemTeal),
            ]),
        ]

        return nodes
    }
}

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

        let configuration = SunburstConfiguration(nodes: [
            Node(name: "Walking", showName: false, image: UIImage(named: "walking"), value: 10.0, backgroundColor: .systemBlue),
            Node(name: "Restaurant", showName: false, image: UIImage(named: "eating"), value: 30.0, backgroundColor: .systemRed, children: [
                Node(name: "Dessert", showName: false, image: UIImage(named: "croissant"), value: 10.0, backgroundColor: .systemYellow),
                Node(name: "Dinner", showName: false, image: UIImage(named: "poultry"), value: 5.0, backgroundColor: .systemOrange),
            ]),
            Node(name: "Transport", showName: false, image: UIImage(named: "sailing"), value: 10.0, backgroundColor: .systemPurple),
            Node(name: "Home", showName: false, image: UIImage(named: "house"), value: 45.0, backgroundColor: .systemTeal),
        ], calculationMode: .parentDependent(totalValue: 100.0))

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: RootView(configuration: configuration))
        self.window = window
        window.makeKeyAndVisible()
    }
}

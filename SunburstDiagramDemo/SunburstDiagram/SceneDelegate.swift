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

    var sunburstViewController: UIViewController!
    var settingsViewController: UIViewController!
    
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

//        configuration.innerRadius = 90.0
//        configuration.expandedArcThickness = 90.0
//        configuration.marginBetweenArcs = 3.0

        self.sunburstViewController = UIHostingController(rootView: SunburstView.configureWith(configuration))
        self.settingsViewController = UIHostingController(rootView: SettingsView())

        let splitViewController = UISplitViewController()
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        splitViewController.viewControllers = [self.settingsViewController, self.sunburstViewController]
        
        splitViewController.view.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.sunburstViewController.view.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.settingsViewController.view.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = splitViewController
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        return self.sunburstViewController
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        return self.settingsViewController
    }
}

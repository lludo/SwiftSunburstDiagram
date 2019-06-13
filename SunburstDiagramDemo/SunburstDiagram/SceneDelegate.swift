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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        let ring = Ring(arcs: [
            Ring.Arc(text: "Walking", image: UIImage(named: "walking"), width: 0.8, hue: 0.3, isTextHidden: true),
            Ring.Arc(text: "Restaurant", image: UIImage(named: "eating"), width: 2.1, hue: 0.6, childArcs: [
                Ring.Arc(text: "Desert", image: UIImage(named: "croissant"), width: 0.6, hue: 0.65, isTextHidden: true),
                Ring.Arc(text: "Diner", image: UIImage(named: "poultry"), width: 0.8, hue: 0.7, isTextHidden: true),
            ], isTextHidden: true),
            Ring.Arc(text: "Transport", image: UIImage(named: "sailing"), width: 1.0, hue: 0.9, isTextHidden: true),
            Ring.Arc(text: "Home", image: UIImage(named: "house"), width: 2.3, hue: 0.1, isTextHidden: true)
        ])
        
        ring.randomWalk = true // For testing
        
        // Use a UIHostingController as window root view controller
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: RingView().environmentObject(ring))
        self.window = window
        window.makeKeyAndVisible()
    }
}

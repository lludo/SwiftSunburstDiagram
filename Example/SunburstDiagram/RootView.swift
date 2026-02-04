//
//  RootView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/18/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI

struct RootView: View {

    @ObservedObject var configuration: SunburstConfiguration
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width <= geometry.size.height {
                VStack(spacing: 0) {
                    SunburstView(configuration: configuration)
                    Divider()
                        .ignoresSafeArea()
                    SettingsView(configuration: configuration)
                }
            } else {
                HStack(spacing: 0) {
                    SunburstView(configuration: configuration)
                        .ignoresSafeArea()
                    Divider()
                        .ignoresSafeArea()
                    SettingsView(configuration: configuration)
                }
            }
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let configuration = SunburstConfiguration(nodes: [
            Node(name: "Walking",
                 showName: false,
                 image: .asset(name: "walking"),
                 value: 10.0,
                 backgroundColor: .system(.blue)),
            Node(name: "Restaurant",
                 showName: false,
                 image: .asset(name: "eating"),
                 value: 30.0,
                 backgroundColor: .system(.red)),
            Node(name: "Home",
                 showName: false,
                 image: .asset(name: "house"),
                 value: 75.0,
                 backgroundColor: .system(.teal))
        ])
        return RootView(configuration: configuration)
    }
}
#endif

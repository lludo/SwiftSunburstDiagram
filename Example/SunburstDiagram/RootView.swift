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
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @ObservedObject var configuration: SunburstConfiguration
    
    var body: some View {
        if horizontalSizeClass == .compact {
            return AnyView(
                VStack(spacing: 0) {
                    SunburstView(configuration: configuration)
                    Divider()
                        .edgesIgnoringSafeArea(.all)
                    SettingsView(configuration: configuration)
                }
            )
        } else {
            return AnyView(
                HStack(spacing: 0) {
                    SunburstView(configuration: configuration)
                        .edgesIgnoringSafeArea(.all)
                    Divider()
                        .edgesIgnoringSafeArea(.all)
                    SettingsView(configuration: configuration)
                }
            )
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let configuration = SunburstConfiguration(nodes: [
            Node(name: "Walking",
                 showName: false,
                 image: UIImage(named: "walking"),
                 value: 10.0,
                 backgroundColor: .systemBlue),
            Node(name: "Restaurant",
                 showName: false,
                 image: UIImage(named: "eating"),
                 value: 30.0,
                 backgroundColor: .systemRed),
            Node(name: "Home",
                 showName: false,
                 image: UIImage(named: "house"),
                 value: 75.0,
                 backgroundColor: .systemTeal)
        ])
        return RootView(configuration: configuration)
    }
}
#endif

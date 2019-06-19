//
//  RootView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/18/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI

struct RootView : View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @ObjectBinding var configuration: SunburstConfiguration
    
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
struct RootView_Previews : PreviewProvider {
    static var previews: some View {
        let configuration = SunburstConfiguration(nodes: [])
        return RootView(configuration: configuration)
    }
}
#endif

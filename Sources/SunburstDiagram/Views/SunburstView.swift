//
//  SunburstView.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI

public struct SunburstView: View {

    @ObservedObject private var sunburst: Sunburst
    
    public init(configuration: SunburstConfiguration) {
        sunburst = configuration.sunburst
    }
    
    public var body: some View {
        ZStack {
            SunburstArcGroup(arcs: sunburst.rootArcs, configuration: sunburst.configuration)
            Color.clear
        }
        .flipsForRightToLeftLayoutDirection(true)
        .padding()
        .drawingGroup()
    }
}

private struct SunburstArcGroup: View {
    let arcs: [Sunburst.Arc]
    @ObservedObject var configuration: SunburstConfiguration

    var body: some View {
        ForEach(arcs) { arc in
            ArcView(arc: arc, configuration: configuration)
                .onTapGesture { handleTap(on: arc) }
            if let childArcs = arc.childArcs {
                SunburstArcGroup(arcs: childArcs, configuration: configuration)
            }
        }
    }

    private func handleTap(on arc: Sunburst.Arc) {
        guard configuration.allowsSelection else { return }
        withAnimation(.easeInOut) {
            if configuration.selectedNode == arc.node && configuration.focusedNode == arc.node {
                configuration.focusedNode = configuration.parentForNode(arc.node)
            } else if configuration.selectedNode == arc.node {
                configuration.focusedNode = arc.node
            } else {
                configuration.selectedNode = arc.node
            }
        }
    }
}

#if DEBUG
struct SunburstView_Previews : PreviewProvider {
    static var previews: some View {
        let configuration = SunburstConfiguration(nodes: [
            Node(name: "Walking",
                 showName: false,
                 value: 10.0,
                 backgroundColor: .system(.blue)),
            Node(name: "Restaurant",
                 showName: false,
                 value: 30.0,
                 backgroundColor: .system(.red)),
            Node(name: "Home",
                 showName: false,
                 value: 75.0,
                 backgroundColor: .system(.teal))
        ])
        return SunburstView(configuration: configuration)
    }
}
#endif

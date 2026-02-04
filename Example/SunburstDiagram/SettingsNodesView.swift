//
//  SettingsNodesView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/18/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI

struct SettingsNodesView: View {
    
    var nodes: [Node]

    var body: some View {
        container
        .navigationTitle("Nodes")
    }

    @ViewBuilder
    private var container: some View {
        #if os(tvOS)
        List { listContent }
        #else
        Form { listContent }
        #endif
    }

    @ViewBuilder
    private var listContent: some View {
        if nodes.count > 0 {
            Section {
                ForEach(nodes) { node in
                    self.nodeCellFor(node)
                }
            }
        }
        Section {
            NavigationLink(destination: SettingsNewNodeView()) {
                Text("Add new node")
            }
        }
    }
    
    fileprivate func nodeCellFor(_ node: Node) -> some View {
        return NavigationLink(destination: SettingsNodesView(nodes: node.children)) {
            HStack {
                if let image = node.image {
                    image.resolve().renderingMode(.template)
                }
                Text(node.name)
                Spacer()
                Text(node.children.count == 0 ? "Leaf node" : "\(node.children.count) child nodes")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }
}

#if DEBUG
struct SettingsNodesView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsNodesView(nodes: [
            Node(name: "Walking",
                 showName: false,
                 image: .asset(name: "walking"),
                 value: 10.0,
                 backgroundColor: .system(.blue))
        ])
    }
}
#endif

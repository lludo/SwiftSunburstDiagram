//
//  SettingsNodesView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/18/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI

struct SettingsNodesView : View {
    
    var nodes: [Node]?
    
    var body: some View {
        Form {
            IfLet(nodes) { nodes in
                Section {
                    ForEach(nodes) { node in
                        self.nodeCellFor(node)
                    }
                }
            }
            Section {
                NavigationButton(destination: SettingsNewNodeView()) {
                    Text("Add new node")
                }
            }
        }
    }
    
    fileprivate func nodeCellFor(_ node: Node) -> some View {
        return NavigationButton(destination: SettingsNodesView(nodes: node.children)) {
            HStack {
                IfLet(node.image) { image in
                    Image(uiImage: image).renderingMode(.template)
                }
                Text(node.name)
                Spacer()
                Text((node.children?.count ?? 0) == 0 ? "Leaf node" : "\(node.children!.count) child nodes").color(Color.secondary)
            }
        }
    }
}

#if DEBUG
struct SettingsNodesView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsNodesView(nodes: nil)
    }
}
#endif

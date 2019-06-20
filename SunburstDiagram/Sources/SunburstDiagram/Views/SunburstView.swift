//
//  SunburstView.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI

public struct SunburstView: View {

    @ObjectBinding var sunburst: Sunburst
    
    public init(configuration: SunburstConfiguration) {
        sunburst = Sunburst(configuration: configuration)
    }
    
    public var body: some View {
        let arcs = ZStack {
            configureViews(arcs: sunburst.arcs)
            
            // Stop the window shrinking to zero when there is no arcs.
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .padding()
        
        let drawnArcs = arcs.drawingGroup()
        return drawnArcs
    }
    
    private func configureViews(arcs: [Sunburst.Arc], parentArc: Sunburst.Arc? = nil, level: UInt = 0) -> some View {
        return ForEach(arcs) { arc in
            ArcView(arc: arc, level: level, configuration: self.sunburst.configuration)
                .transition(.scaleAndFade)
                .tapAction {
                    withAnimation(.fluidSpring()) {
                        print(">>> Tapped arc: \(arc.text)")
                    }
                }
            IfLet(arc.childArcs) { childArcs in
                AnyView(self.configureViews(arcs: childArcs, parentArc: arc, level: level + 1))
            }
        }
    }
}

// MARK: - Transitions

struct ScaleAndFade: ViewModifier {
    
    // True when the transition is active.
    var isEnabled: Bool
    
    // Scale and fade the content view while transitioning in and out of the container.
    func body(content: Content) -> some View {
        return content
            .scaleEffect(isEnabled ? 0.1 : 1)
            .opacity(isEnabled ? 0 : 1)
    }
}

extension AnyTransition {
    static let scaleAndFade = AnyTransition.modifier(
        active: ScaleAndFade(isEnabled: true),
        identity: ScaleAndFade(isEnabled: false)
    )
}

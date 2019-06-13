//
//  RingView.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI

public struct RingView: View {
    
    @EnvironmentObject var ring: Ring
    
    public init() {
    }
    
    public var body: some View {
        let arcs = ZStack {
            configureViews(arcs: ring.arcs, parentArc: nil, level: 0)
            
            // Stop the window shrinking to zero when there is no arcs.
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .padding()
        
        let drawnArcs = arcs.drawingGroup()
        return drawnArcs
    }
    
    private func configureViews(arcs: [Ring.Arc], parentArc: Ring.Arc?, level: Int) -> some View {
        return ForEach(arcs) { arc in
            ArcView(arc: arc, level: level)
                .transition(.scaleAndFade)
                .tapAction {
                    withAnimation(.fluidSpring(stiffness: 20.0)) {
                        self.ring.remove(arc: arc)
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

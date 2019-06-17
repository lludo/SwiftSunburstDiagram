//
//  SunburstView.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI

public struct SunburstView: View {
    
    @EnvironmentObject var sunburst: Sunburst
    
    public static func configureWith(_ configuration: SunburstConfiguration) -> some View {
        configuration.validateAndPrepare()
        
        let sunburst = Sunburst(configuration: configuration)
//        sunburst.randomWalk = true // For testing
        
        return SunburstView().environmentObject(sunburst)
    }
    
    public var body: some View {
        let arcs = ZStack {
            configureViews(arcs: sunburst.arcs, parentArc: nil, level: 0)
            
            // Stop the window shrinking to zero when there is no arcs.
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .padding()
        
        let drawnArcs = arcs.drawingGroup()
        return drawnArcs
    }
    
    private func configureViews(arcs: [Sunburst.Arc], parentArc: Sunburst.Arc?, level: Int) -> some View {
        return ForEach(arcs) { arc in
            ArcView(arc: arc, level: level, configuration: self.sunburst.configuration)
                .transition(.scaleAndFade)
                .tapAction {
                    withAnimation(.fluidSpring()) {
                        self.sunburst.remove(arc: arc)
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

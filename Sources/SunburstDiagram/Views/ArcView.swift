//
//  ArcView.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI

// A view drawing a single colored arc with a label
struct ArcView: View {

    @ObservedObject private var configuration: SunburstConfiguration

    private let arc: Sunburst.Arc
    
    init(arc: Sunburst.Arc, configuration: SunburstConfiguration) {
        self.arc = arc
        self.configuration = configuration
    }
    
    var body: some View {
        let animation = Animation.easeInOut
        let arcShape = ArcShape(arc, configuration: configuration)

        return ZStack() {
            arcShape.fill(arc.backgroundColor).animation(animation)
            arcShape.stroke(Color.primary, lineWidth: isNodeSelected() ? 4 : 0).clipShape(arcShape).animation(animation)
            if arc.width > 0 && (configuration.maximumRingsShownCount == nil || arc.level <= configuration.maximumRingsShownCount!)
                && (configuration.maximumExpandedRingsShownCount == nil || arc.level <= configuration.maximumExpandedRingsShownCount!) {
                    ArcLabel(arc, configuration: configuration).animation(animation)
            }
        }
    }

    func isNodeSelected() -> Bool {
        return configuration.allowsSelection && arc.node == configuration.selectedNode
    }
}

// A view for the label of the arc (text + image)
struct ArcLabel: View {
    
    private var arc: Sunburst.Arc
    private var offset: CGPoint = .zero
    private let configuration: SunburstConfiguration
    
    init(_ arc: Sunburst.Arc, configuration: SunburstConfiguration) {
        self.arc = arc
        self.configuration = configuration
        
        let points = ArcGeometry(arc, configuration: configuration)
        offset = points[.center]
    }
    
    var body: some View {
        VStack() {
            IfLet(arc.node.image) { image in
                Image(uiImage: image)
            }
            if !arc.isTextHidden {
                Text(arc.node.name)
            }
        }
        .offset(x: offset.x, y: offset.y)
    }
}

// A view for the shape of the arc
struct ArcShape: Shape {
    
    private var arc: Sunburst.Arc
    private let configuration: SunburstConfiguration

    init(_ arc: Sunburst.Arc, configuration: SunburstConfiguration) {
        self.arc = arc
        self.configuration = configuration
    }
    
    func path(in rect: CGRect) -> Path {
        let points = ArcGeometry(arc, in: rect, configuration: configuration)
        
        var path = Path()
        path.addArc(center: points.center, radius: arc.innerRadius,
                    startAngle: .radians(arc.start + arc.innerMargin), endAngle: .radians(arc.end - arc.innerMargin),
                    clockwise: false)
        path.addArc(center: points.center, radius: arc.outerRadius,
                    startAngle: .radians(arc.end - arc.outerMargin), endAngle: .radians(arc.start + arc.outerMargin),
                    clockwise: true)
        path.closeSubpath()
        return path
    }

    var animatableData: Sunburst.Arc.AnimatableData {
        get { arc.animatableData }
        set { arc.animatableData = newValue }
    }
    
    static func == (lhs: ArcShape, rhs: ArcShape) -> Bool {
        return lhs.arc == rhs.arc
    }
}

// Helper type for creating view-space points within an arc.
private struct ArcGeometry {
    
    var arc: Sunburst.Arc
    var center: CGPoint
    
    init(_ arc: Sunburst.Arc, in rect: CGRect? = nil, configuration: SunburstConfiguration) {
        self.arc = arc
        
        if let rect = rect {
            center = CGPoint(x: rect.midX, y: rect.midY)
        } else {
            self.center = .zero
        }
    }
    
    // Returns the view location of the point in the arc at unit-
    // space location `unitPoint`, where the X axis of `p` moves around the
    // arc arc and the Y axis moves out from the inner to outer radius.
    subscript(unitPoint: UnitPoint) -> CGPoint {
        let radius = lerp(arc.innerRadius, arc.outerRadius, by: unitPoint.y)
        let angle = lerp(arc.start, arc.end, by: Double(unitPoint.x))
        
        return CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                       y: center.y + CGFloat(sin(angle)) * radius)
    }
}

// Linearly interpolate from `from` to `to` by the fraction `amount`.
private func lerp<T: BinaryFloatingPoint>(_ fromValue: T, _ toValue: T, by amount: T) -> T {
    return fromValue + (toValue - fromValue) * amount
}

#if DEBUG
struct ArcView_Previews : PreviewProvider {
    static var previews: some View {
        let node =  Node(name: "Walking",
                         showName: false,
                         value: 10.0,
                         backgroundColor: .systemBlue)
        let totalValue = 30.0
        let arc = Sunburst.Arc(node: node, level: 1, totalValue: totalValue)
        let configuration = SunburstConfiguration(nodes: [node],
                calculationMode: .parentIndependent(totalValue: totalValue))

        return ArcView(arc: arc, configuration: configuration)
    }
}
#endif

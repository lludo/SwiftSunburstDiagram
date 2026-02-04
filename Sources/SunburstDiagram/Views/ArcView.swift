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
    @Environment(\.colorScheme) private var colorScheme

    private let arc: Sunburst.Arc
    
    init(arc: Sunburst.Arc, configuration: SunburstConfiguration) {
        self.arc = arc
        self.configuration = configuration
    }
    
    var body: some View {
        let arcShape = ArcShape(arc)

        return ZStack {
            arcShape.fill(arc.backgroundColor.resolve(in: colorScheme))
            arcShape
                .stroke(Color.primary, lineWidth: isNodeSelected() ? 3 : 0)
                .clipShape(arcShape)
            if shouldShowLabel {
                ArcLabel(arc)
            }
        }
        .animation(.easeInOut, value: arc.animatableData)
        .contentShape(arcShape)
    }

    func isNodeSelected() -> Bool {
        return configuration.allowsSelection && arc.node == configuration.selectedNode
    }

    private var shouldShowLabel: Bool {
        guard arc.width > 0 else { return false }
        if let maxRings = configuration.maximumRingsShownCount, arc.level > maxRings {
            return false
        }
        if let maxExpanded = configuration.maximumExpandedRingsShownCount, arc.level > maxExpanded {
            return false
        }
        return true
    }
}

// A view for the label of the arc (text + image)
struct ArcLabel: View {
    
    private let arc: Sunburst.Arc
    private let offset: CGPoint
    init(_ arc: Sunburst.Arc) {
        self.arc = arc

        let points = ArcGeometry(arc)
        offset = points[.center]
    }
    
    var body: some View {
        VStack() {
            if let image = arc.node.image {
                image.resolve()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
            if !arc.isTextHidden {
                Text(arc.node.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .offset(x: offset.x, y: offset.y)
    }
}

// A view for the shape of the arc
struct ArcShape: Shape {
    
    private var arc: Sunburst.Arc
    init(_ arc: Sunburst.Arc) {
        self.arc = arc
    }
    
    func path(in rect: CGRect) -> Path {
        let points = ArcGeometry(arc, in: rect)
        
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
    
    init(_ arc: Sunburst.Arc, in rect: CGRect? = nil) {
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
                         backgroundColor: .system(.blue))
        let totalValue = 30.0
        let arc = Sunburst.Arc(node: node, level: 1, totalValue: totalValue)
        let configuration = SunburstConfiguration(nodes: [node],
                calculationMode: .parentIndependent(totalValue: totalValue))

        return ArcView(arc: arc, configuration: configuration)
    }
}
#endif

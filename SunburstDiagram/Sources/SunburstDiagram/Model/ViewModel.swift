//
//  Model.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import Combine
import SwiftUI

class Sunburst: BindableObject {

    struct Arc: Equatable, Identifiable {
        var id: ObjectIdentifier
        
        var width: Double
        var backgroundColor: Color
        var isTextHidden: Bool
        
        let text: String
        let image: UIImage?
        
        fileprivate(set) var childArcs: [Arc]?
        
        // The start location of the arc, as an angle in radians.
        fileprivate(set) var start = 0.0
        // The end location of the arc, as an angle in radians.
        fileprivate(set) var end = 0.0
        
        init(text: String, image: UIImage? = nil, width: Double, backgroundColor: UIColor, childArcs: [Arc]? = nil, isTextHidden: Bool = false) {
            self.id = ObjectIdentifier(text as NSString)
            
            self.width = width
            let ciColor = CIColor(color: backgroundColor) // All this is far from ideal :(
            self.backgroundColor = Color(red: Double(ciColor.red), green: Double(ciColor.green), blue: Double(ciColor.blue))
            self.isTextHidden = isTextHidden
            
            self.childArcs = childArcs
            
            self.image = image
            self.text = text
        }
    }
    
    private(set) var arcs: [Arc] = []
    private let configuration: SunburstConfiguration
    
    // Trivial publisher for our changes.
    let didChange = PassthroughSubject<Sunburst, Never>()
    
    init(configuration: SunburstConfiguration) {
        self.configuration = configuration
        
        self.arcs = configureArcs(nodes: configuration.nodes, totalValue: configuration.totalNodesValue)
        modelDidChange()
    }
    
    // Called after each change, updates derived model values and posts the notification.
    private func modelDidChange() {
        guard nestedUpdates == 0 else { return }
        
        // Recalculate locations, to pack within circle.
        
        var location = -.pi / 2.0
        for index in 0 ..< arcs.count {
            
            // TODO: HACK for now, need to be recursive, not just 1 more level down!
            var childLocation = location
            if let childArcs = arcs[index].childArcs {
                for childIndex in 0 ..< childArcs.count {
                    var childArc = childArcs[childIndex]
                    childArc.start = childLocation
                    childLocation += childArc.width
                    childArc.end = childLocation
                    arcs[index].childArcs![childIndex] = childArc
                }
            }
            
            arcs[index].start = location
            location += arcs[index].width
            arcs[index].end = location
        }
        
        didChange.send(self)
    }
    
    // Non-zero while a batch of updates is being processed.
    private var nestedUpdates = 0
    
    // Invokes `body()` such that any changes it makes to the model
    // will only post a single notification to observers.
    func batch(_ body: () -> Void) {
        nestedUpdates += 1
        defer {
            nestedUpdates -= 1
            if nestedUpdates == 0 {
                modelDidChange()
            }
        }
        body()
    }
    
    func add(arc: Arc) {
        arcs.append(arc)
        modelDidChange()
    }
    
    func remove(arc: Arc) {
        if let index = arcs.firstIndex(of: arc) {
            arcs.remove(at: index)
            modelDidChange()
        }
    }
    
    func reset() {
        if !arcs.isEmpty {
            arcs.removeAll()
            modelDidChange()
        }
    }
    
    // MARK: Private
    
    private func configureArcs(nodes: [Node], totalValue: Double) -> [Sunburst.Arc] {
        var arcs: [Sunburst.Arc] = []
        
        // Iterate through the nodes
        for node in nodes {
            var arc = Sunburst.Arc.configureWith(node: node, totalValue: totalValue)
            if let children = node.children {
                arc.childArcs = configureArcs(nodes: children, totalValue: totalValue)
            }
            arcs.append(arc)
        }
        return arcs
    }
}

// MARK: - Arc

extension Sunburst.Arc {
    
    static func configureWith(node: Node, totalValue: Double) -> Sunburst.Arc {
        let width = (node.computedValue / totalValue) * 2.0 * .pi
        let backgroundColor = node.backgroundColor ?? .systemGray
        
        return Sunburst.Arc(text: node.name, image: node.image, width: width, backgroundColor: backgroundColor, isTextHidden: !node.showName)
    }
}

// MARK: - Random updates for testing

extension Sunburst {
    
    private static var _randomWalk = [String : Bool]()
    private static var _timer = [String : Timer]()
    
    private var timer: Timer? {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return Sunburst._timer[tmpAddress]
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            Sunburst._timer[tmpAddress] = newValue
            updateTimer()
        }
    }
    
    // When true, periodically updates the data with random changes.
    var randomWalk: Bool {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return Sunburst._randomWalk[tmpAddress] ?? false
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            Sunburst._randomWalk[tmpAddress] = newValue
            updateTimer()
        }
    }
    
    // Randomly changes values of existing arcs.
    private func randomize() {
        withAnimation(.fluidSpring()) {
            for index in 0 ..< arcs.count {
                var arc = arcs[index]
                arc.width = .random(in: max(0.2, arc.width - 0.2) ... min(2.0 * .pi, arc.width + 0.2))
                arcs[index] = arc
            }
            modelDidChange()
        }
    }
    
    // Ensures the random-walk timer has the correct state.
    private func updateTimer() {
        if randomWalk, timer == nil {
            randomize()
            timer = Timer.scheduledTimer(
                withTimeInterval: 2, repeats: true
            ) { [weak self] _ in
                self?.randomize()
            }
        } else if !randomWalk, let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        modelDidChange()
    }
}

// MARK: - Animation

// Extend the arc description to conform to the Animatable type to
// simplify creation of custom shapes using the arc.
extension Sunburst.Arc: Animatable {
    // Use a composition of pairs to merge the interpolated values into
    // a single type. AnimatablePair acts as a single interpolatable
    // values, given two interpolatable input types. We'll interpolate
    // the derived start/end angles.
    
    public typealias AnimatableData = AnimatablePair<Double, Double>
    
    public var animatableData: AnimatableData {
        get {
            AnimatablePair(start, end)
        }
        set {
            start = newValue.first
            end = newValue.second
        }
    }
}

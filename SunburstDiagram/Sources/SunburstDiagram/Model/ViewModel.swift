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
        let id: ObjectIdentifier
        let level: UInt
        let node: Node

        var width: Double
        var backgroundColor: Color
        var isTextHidden: Bool

        fileprivate(set) var childArcs: [Arc]?
        fileprivate(set) var start = 0.0    // The start location of the arc, as an angle in radians.
        fileprivate(set) var end = 0.0      // The end location of the arc, as an angle in radians.

        fileprivate(set) var innerRadius: Length = 0.0
        fileprivate(set) var outerRadius: Length = 0.0

        fileprivate(set) var innerMargin = 0.0
        fileprivate(set) var outerMargin = 0.0

        init(node: Node, level: UInt, totalValue: Double) {
            self.id = node.id
            self.level = level
            self.node = node
            
            let ciColor = CIColor(color: node.computedBackgroundColor) // All this is far from ideal :(
            backgroundColor = Color(red: Double(ciColor.red), green: Double(ciColor.green), blue: Double(ciColor.blue))
            
            width = (node.computedValue / totalValue) * 2.0 * .pi
            isTextHidden = !node.showName
        }

        mutating func update(node: Node, totalValue: Double) {
            let ciColor = CIColor(color: node.computedBackgroundColor) // All this is far from ideal :(
            backgroundColor = Color(red: Double(ciColor.red), green: Double(ciColor.green), blue: Double(ciColor.blue))

            width = (node.computedValue / totalValue) * 2.0 * .pi
            isTextHidden = !node.showName
        }
    }

    let configuration: SunburstConfiguration

    private(set) var rootArcs: [Arc] = []
    private var arcsCache: [ObjectIdentifier : Arc] = [:]

    // Trivial publisher for our changes.
    let didChange = PassthroughSubject<Sunburst, Never>()

    init(configuration: SunburstConfiguration) {
        self.configuration = configuration

        configuration.validateAndPrepare()
        _ = configuration.didChange.sink { [weak self] (config) in
            self?.modelDidChange()
        }

        modelDidChange()
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
    
    // MARK: Private
    
    private func configureArcs(nodes: [Node], totalValue: Double, level: UInt = 0) -> [Sunburst.Arc] {
        var arcs: [Sunburst.Arc] = []
        
        // Sort the nodes if needed
        let orderedNodes: [Node]
        switch configuration.nodesSort {
        case .asc:
            orderedNodes = nodes.sorted { $0.computedValue == $1.computedValue ? ($0.value ?? 0) < ($1.value ?? 0) : $0.computedValue < $1.computedValue }
        case .desc:
            orderedNodes = nodes.sorted { $0.computedValue == $1.computedValue ? ($0.value ?? 0) > ($1.value ?? 0) : $0.computedValue > $1.computedValue }
        case .none:
            orderedNodes = nodes
        }
        
        // Iterate through the nodes
        for node in orderedNodes {

            // Get the arc from cache or create a new one
            var arc: Sunburst.Arc
            if let cachedArc = arcsCache[node.id] {
                arc = cachedArc
                arc.update(node: node, totalValue: totalValue)
            } else {
                arc = Sunburst.Arc(node: node, level: level, totalValue: totalValue)
                arcsCache[node.id] = arc
            }

            if let children = node.children {
                arc.childArcs = configureArcs(nodes: children, totalValue: totalValue, level: level + 1)
            }
            arcs.append(arc)
        }
        return arcs
    }
    
    // Called after each change, updates derived model values and posts the notification.
    private func modelDidChange() {
        guard nestedUpdates == 0 else { return }

        rootArcs = configureArcs(nodes: configuration.nodes, totalValue: configuration.totalNodesValue)

        // Recalculate locations, to pack within circle.
        let startLocation = -.pi / 2.0 + (configuration.startingAngle * .pi / 180)
        recalculateLocations(arcs: &rootArcs, startLocation: startLocation)
        
        didChange.send(self)
    }
    
    private func recalculateLocations(arcs: inout [Sunburst.Arc], startLocation location: Double) {
        var location = location
        for index in 0 ..< arcs.count {
            if arcs[index].childArcs != nil {
                recalculateLocations(arcs: &arcs[index].childArcs!, startLocation: location)
            }
            arcs[index].start = location
            location += arcs[index].width
            arcs[index].end = location

            let innerRadius = arcs[index].arcInnerRadius(configuration: configuration)
            let outerRadius = innerRadius + arcs[index].arcThickness(configuration: configuration)
            arcs[index].innerRadius = innerRadius
            arcs[index].outerRadius = outerRadius

            arcs[index].innerMargin = Double(configuration.marginBetweenArcs / 2.0) / Double(innerRadius)
            arcs[index].outerMargin = Double(configuration.marginBetweenArcs / 2.0) / Double(outerRadius)
        }
    }
}

// MARK: - Arc extensions

// Geometry
extension Sunburst.Arc {

    func arcIsExpanded(configuration: SunburstConfiguration) -> Bool {
        if let maximumExpandedRingsShownCount = configuration.maximumExpandedRingsShownCount {
            return level < maximumExpandedRingsShownCount
        } else {
            return true
        }
    }

    func arcInnerRadius(configuration: SunburstConfiguration) -> Length {
        if let maximumExpandedRingsShownCount = configuration.maximumExpandedRingsShownCount, level >= maximumExpandedRingsShownCount {
            let expandedRingsThickness = Length(maximumExpandedRingsShownCount) * (configuration.expandedArcThickness + configuration.marginBetweenArcs)
            let collapsedRingsThickness = Length(level - maximumExpandedRingsShownCount) * (configuration.collapsedArcThickness + configuration.marginBetweenArcs)
            return expandedRingsThickness + collapsedRingsThickness + configuration.innerRadius
        } else {
            return Length(level) * (configuration.expandedArcThickness + configuration.marginBetweenArcs) + configuration.innerRadius
        }
    }

    func arcThickness(configuration: SunburstConfiguration) -> Length {
        return arcIsExpanded(configuration: configuration) ? configuration.expandedArcThickness : configuration.collapsedArcThickness
    }
}

// Animations
extension Sunburst.Arc: Animatable {

    public var animatableData: AnimatablePair<
        AnimatablePair<
            AnimatablePair<Double, Double>,
            AnimatablePair<Length, Length>
        >,
        AnimatablePair<Double, Double>
    > {
        get {
            AnimatablePair(
                AnimatablePair(
                    AnimatablePair(start, end),
                    AnimatablePair(innerRadius, outerRadius)
                ),
                AnimatablePair(innerMargin, outerMargin)
            )
        }
        set {
            start = newValue.first.first.first
            end = newValue.first.first.second
            innerRadius = newValue.first.second.first
            outerRadius = newValue.first.second.second
            innerMargin = newValue.second.first
            outerMargin = newValue.second.second
        }
    }
}

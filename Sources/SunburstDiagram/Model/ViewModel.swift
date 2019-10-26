//
//  Model.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import Combine
import SwiftUI

class Sunburst: ObservableObject {

    struct Arc: Equatable, Identifiable {
        let id: UUID
        let level: UInt
        private(set) var node: Node

        var width: Double
        var backgroundColor: Color
        var isTextHidden: Bool

        fileprivate(set) var childArcs: [Arc]?
        fileprivate(set) var start = 0.0    // The start location of the arc, as an angle in radians.
        fileprivate(set) var end = 0.0      // The end location of the arc, as an angle in radians.

        fileprivate(set) var innerRadius: CGFloat = 0.0
        fileprivate(set) var outerRadius: CGFloat = 0.0

        fileprivate(set) var innerMargin = 0.0
        fileprivate(set) var outerMargin = 0.0

        init(node: Node, level: UInt, totalValue: Double) {
            self.id = node.id
            self.level = level
            self.node = node

            backgroundColor = Color(node.computedBackgroundColor)
            width = totalValue > 0 ? (node.computedValue / totalValue) * 2.0 * .pi : 0
            isTextHidden = !node.showName
        }

        mutating func update(node: Node, totalValue: Double) {
            self.node = node

            backgroundColor = Color(node.computedBackgroundColor)
            width = totalValue > 0 ? (node.computedValue / totalValue) * 2.0 * .pi : 0
            isTextHidden = !node.showName
        }
    }

    let configuration: SunburstConfiguration

    private(set) var rootArcs: [Arc] = []                   { willSet { objectWillChange.send() } }
    private var arcsCache: [UUID : Arc] = [:]               { willSet { objectWillChange.send() } }
    private var focusedLevel: UInt = 0                      { willSet { objectWillChange.send() } }

    public let objectWillChange = ObservableObjectPublisher()

    private var cancellable: AnyCancellable?

    init(configuration: SunburstConfiguration) {
        self.configuration = configuration

        updateFromConfiguration()
        cancellable = configuration.objectWillChange.sink { [weak self] (config) in
            DispatchQueue.main.async() {
                self?.updateFromConfiguration()
            }
        }
    }

    deinit {
        cancellable?.cancel()
    }

    // MARK: Private
    
    private func configureArcs(nodes: [Node], totalValue: Double, level: UInt = 1,
                               focusedNode: Node? = nil, foundFocusedNode: Bool = false) -> [Sunburst.Arc] {
        var arcs: [Sunburst.Arc] = []

        let shouldUseTotalValue = (focusedNode != nil) == foundFocusedNode

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

            // Look for levels depending on focused nodes
            var foundFocusedNode = foundFocusedNode
            var totalValueForDisplay = shouldUseTotalValue ? totalValue : 0
            if let focusedNode = focusedNode, foundFocusedNode == false, node == focusedNode {
                foundFocusedNode = true
                totalValueForDisplay = node.computedValue
                focusedLevel = level
            }

            // Get the arc from cache or create a new one
            var arc: Sunburst.Arc
            if let cachedArc = arcsCache[node.id] {
                arc = cachedArc
                arc.update(node: node, totalValue: totalValueForDisplay)
            } else {
                arc = Sunburst.Arc(node: node, level: level, totalValue: totalValueForDisplay)
                arcsCache[node.id] = arc
            }

            if node.children.count > 0 {
                arc.childArcs = configureArcs(nodes: node.children, totalValue: totalValueForDisplay, level: level + 1,
                                              focusedNode: focusedNode, foundFocusedNode: foundFocusedNode)
            }
            arcs.append(arc)
        }
        return arcs
    }
    
    // Called after each change, updates derived model values and posts the notification.
    private func updateFromConfiguration() {
        focusedLevel = 0
        if let focusedNode = configuration.focusedNode, configuration.allowsSelection {
            rootArcs = configureArcs(nodes: configuration.nodes, totalValue: configuration.totalNodesValue, focusedNode: focusedNode)
        } else {
            rootArcs = configureArcs(nodes: configuration.nodes, totalValue: configuration.totalNodesValue)
        }

        // Recalculate locations, to pack within circle.
        let startLocation = -.pi / 2.0 + (configuration.startingAngle * .pi / 180)
        recalculateLocations(arcs: &rootArcs, startLocation: startLocation)
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

            let innerRadius = arcs[index].arcInnerRadius(configuration: configuration, focusedLevel: focusedLevel)
            let outerRadius = innerRadius + arcs[index].arcThickness(configuration: configuration, focusedLevel: focusedLevel)
            arcs[index].innerRadius = innerRadius
            arcs[index].outerRadius = outerRadius

            if focusedLevel < arcs[index].level {
                let innerMargin = Double(configuration.marginBetweenArcs / 2.0) / Double(innerRadius)
                let outerMargin = Double(configuration.marginBetweenArcs / 2.0) / Double(outerRadius)
                arcs[index].innerMargin = min(max(0.0, arcs[index].width / 2.0 - Double.ulpOfOne), innerMargin)
                arcs[index].outerMargin = min(max(0.0, arcs[index].width / 2.0 - Double.ulpOfOne), outerMargin)
            } else {
                arcs[index].innerMargin = 0.0
                arcs[index].outerMargin = 0.0
            }
        }
    }
}

// MARK: - Arc extensions

// Geometry
extension Sunburst.Arc {

    func arcIsExpanded(configuration: SunburstConfiguration, focusedLevel: UInt) -> Bool {
        guard focusedLevel < level else {
            return true
        }

        if let maximumExpandedRingsShownCount = configuration.maximumExpandedRingsShownCount {
            let displayedLevel = level - focusedLevel - 1
            return displayedLevel < maximumExpandedRingsShownCount
        } else {
            return true
        }
    }

    func arcInnerRadius(configuration: SunburstConfiguration, focusedLevel: UInt) -> CGFloat {
        guard focusedLevel < level else {
            return 0.0
        }

        var displayedLevel = level - focusedLevel - 1
        if let maximumRingsShownCount = configuration.maximumRingsShownCount, displayedLevel >= maximumRingsShownCount {
            displayedLevel = maximumRingsShownCount
        }
        if let maximumExpandedRingsShownCount = configuration.maximumExpandedRingsShownCount, displayedLevel >= maximumExpandedRingsShownCount {
            let expandedRingsThickness = CGFloat(maximumExpandedRingsShownCount) * (configuration.expandedArcThickness + configuration.marginBetweenArcs)
            let collapsedRingsThickness = CGFloat(displayedLevel - maximumExpandedRingsShownCount) * (configuration.collapsedArcThickness + configuration.marginBetweenArcs)
            return expandedRingsThickness + collapsedRingsThickness + configuration.innerRadius
        } else {
            return CGFloat(displayedLevel) * (configuration.expandedArcThickness + configuration.marginBetweenArcs) + configuration.innerRadius
        }
    }

    func arcThickness(configuration: SunburstConfiguration, focusedLevel: UInt) -> CGFloat {
        guard focusedLevel < level else {
            return configuration.innerRadius - configuration.marginBetweenArcs
        }

        let displayedLevel = level - focusedLevel - 1
        if let maximumRingsShownCount = configuration.maximumRingsShownCount, displayedLevel >= maximumRingsShownCount {
            return 0.0
        } else {
            return arcIsExpanded(configuration: configuration, focusedLevel: focusedLevel) ? configuration.expandedArcThickness : configuration.collapsedArcThickness
        }
    }
}

// Animations
extension Sunburst.Arc: Animatable {

    public var animatableData: AnimatablePair<
        AnimatablePair<
            AnimatablePair<Double, Double>,
            AnimatablePair<CGFloat, CGFloat>
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

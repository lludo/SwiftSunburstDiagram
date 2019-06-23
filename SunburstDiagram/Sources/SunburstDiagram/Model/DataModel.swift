//
//  Model.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/13/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import UIKit

// TODO: Callbacks & functions:
// - Did select node - only support single selection
// - Select/Deselect node
// - Drill down to node
// - Drill up / drill up to root

/// The `SunburstConfiguration` is the main configuration class used to create the `SunburstView`
public class SunburstConfiguration: BindableObject {
    public var nodes: [Node] = []                                   { didSet { modelDidChange() } }
    public var calculationMode: CalculationMode = .ordinalFromRoot  { didSet { modelDidChange() } }
    public var nodesSort: NodesSort = .none                         { didSet { modelDidChange() } }
    
    public var marginBetweenArcs: CGFloat = 1.0                     { didSet { modelDidChange() } }
    public var collapsedArcThickness: CGFloat = 8.0                 { didSet { modelDidChange() } }
    public var expandedArcThickness: CGFloat = 60.0                 { didSet { modelDidChange() } }
    public var innerRadius: CGFloat = 60.0                          { didSet { modelDidChange() } }

    /// Angle in degrees, start at the top and rotate clockwise
    public var startingAngle: Double = 0.0                          { didSet { modelDidChange() } }
    public var minimumArcAngleShown: ArcMinimumAngle = .showAll     { didSet { modelDidChange() } }
    
    public var maximumRingsShownCount: UInt? = nil                  { didSet { modelDidChange() } }
    /// Rings passed this will be shown collapsed (to show more rings with less data)
    public var maximumExpandedRingsShownCount: UInt? = nil          { didSet { modelDidChange() } }

    // MARK: Interactions

//    public var allowsSelection: Bool = true                         { didSet { modelDidChange() } }

    public var selectedNode: Node?                                  { didSet { modelDidChange() } }
    public var focusedNode: Node?                                   { didSet { modelDidChange() } }

    public let didChange = PassthroughSubject<SunburstConfiguration, Never>()

    lazy var sunburst: Sunburst = {
        return Sunburst(configuration: self)
    }()

    public init(nodes: [Node], calculationMode: CalculationMode = .ordinalFromRoot, nodesSort: NodesSort = .none) {
        self.nodes = nodes
        self.calculationMode = calculationMode
        self.nodesSort = nodesSort
    }

    // MARK: - Private

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

    // Called after each change, updates derived model values and posts the notification.
    private func modelDidChange() {
        guard nestedUpdates == 0 else { return }

        validateAndPrepare()
        didChange.send(self)
    }
}

/// The `Node` class holds the data shown in the diagram
public class Node: Identifiable, Equatable {

    public let name: String
    public var children: [Node]? = nil
    public var value: Double? = nil
    
    public var showName: Bool = true
    public var image: UIImage? = nil
    public var backgroundColor: UIColor? = nil

    // Internal values
    var computedValue: Double = 0.0
    var computedBackgroundColor: UIColor = .systemGray

    public init(name: String, showName: Bool = true, image: UIImage? = nil,
                value: Double? = nil, backgroundColor: UIColor? = nil, children: [Node]? = nil) {
        self.name = name
        self.showName = showName
        self.image = image
        self.value = value
        self.backgroundColor = backgroundColor
        self.children = children
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum CalculationMode: Hashable {
    /// Default, values are not used. Divide the circle into equal parts from root. Child elements also divide their parents into equal parts.
    case ordinalFromRoot
    /// Values are not used. Elements at the last level (leaves), divide the circle into equal parts, the size of each parent depends on the number of its children.
    case ordinalFromLeaves
    /// The sizes of nodes depend on their values, so the value data field is required. The value of a parent node can exceed the sum of its child nodes values (when omitted or incomplete data).
    case parentDependent(totalValue: Double? = nil)
    /// This mode requires the value at the last level (leaves)
    case parentIndependent(totalValue: Double? = nil)
}

public enum NodesSort: Hashable {
    /// Default. Will preserve the provided order.
    case none
    /// Smaller node values first.
    case asc
    /// Larger node values first.
    case desc
}

public enum ArcMinimumAngle: Hashable {
    /// Default. Will show all arcs
    case showAll
    /// Group sibling arcs toguether if their angle is less than the desired value in degree
    case group(ifLessThan: Double)
    /// Hide arcs if their angle is less than the desired value in degree
    case hide(ifLessThan: Double)
}

// MARK: - Extensions

extension SunburstConfiguration {
    
    func validateAndPrepare() {
        validateAndPrepareValues()
        validateAndPrepareColors(nodes: nodes)
        
        // TODO: implement minimumArc size
    }
    
    var totalNodesValue: Double {
        let totalNodesValue: Double
        if case .parentDependent(let totalValue) = calculationMode, let value = totalValue {
            totalNodesValue = value
        } else if case .parentIndependent(let totalValue) = calculationMode, let value = totalValue {
            totalNodesValue = value
        } else {
            totalNodesValue = totalComputedValue(nodes: nodes)
        }
        return totalNodesValue
    }
    
    // MARK: Private
    
    private func totalLeavesCount(nodes: [Node]) -> UInt {
        var nodesLeavesCount: UInt = 0
        for node in nodes {
            if let children = node.children {
                nodesLeavesCount += totalLeavesCount(nodes: children)
            } else {
                nodesLeavesCount += 1
            }
        }
        return nodesLeavesCount
    }
    
    private func totalComputedValue(nodes: [Node]) -> Double {
        return nodes.reduce(0.0) { $0 + $1.computedValue }
    }
    
    private func validateAndPrepareColors(nodes: [Node]) {
        for node in nodes {
            if let backgroundColor = node.backgroundColor {
                node.computedBackgroundColor = backgroundColor
            }
            if let children = node.children {
                validateAndPrepareColors(nodes: children)
            }
        }
        
        // TODO: implement compute Colors if no color provided
    }
    
    private func validateAndPrepareValues() {
        switch calculationMode {
        case .ordinalFromRoot:
            prepareNodeComputedValuesForModeOrdinalFromRoot(nodes: nodes)
        case .ordinalFromLeaves:
            _ = prepareNodeComputedValuesForModeOrdinalFromLeaves(nodes: nodes)
        case .parentDependent(let totalValue):
            guard validateAllNodesHaveValue(nodes: nodes) else {
                fatalError("The sunburst nodes are invalid for this configuration. With the .parentDependent CalculationMode every node require a value!")
            }
            // TODO: Validate that the chidren nodes sum is not bigger than the parent node value
            prepareNodeComputedValuesForModeParentDependent(nodes: nodes)
            guard validateTotalValue(nodes: nodes, totalValue: totalValue) else {
                fatalError("The sunburst nodes, or the total value provided with the .parentDependent CalculationMode is invalid. The total value cannot be less than the sum of the nodes.")
            }
        case .parentIndependent(let totalValue):
            guard validateLeafNodesHaveValue(nodes: nodes) else {
                fatalError("The sunburst nodes are invalid for this configuration. With the .parentIndependent CalculationMode all leaves require a value!")
            }
            _ = prepareNodeComputedValuesForModeParentIndependent(nodes: nodes)
            guard validateTotalValue(nodes: nodes, totalValue: totalValue) else {
                fatalError("The sunburst nodes, or the total value provided with the .parentIndependent CalculationMode is invalid. The total value cannot be less than the sum of the nodes.")
            }
        }
    }
    
    // MARK: Private validate computed value
    
    private func validateAllNodesHaveValue(nodes: [Node]) -> Bool {
        for node in nodes {
            if node.value == nil {
                return false
            }
            if let children = node.children {
                let isValidChildren = validateLeafNodesHaveValue(nodes: children)
                if !isValidChildren {
                    return false
                }
            }
        }
        return true
    }
    
    private func validateLeafNodesHaveValue(nodes: [Node]) -> Bool {
        for node in nodes {
            if let children = node.children {
                let isValidChildren = validateLeafNodesHaveValue(nodes: children)
                if !isValidChildren {
                    return false
                }
            } else {
                if node.value == nil {
                    return false
                }
            }
        }
        return true
    }
    
    private func validateTotalValue(nodes: [Node], totalValue: Double?) -> Bool {
        if let totalValue = totalValue {
            return totalComputedValue(nodes: nodes) <= totalValue
        } else {
            return true
        }
    }
    
    // MARK: Private prepare computed value
    
    private func prepareNodeComputedValuesForModeOrdinalFromRoot(nodes: [Node], totalValue: Double = 100.0) {
        let nodeValue = totalValue / Double(nodes.count)
        for node in nodes {
            node.computedValue = nodeValue
            if let children = node.children {
                prepareNodeComputedValuesForModeOrdinalFromRoot(nodes: children, totalValue: nodeValue)
            }
        }
    }
    
    private func prepareNodeComputedValuesForModeOrdinalFromLeaves(nodes: [Node], leavesValue: Double? = nil) -> Double {
        let leavesValue = leavesValue ?? (100.0 / Double(totalLeavesCount(nodes: nodes)))
        
        var nodesTotalComputedValue = 0.0
        for node in nodes {
            let nodeComputedValue: Double
            if let children = node.children {
                nodeComputedValue = prepareNodeComputedValuesForModeOrdinalFromLeaves(nodes: children, leavesValue: leavesValue)
            } else {
                nodeComputedValue = leavesValue
            }
            node.computedValue = nodeComputedValue
            nodesTotalComputedValue += nodeComputedValue
        }
        return nodesTotalComputedValue
    }
    
    private func prepareNodeComputedValuesForModeParentDependent(nodes: [Node]) {
        for node in nodes {
            guard let nodeValue = node.value  else {
                fatalError("The sunburst node:\(node) is invalid for this configuration. With the .parentDependent CalculationMode every node require a value!")
            }
            node.computedValue = nodeValue
            if let children = node.children {
                prepareNodeComputedValuesForModeParentDependent(nodes: children)
            }
        }
    }
    
    private func prepareNodeComputedValuesForModeParentIndependent(nodes: [Node]) -> Double {
        var nodesTotalComputedValue = 0.0
        for node in nodes {
            let nodeComputedValue: Double
            if let children = node.children {
                nodeComputedValue = prepareNodeComputedValuesForModeParentIndependent(nodes: children)
            } else {
                guard let nodeValue = node.value  else {
                    fatalError("The sunburst node:\(node) is invalid for this configuration. With the .parentIndependent CalculationMode all leaves require a value!")
                }
                nodeComputedValue = nodeValue
            }
            node.computedValue = nodeComputedValue
            nodesTotalComputedValue += nodeComputedValue
        }
        return nodesTotalComputedValue
    }
}

extension Node: CustomStringConvertible {
    
    public var description: String {
        return "<Node: name:\(name), value:\(String(describing: value)), [computedValue:\(String(describing: computedValue))]>"
    }
}

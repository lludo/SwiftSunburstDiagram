//
//  Model.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/13/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import Foundation
import UIKit

/// The `SunburstConfiguration` is the main configuration class used to create the `SunburstView`
public class SunburstConfiguration {
    public var nodes: [Node] = []
    public var calculationMode: CalculationMode = .ordinalFromRoot
    public var nodesSort: NodesSort = .none
    
    public var marginBetweenArcs: CGFloat = 1.0
    public var collapsedArcThickness: CGFloat = 10.0
    public var expandedArcThickness: CGFloat = 60.0
    public var innerRadius: CGFloat = 60.0
    
    public var startingAngle: CGFloat = 0.0 // In degrees clockwise, default is 0 which means top
    public var minimumArcAngleShown: ArcMinimumAngle = .showAll
    
    public var maximumRingsShownCount: UInt? = nil
    public var maximumExpandedRingsShownCount: UInt? = nil // Rings passed this will be shown collapsed (to show more rings with less data)
    
    public init(nodes: [Node], calculationMode: CalculationMode = .ordinalFromRoot, nodesSort: NodesSort = .none) {
        self.nodes = nodes
        self.calculationMode = calculationMode
        self.nodesSort = nodesSort
    }
}

/// The `Node` class holds the data shown in the diagram
public class Node {
    public let name: String
    public var children: [Node]? = nil
    public var value: Double? = nil
    
    public var showName: Bool = true
    public var image: UIImage? = nil
    public var backgroundColor: UIColor? = nil
    
    public init(name: String, showName: Bool = true, image: UIImage? = nil,
                value: Double? = nil, backgroundColor: UIColor? = nil, children: [Node]? = nil) {
        self.name = name
        self.showName = showName
        self.image = image
        self.value = value
        self.backgroundColor = backgroundColor
        self.children = children
    }
    
    // MARK: - Internal
    
    var computedValue: Double?
    var computedBackgroundColor: UIColor?
}

public enum CalculationMode {
    /// Default, values are not used. Divide the circle into equal parts from root. Child elements also divide their parents into equal parts.
    case ordinalFromRoot
    /// Values are not used. Elements at the last level (leaves), divide the circle into equal parts, the size of each parent depends on the number of its children.
    case ordinalFromLeaves
    /// The sizes of nodes depend on their values, so the value data field is required. The value of a parent node can exceed the sum of its child nodes values (when omitted or incomplete data).
    case parentDependent
    /// This mode requires the value at the last level (leaves)
    case parentIndependent(totalValue: Double?)
}

public enum NodesSort {
    /// Default. Will preserve the provided order.
    case none
    /// Smaller node values first.
    case asc
    /// Larger node values first.
    case desc
}

public enum ArcMinimumAngle {
    /// Default. Will show all arcs
    case showAll
    /// Group sibling arcs toguether if their angle is less than the desired value in degree
    case group(ifLessThan: CGFloat)
    /// Hide arcs if their angle is less than the desired value in degree
    case hide(ifLessThan: CGFloat)
}

// MARK: - Notes === Sunburst diagram: ring chart, sunburst chart, multilevel pie chart ===

// TODO: Callbacks & functions:
// - Did select node - only support single selection
// - Select/Deselect node
// - Drill down to node
// - Drill up / drill up to root

// MARK: - Extensions

extension SunburstConfiguration {
    
    func validateAndPrepare() {
        guard validateAndPrepareValues() else {
             fatalError("This SunburstConfiguration configuration is invalid, check the calculationMode used and node value(s) provided.")
        }
        
        // TODO: implement compute Colors if not provided
        // TODO: implement minimumArc
    }
    
    // MARK: Private
    
    private func validateAndPrepareValues() -> Bool {
        var isValidConfiguration = true
        
        switch calculationMode {
        case .ordinalFromRoot:
            prepareNodeComputedValuesForModeOrdinalFromRoot()
        case .ordinalFromLeaves:
            prepareNodeComputedValuesForModeOrdinalFromLeaves()
        case .parentDependent:
            isValidConfiguration = validateAllNodesHaveValue(nodes: nodes)
            prepareNodeComputedValuesForModeParentDependent(nodes: nodes)
        case .parentIndependent(let value):
            isValidConfiguration = validateLeafNodesHaveValue(nodes: nodes)
            prepareNodeComputedValuesForModeParentIndependent(parentTotalValue: value)
        }
        
        return isValidConfiguration
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
    
    // MARK: Private prepare computed value
    
    private func prepareNodeComputedValuesForModeOrdinalFromRoot() {
        
        // TODO: implement
    }
    
    private func prepareNodeComputedValuesForModeOrdinalFromLeaves() {
        
        // TODO: implement
    }
    
    private func prepareNodeComputedValuesForModeParentDependent(nodes: [Node]) {
        for node in nodes {
            node.computedValue = node.value
            if let children = node.children {
                prepareNodeComputedValuesForModeParentDependent(nodes: children)
            }
        }
    }
    
    private func prepareNodeComputedValuesForModeParentIndependent(parentTotalValue: Double?) {
        
        // TODO: implement copy from childs and add to parents
    }
}

extension Node: CustomStringConvertible {
    
    public var description: String {
        return "<Node: name:\(name), value:\(String(describing: value)), [computedValue:\(String(describing: computedValue))]>"
    }
}

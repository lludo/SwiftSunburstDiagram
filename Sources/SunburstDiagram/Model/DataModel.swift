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

// TODO: Callbacks & functions:
// - Did select node - only support single selection
// - Select/Deselect node
// - Drill down to node
// - Drill up / drill up to root

/// The `SunburstConfiguration` is the main configuration class used to create the `SunburstView`.
@MainActor
public final class SunburstConfiguration: ObservableObject {
    @Published public var nodes: [Node] = [] {
        didSet { validateAndPrepare() }
    }
    @Published public var calculationMode: CalculationMode = .ordinalFromRoot {
        didSet { validateAndPrepare() }
    }
    @Published public var nodesSort: NodesSort = .none
    
    @Published public var marginBetweenArcs: CGFloat = 1.0
    @Published public var collapsedArcThickness: CGFloat = 8.0
    @Published public var expandedArcThickness: CGFloat = 60.0
    @Published public var innerRadius: CGFloat = 60.0

    /// Angle in degrees, start at the top and rotate clockwise
    @Published public var startingAngle: Double = 0.0
    @Published public var minimumArcAngleShown: ArcMinimumAngle = .showAll
    
    @Published public var maximumRingsShownCount: UInt? = nil
    /// Rings passed this will be shown collapsed (to show more rings with less data)
    @Published public var maximumExpandedRingsShownCount: UInt? = nil

    // MARK: Interactions

    @Published public var allowsSelection: Bool = true {
        didSet {
            if allowsSelection == false {
                selectedNode = nil
                focusedNode = nil
            }
        }
    }

    @Published public var selectedNode: Node?
    @Published public var focusedNode: Node?
    @Published public private(set) var validationIssues: [ValidationIssue] = []
    public var validationIssue: ValidationIssue? {
        validationIssues.first
    }

    private var isValidating = false

    lazy var sunburst: Sunburst = {
        return Sunburst(configuration: self)
    }()

    public init(nodes: [Node], calculationMode: CalculationMode = .ordinalFromRoot, nodesSort: NodesSort = .none) {
        self.nodes = nodes
        self.calculationMode = calculationMode
        self.nodesSort = nodesSort

        validateAndPrepare()
    }
}

/// The `Node` class holds the data shown in the diagram
public struct Node: Identifiable, Equatable, Sendable {
    public let id: UUID

    public let name: String
    public var children: [Node]
    public var value: Double? = nil
    
    public var showName: Bool = true
    public var image: ImageRef? = nil
    public var backgroundColor: ColorRef? = nil

    // Internal values
    var computedValue: Double = 0.0
    var computedBackgroundColor: ColorRef = .defaultBackground

    public init(id: UUID = UUID(),
                name: String,
                showName: Bool = true,
                image: ImageRef? = nil,
                value: Double? = nil, backgroundColor: ColorRef? = nil, children: [Node] = []) {
        self.id = id
        self.name = name
        self.showName = showName
        self.image = image
        self.value = value
        self.backgroundColor = backgroundColor
        self.children = children
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.id == rhs.id
    }
}

public enum CalculationMode: Hashable, Sendable {
    /// Default, values are not used. Divide the circle into equal parts from root. Child elements also divide their parents into equal parts.
    case ordinalFromRoot
    /// Values are not used. Elements at the last level (leaves), divide the circle into equal parts, the size of each parent depends on the number of its children.
    case ordinalFromLeaves
    /// The sizes of nodes depend on their values, so the value data field is required. The value of a parent node can exceed the sum of its child nodes values (when omitted or incomplete data).
    case parentDependent(totalValue: Double? = nil)
    /// This mode requires the value at the last level (leaves)
    case parentIndependent(totalValue: Double? = nil)
}

public enum NodesSort: Hashable, Sendable {
    /// Default. Will preserve the provided order.
    case none
    /// Smaller node values first.
    case asc
    /// Larger node values first.
    case desc
}

public enum ArcMinimumAngle: Hashable, Sendable {
    /// Default. Will show all arcs
    case showAll
    /// Group sibling arcs together if their angle is less than the desired value in degree
    case group(ifLessThan: Double)
    /// Hide arcs if their angle is less than the desired value in degree
    case hide(ifLessThan: Double)
}

public enum ValidationIssue: Hashable, Sendable {
    case missingNodeValue(mode: CalculationMode, nodeID: UUID)
    case parentValueLessThanChildren(nodeID: UUID, parentValue: Double, childrenSum: Double)
    case totalValueTooSmall(mode: CalculationMode, provided: Double, requiredMinimum: Double)
}

// MARK: - Extensions

extension SunburstConfiguration {
    
    func validateAndPrepare() {
        guard !isValidating else { return }
        isValidating = true
        defer { isValidating = false }
        validationIssues = []

        validateAndPrepareValues()
        validateAndPrepareColors(nodes: &nodes)
        cleanupSelections()
        
        // TODO: implement minimum arc size
    }
    
    var totalNodesValue: Double {
        let computedTotal = totalComputedValue(nodes: nodes)
        if case .parentDependent(let totalValue) = calculationMode, let providedValue = totalValue {
            return max(providedValue, computedTotal)
        } else if case .parentIndependent(let totalValue) = calculationMode, let providedValue = totalValue {
            return max(providedValue, computedTotal)
        } else {
            return computedTotal
        }
    }
    
    // MARK: Private
    
    private func totalLeavesCount(nodes: [Node]) -> UInt {
        var nodesLeavesCount: UInt = 0
        for node in nodes {
            if node.children.count > 0 {
                nodesLeavesCount += totalLeavesCount(nodes: node.children)
            } else {
                nodesLeavesCount += 1
            }
        }
        return nodesLeavesCount
    }
    
    private func totalComputedValue(nodes: [Node]) -> Double {
        return nodes.reduce(0.0) { $0 + $1.computedValue }
    }
    
    private func validateAndPrepareColors(nodes: inout [Node]) {
        for nodeIndex in 0..<nodes.count {
            nodes[nodeIndex].computedBackgroundColor = nodes[nodeIndex].backgroundColor ?? .defaultBackground
            if nodes[nodeIndex].children.count > 0 {
                validateAndPrepareColors(nodes: &nodes[nodeIndex].children)
            }
        }
    }
    
    private func validateAndPrepareValues() {
        switch calculationMode {
        case .ordinalFromRoot:
            prepareNodeComputedValuesForModeOrdinalFromRoot(nodes: &nodes)
        case .ordinalFromLeaves:
            _ = prepareNodeComputedValuesForModeOrdinalFromLeaves(nodes: &nodes)
        case .parentDependent(let totalValue):
            let mode = CalculationMode.parentDependent(totalValue: totalValue)
            _ = prepareNodeComputedValuesForModeParentDependent(nodes: &nodes, mode: mode)
            validateTotalValue(mode: mode, nodes: nodes, totalValue: totalValue)
        case .parentIndependent(let totalValue):
            let mode = CalculationMode.parentIndependent(totalValue: totalValue)
            _ = prepareNodeComputedValuesForModeParentIndependent(nodes: &nodes, mode: mode)
            validateTotalValue(mode: mode, nodes: nodes, totalValue: totalValue)
        }
    }

    private func validateTotalValue(mode: CalculationMode, nodes: [Node], totalValue: Double?) {
        guard let totalValue else { return }
        let requiredMinimum = totalComputedValue(nodes: nodes)
        guard requiredMinimum > totalValue else { return }
        appendValidationIssue(.totalValueTooSmall(mode: mode, provided: totalValue, requiredMinimum: requiredMinimum))
    }

    private func appendValidationIssue(_ issue: ValidationIssue) {
        if !validationIssues.contains(issue) {
            validationIssues.append(issue)
        }
    }
    
    // MARK: Private prepare computed value
    
    private func prepareNodeComputedValuesForModeOrdinalFromRoot(nodes: inout [Node], totalValue: Double = 100.0) {
        guard !nodes.isEmpty else { return }
        let nodeValue = totalValue / Double(nodes.count)
        for nodeIndex in 0..<nodes.count {
            nodes[nodeIndex].computedValue = nodeValue
            if nodes[nodeIndex].children.count > 0 {
                prepareNodeComputedValuesForModeOrdinalFromRoot(nodes: &nodes[nodeIndex].children, totalValue: nodeValue)
            }
        }
    }
    
    private func prepareNodeComputedValuesForModeOrdinalFromLeaves(nodes: inout [Node], leavesValue: Double? = nil) -> Double {
        guard !nodes.isEmpty else { return 0.0 }
        let leavesCount = totalLeavesCount(nodes: nodes)
        guard leavesCount > 0 else { return 0.0 }
        let leavesValue = leavesValue ?? (100.0 / Double(leavesCount))
        
        var nodesTotalComputedValue = 0.0
        for nodeIndex in 0..<nodes.count {
            let nodeComputedValue: Double
            if nodes[nodeIndex].children.count > 0 {
                nodeComputedValue = prepareNodeComputedValuesForModeOrdinalFromLeaves(nodes: &nodes[nodeIndex].children, leavesValue: leavesValue)
            } else {
                nodeComputedValue = leavesValue
            }
            nodes[nodeIndex].computedValue = nodeComputedValue
            nodesTotalComputedValue += nodeComputedValue
        }
        return nodesTotalComputedValue
    }
    
    @discardableResult
    private func prepareNodeComputedValuesForModeParentDependent(nodes: inout [Node], mode: CalculationMode) -> Double {
        var nodesTotalComputedValue = 0.0
        for nodeIndex in 0..<nodes.count {
            let childrenSum: Double
            if nodes[nodeIndex].children.count > 0 {
                childrenSum = prepareNodeComputedValuesForModeParentDependent(nodes: &nodes[nodeIndex].children, mode: mode)
            } else {
                childrenSum = 0.0
            }

            let parentValue = nodes[nodeIndex].value
            if parentValue == nil {
                appendValidationIssue(.missingNodeValue(mode: mode, nodeID: nodes[nodeIndex].id))
            }
            let resolvedParentValue = parentValue ?? childrenSum
            if resolvedParentValue < childrenSum {
                appendValidationIssue(.parentValueLessThanChildren(nodeID: nodes[nodeIndex].id,
                                                                   parentValue: resolvedParentValue,
                                                                   childrenSum: childrenSum))
            }
            let nodeComputedValue = max(resolvedParentValue, childrenSum)
            nodes[nodeIndex].computedValue = nodeComputedValue
            nodesTotalComputedValue += nodeComputedValue
        }
        return nodesTotalComputedValue
    }
    
    private func prepareNodeComputedValuesForModeParentIndependent(nodes: inout [Node], mode: CalculationMode) -> Double {
        var nodesTotalComputedValue = 0.0
        for nodeIndex in 0..<nodes.count {
            let nodeComputedValue: Double
            if nodes[nodeIndex].children.count > 0 {
                nodeComputedValue = prepareNodeComputedValuesForModeParentIndependent(nodes: &nodes[nodeIndex].children, mode: mode)
            } else {
                guard let nodeValue = nodes[nodeIndex].value else {
                    appendValidationIssue(.missingNodeValue(mode: mode, nodeID: nodes[nodeIndex].id))
                    nodeComputedValue = 0.0
                    nodes[nodeIndex].computedValue = nodeComputedValue
                    nodesTotalComputedValue += nodeComputedValue
                    continue
                }
                nodeComputedValue = nodeValue
            }
            nodes[nodeIndex].computedValue = nodeComputedValue
            nodesTotalComputedValue += nodeComputedValue
        }
        return nodesTotalComputedValue
    }

    // MARK: Utilities

    func parentForNode(_ node: Node) -> Node? {
        return parentNodeFor(node: node, inNodes: nodes, withParent: nil)
    }

    private func parentNodeFor(node nodeToFind: Node, inNodes nodes: [Node], withParent parentNode: Node?) -> Node? {
        for node in nodes {
            if nodeToFind == node {
                return parentNode
            }
            if node.children.count > 0, let foundParent = parentNodeFor(node: nodeToFind, inNodes: node.children, withParent: node) {
                return foundParent
            }
        }
        return nil
    }

    private func cleanupSelections() {
        if let selectedNode, !containsNode(selectedNode) {
            self.selectedNode = nil
        }
        if let focusedNode, !containsNode(focusedNode) {
            self.focusedNode = nil
        }
    }

    private func containsNode(_ node: Node) -> Bool {
        containsNode(id: node.id, in: nodes)
    }

    private func containsNode(id: UUID, in nodes: [Node]) -> Bool {
        for node in nodes {
            if node.id == id { return true }
            if node.children.count > 0, containsNode(id: id, in: node.children) {
                return true
            }
        }
        return false
    }
}

extension Node: CustomStringConvertible {
    
    public var description: String {
        return "<Node: name:\(name), value:\(String(describing: value)), [computedValue:\(String(describing: computedValue))]>"
    }
}

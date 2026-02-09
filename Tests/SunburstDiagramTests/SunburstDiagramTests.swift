import XCTest
@testable import SunburstDiagram

final class SunburstDiagramTests: XCTestCase {
    
    @MainActor
    func testSunburstArcHasTextHidden() {
        let node = Node(name: "Node", showName: true)
        let arc = Sunburst.Arc(node: node, level: 0, totalValue: .pi)
        XCTAssertEqual(arc.isTextHidden, !node.showName)
    }

    @MainActor
    func testOrdinalFromRootComputedValues() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1"),
                Node(name: "A2"),
            ]),
            Node(name: "B")
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .ordinalFromRoot)

        XCTAssertEqual(configuration.nodes[0].computedValue, 50.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[1].computedValue, 50.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[0].children[0].computedValue, 25.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[0].children[1].computedValue, 25.0, accuracy: 0.0001)
    }

    @MainActor
    func testOrdinalFromLeavesComputedValues() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1"),
                Node(name: "A2"),
            ]),
            Node(name: "B")
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .ordinalFromLeaves)

        let leafValue = 100.0 / 3.0
        XCTAssertEqual(configuration.nodes[0].children[0].computedValue, leafValue, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[0].children[1].computedValue, leafValue, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[1].computedValue, leafValue, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[0].computedValue, leafValue * 2.0, accuracy: 0.0001)
    }

    @MainActor
    func testParentDependentUsesNodeValues() {
        let nodes = [
            Node(name: "A", value: 40.0, children: [
                Node(name: "A1", value: 10.0),
            ]),
            Node(name: "B", value: 60.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))

        XCTAssertEqual(configuration.nodes[0].computedValue, 40.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[0].children[0].computedValue, 10.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[1].computedValue, 60.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.totalNodesValue, 100.0, accuracy: 0.0001)
    }

    @MainActor
    func testParentIndependentSumsLeaves() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1", value: 10.0),
                Node(name: "A2", value: 20.0),
            ]),
            Node(name: "B", value: 30.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentIndependent(totalValue: nil))

        XCTAssertEqual(configuration.nodes[0].computedValue, 30.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[1].computedValue, 30.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.totalNodesValue, 60.0, accuracy: 0.0001)
    }

    @MainActor
    func testTotalValueOverride() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1", value: 10.0),
                Node(name: "A2", value: 20.0),
            ]),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentIndependent(totalValue: 200.0))

        XCTAssertEqual(configuration.totalNodesValue, 200.0, accuracy: 0.0001)
    }

    @MainActor
    func testParentDependentTotalValueOverride() {
        let nodes = [
            Node(name: "A", value: 10.0),
            Node(name: "B", value: 20.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: 100.0))

        XCTAssertEqual(configuration.totalNodesValue, 100.0, accuracy: 0.0001)
    }

    @MainActor
    func testSelectionCleanupWhenNodesChange() {
        let node = Node(name: "Root")
        let configuration = SunburstConfiguration(nodes: [node])
        configuration.selectedNode = node
        configuration.focusedNode = node

        configuration.nodes = []

        XCTAssertNil(configuration.selectedNode)
        XCTAssertNil(configuration.focusedNode)
    }

    @MainActor
    func testValidationIssuesEmptyForValidConfiguration() {
        let nodes = [
            Node(name: "A", value: 10.0),
            Node(name: "B", value: 20.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: 30.0))
        XCTAssertTrue(configuration.validationIssues.isEmpty)
        XCTAssertNil(configuration.validationIssue)
    }

    @MainActor
    func testParentDependentMissingValueSetsValidationIssueAndFallsBack() {
        let nodes = [
            Node(name: "A"),
            Node(name: "B", value: 10.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))

        XCTAssertEqual(configuration.nodes[0].computedValue, 0.0, accuracy: 0.0001)
        if case .missingNodeValue(let mode, let nodeID)? = configuration.validationIssue {
            XCTAssertEqual(mode, .parentDependent(totalValue: nil))
            XCTAssertEqual(nodeID, configuration.nodes[0].id)
        } else {
            XCTFail("Expected missing node value validation issue")
        }
    }

    @MainActor
    func testParentDependentMissingValuePreservesConfiguredMode() {
        let nodes = [
            Node(name: "A"),
            Node(name: "B", value: 10.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: 100.0))

        if case .missingNodeValue(let mode, _)? = configuration.validationIssue {
            XCTAssertEqual(mode, .parentDependent(totalValue: 100.0))
        } else {
            XCTFail("Expected missing node value validation issue")
        }
    }

    @MainActor
    func testParentDependentMissingParentValueFallsBackToChildrenSum() {
        let nodes = [
            Node(name: "Root", children: [
                Node(name: "A", value: 2.0),
                Node(name: "B", value: 3.0),
            ]),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))

        XCTAssertEqual(configuration.nodes[0].computedValue, 5.0, accuracy: 0.0001)
        XCTAssertTrue(configuration.validationIssues.contains(.missingNodeValue(mode: .parentDependent(totalValue: nil),
                                                                                nodeID: configuration.nodes[0].id)))
    }

    @MainActor
    func testParentIndependentMissingLeafSetsValidationIssueAndUsesZeroFallback() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1"),
            ]),
            Node(name: "B", value: 5.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentIndependent(totalValue: nil))

        XCTAssertEqual(configuration.nodes[0].children[0].computedValue, 0.0, accuracy: 0.0001)
        XCTAssertEqual(configuration.nodes[0].computedValue, 0.0, accuracy: 0.0001)
        if case .missingNodeValue(let mode, let nodeID)? = configuration.validationIssue {
            XCTAssertEqual(mode, .parentIndependent(totalValue: nil))
            XCTAssertEqual(nodeID, configuration.nodes[0].children[0].id)
        } else {
            XCTFail("Expected missing leaf value validation issue")
        }
    }

    @MainActor
    func testParentIndependentMissingLeafPreservesConfiguredMode() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1"),
            ]),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentIndependent(totalValue: 100.0))

        if case .missingNodeValue(let mode, _)? = configuration.validationIssue {
            XCTAssertEqual(mode, .parentIndependent(totalValue: 100.0))
        } else {
            XCTFail("Expected missing leaf value validation issue")
        }
    }

    @MainActor
    func testParentIndependentCollectsAllMissingLeafIssues() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1"),
                Node(name: "A2"),
            ]),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentIndependent(totalValue: nil))

        let missingNodeIDs = Set(configuration.validationIssues.compactMap { issue -> UUID? in
            guard case .missingNodeValue(_, let nodeID) = issue else { return nil }
            return nodeID
        })
        let expectedNodeIDs = Set(configuration.nodes[0].children.map(\.id))
        XCTAssertEqual(missingNodeIDs, expectedNodeIDs)
    }

    @MainActor
    func testParentDependentChildrenCannotExceedParentComputedValue() {
        let nodes = [
            Node(name: "Root", value: 10.0, children: [
                Node(name: "A", value: 8.0),
                Node(name: "B", value: 7.0),
            ])
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))

        XCTAssertEqual(configuration.nodes[0].computedValue, 15.0, accuracy: 0.0001)
        if case .parentValueLessThanChildren(let nodeID, let parentValue, let childrenSum)? = configuration.validationIssue {
            XCTAssertEqual(nodeID, configuration.nodes[0].id)
            XCTAssertEqual(parentValue, 10.0, accuracy: 0.0001)
            XCTAssertEqual(childrenSum, 15.0, accuracy: 0.0001)
        } else {
            XCTFail("Expected parent value less than children validation issue")
        }
    }

    @MainActor
    func testTotalValueTooSmallGetsClampedForDisplay() {
        let nodes = [
            Node(name: "A", children: [
                Node(name: "A1", value: 10.0),
                Node(name: "A2", value: 20.0),
            ]),
            Node(name: "B", value: 30.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentIndependent(totalValue: 50.0))

        XCTAssertEqual(configuration.totalNodesValue, 60.0, accuracy: 0.0001)
        if case .totalValueTooSmall(let mode, let provided, let requiredMinimum)? = configuration.validationIssue {
            XCTAssertEqual(mode, .parentIndependent(totalValue: 50.0))
            XCTAssertEqual(provided, 50.0, accuracy: 0.0001)
            XCTAssertEqual(requiredMinimum, 60.0, accuracy: 0.0001)
        } else {
            XCTFail("Expected total value too small validation issue")
        }
    }

    @MainActor
    func testMultipleValidationIssuesAreCollected() {
        let nodes = [
            Node(name: "Root", value: 10.0, children: [
                Node(name: "A", value: 8.0),
                Node(name: "B", value: 7.0),
            ])
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: 5.0))

        XCTAssertTrue(configuration.validationIssues.contains {
            if case .parentValueLessThanChildren(let nodeID, let parentValue, let childrenSum) = $0 {
                return nodeID == configuration.nodes[0].id
                    && abs(parentValue - 10.0) < 0.0001
                    && abs(childrenSum - 15.0) < 0.0001
            }
            return false
        })
        XCTAssertTrue(configuration.validationIssues.contains {
            if case .totalValueTooSmall(let mode, let provided, let requiredMinimum) = $0 {
                return mode == .parentDependent(totalValue: 5.0)
                    && abs(provided - 5.0) < 0.0001
                    && abs(requiredMinimum - 15.0) < 0.0001
            }
            return false
        })
        XCTAssertEqual(configuration.totalNodesValue, 15.0, accuracy: 0.0001)
    }

    @MainActor
    func testValidationIssueConvenienceReturnsFirstIssue() {
        let nodes = [
            Node(name: "Root", value: 10.0, children: [
                Node(name: "A", value: 8.0),
                Node(name: "B", value: 7.0),
            ])
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: 5.0))

        if case .parentValueLessThanChildren(let nodeID, let parentValue, let childrenSum)? = configuration.validationIssue {
            XCTAssertEqual(nodeID, configuration.nodes[0].id)
            XCTAssertEqual(parentValue, 10.0, accuracy: 0.0001)
            XCTAssertEqual(childrenSum, 15.0, accuracy: 0.0001)
        } else {
            XCTFail("Expected first validation issue to be parentValueLessThanChildren")
        }
    }

    @MainActor
    func testValidationIssuesResetWhenConfigurationBecomesValid() {
        let invalidNodes = [
            Node(name: "A"),
        ]
        let configuration = SunburstConfiguration(nodes: invalidNodes, calculationMode: .parentDependent(totalValue: nil))
        XCTAssertFalse(configuration.validationIssues.isEmpty)

        configuration.nodes = [
            Node(name: "A", value: 10.0),
            Node(name: "B", value: 5.0),
        ]

        XCTAssertTrue(configuration.validationIssues.isEmpty)
        XCTAssertNil(configuration.validationIssue)
    }

    @MainActor
    func testValidationIssuesDoNotAccumulateAcrossRevalidation() {
        let invalidNodes = [
            Node(name: "A"),
        ]
        let configuration = SunburstConfiguration(nodes: invalidNodes, calculationMode: .parentDependent(totalValue: nil))
        XCTAssertEqual(configuration.validationIssues.count, 1)

        configuration.nodes = invalidNodes
        XCTAssertEqual(configuration.validationIssues.count, 1)
    }

    @MainActor
    func testAllowsSelectionFalseClearsState() {
        let node = Node(name: "Root")
        let configuration = SunburstConfiguration(nodes: [node])
        configuration.selectedNode = node
        configuration.focusedNode = node
        configuration.allowsSelection = false

        XCTAssertNil(configuration.selectedNode)
        XCTAssertNil(configuration.focusedNode)
    }

    @MainActor
    func testNodeSortingAscAndDescAffectsArcOrder() async {
        let nodes = [
            Node(name: "A", value: 30.0),
            Node(name: "B", value: 10.0),
            Node(name: "C", value: 20.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))

        configuration.nodesSort = .asc
        await Task.yield()
        XCTAssertEqual(configuration.sunburst.rootArcs.map(\.node.name), ["B", "C", "A"])

        configuration.nodesSort = .desc
        await Task.yield()
        XCTAssertEqual(configuration.sunburst.rootArcs.map(\.node.name), ["A", "C", "B"])
    }

    @MainActor
    func testNodeSortingCoalescesToLatestValue() async {
        let nodes = [
            Node(name: "A", value: 30.0),
            Node(name: "B", value: 10.0),
            Node(name: "C", value: 20.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))

        configuration.nodesSort = .asc
        configuration.nodesSort = .desc
        await Task.yield()
        XCTAssertEqual(configuration.sunburst.rootArcs.map(\.node.name), ["A", "C", "B"])
    }

    @MainActor
    func testCollapsedArcsHideDecorations() async {
        let nodes = [
            Node(name: "Root", value: 100.0, children: [
                Node(name: "Child", value: 100.0),
            ])
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))
        configuration.maximumExpandedRingsShownCount = 0
        await Task.yield()

        guard let rootArc = configuration.sunburst.rootArcs.first else {
            XCTFail("Expected root arc")
            return
        }
        XCTAssertFalse(rootArc.isExpanded)
        XCTAssertFalse(rootArc.showsDecorations)
    }

    @MainActor
    func testMaximumRingsHiddenArcsDoNotShowDecorations() async {
        let nodes = [
            Node(name: "Root", value: 100.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))
        configuration.maximumRingsShownCount = 0
        await Task.yield()

        guard let rootArc = configuration.sunburst.rootArcs.first else {
            XCTFail("Expected root arc")
            return
        }
        XCTAssertFalse(rootArc.showsDecorations)
    }

    @MainActor
    func testExpandedArcShowsDecorationsByDefault() {
        let nodes = [
            Node(name: "Root", value: 100.0),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .parentDependent(totalValue: nil))
        guard let rootArc = configuration.sunburst.rootArcs.first else {
            XCTFail("Expected root arc")
            return
        }
        XCTAssertTrue(rootArc.isExpanded)
        XCTAssertTrue(rootArc.showsDecorations)
    }

    @MainActor
    func testMissingBackgroundColorsUseDefaultBackground() {
        let nodes = [
            Node(name: "A"),
            Node(name: "B"),
            Node(name: "C", backgroundColor: .system(.pink)),
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .ordinalFromRoot)

        XCTAssertEqual(configuration.nodes[0].computedBackgroundColor, .defaultBackground)
        XCTAssertEqual(configuration.nodes[1].computedBackgroundColor, .defaultBackground)
        XCTAssertEqual(configuration.nodes[2].computedBackgroundColor, .system(.pink))
    }

    @MainActor
    func testMissingChildBackgroundColorsUseDefaultBackground() {
        let nodes = [
            Node(name: "Root", children: [
                Node(name: "A"),
                Node(name: "B"),
            ])
        ]
        let configuration = SunburstConfiguration(nodes: nodes, calculationMode: .ordinalFromRoot)

        XCTAssertEqual(configuration.nodes[0].computedBackgroundColor, .defaultBackground)
        XCTAssertEqual(configuration.nodes[0].children[0].computedBackgroundColor, .defaultBackground)
        XCTAssertEqual(configuration.nodes[0].children[1].computedBackgroundColor, .defaultBackground)
    }

    @MainActor
    func testBundleRefResolutionPaths() {
        XCTAssertEqual(BundleRef.main.resolve(), .main)
        XCTAssertEqual(BundleRef.identifier("com.invalid.bundle.id").resolve(), .main)
        XCTAssertNotNil(BundleRef.module.resolve().bundleIdentifier ?? BundleRef.module.resolve().bundlePath)
    }

    @MainActor
    func testRootArcEqualityChangesWhenOnlyImageChanges() async {
        let nodeID = UUID()
        let originalNode = Node(id: nodeID, name: "Node", image: nil, value: 10.0)
        let configuration = SunburstConfiguration(nodes: [originalNode], calculationMode: .parentDependent(totalValue: nil))
        let originalArcs = configuration.sunburst.rootArcs

        var updatedNode = originalNode
        updatedNode.image = .systemSymbol(name: "gear")
        configuration.nodes = [updatedNode]
        await Task.yield()

        let updatedArcs = configuration.sunburst.rootArcs
        XCTAssertEqual(updatedArcs.first?.node.image, .systemSymbol(name: "gear"))
        XCTAssertNotEqual(originalArcs, updatedArcs)
    }

    @MainActor
    func testParentArcEqualityChangesWhenChildImageChanges() async {
        let childID = UUID()
        let parentID = UUID()
        let originalChild = Node(id: childID, name: "Child", image: nil, value: 10.0)
        let originalParent = Node(id: parentID, name: "Parent", value: 10.0, children: [originalChild])
        let configuration = SunburstConfiguration(nodes: [originalParent], calculationMode: .parentDependent(totalValue: nil))
        let originalArcs = configuration.sunburst.rootArcs

        var updatedChild = originalChild
        updatedChild.image = .systemSymbol(name: "gear")
        var updatedParent = originalParent
        updatedParent.children = [updatedChild]
        configuration.nodes = [updatedParent]
        await Task.yield()

        let updatedArcs = configuration.sunburst.rootArcs
        XCTAssertEqual(updatedArcs.first?.childArcs?.first?.node.image, .systemSymbol(name: "gear"))
        XCTAssertNotEqual(originalArcs, updatedArcs)
    }
}

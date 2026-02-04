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
    func testSelectionCleanupWhenNodesChange() {
        let node = Node(name: "Root")
        let configuration = SunburstConfiguration(nodes: [node])
        configuration.selectedNode = node
        configuration.focusedNode = node

        configuration.nodes = []

        XCTAssertNil(configuration.selectedNode)
        XCTAssertNil(configuration.focusedNode)
    }
}

import XCTest
@testable import SunburstDiagram

final class SunburstDiagramTests: XCTestCase {
    
    func testSunburstArcHasTextHidden() {
        let node = Node(name: "Node", showName: true)
        let arc = Sunburst.Arc(node: node, level: 0, totalValue: .pi)
        XCTAssertEqual(arc.isTextHidden, !node.showName)
    }
}

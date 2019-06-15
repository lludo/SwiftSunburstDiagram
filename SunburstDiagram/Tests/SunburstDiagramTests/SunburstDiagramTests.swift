import XCTest
@testable import SunburstDiagram

final class SunburstDiagramTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case. Use XCTAssert
        // and related functions to verify your tests produce the correct results.
        let arc = Sunburst.Arc(text: "Label", width: .pi, hue: 0.5)
        XCTAssertEqual(arc.text, "Label")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

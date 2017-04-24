import XCTest
@testable import SwiftBncsLib

class SwiftBncsLibTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SwiftBncsLib().text, "Hello, World!")
    }


    static var allTests : [(String, (SwiftBncsLibTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

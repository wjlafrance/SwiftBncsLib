import XCTest
import Foundation
@testable import SwiftBncsLib

internal struct TestMessage: Message {
    var data: Foundation.Data
}

class MessageTests: XCTestCase {

    func testEquality() {
        XCTAssertEqual(
            TestMessage(data: Foundation.Data(bytes: [0])),
            TestMessage(data: Foundation.Data(bytes: [0])))

        XCTAssertNotEqual(
            TestMessage(data: Foundation.Data(bytes: [0])),
            TestMessage(data: Foundation.Data(bytes: [1])))
    }

}

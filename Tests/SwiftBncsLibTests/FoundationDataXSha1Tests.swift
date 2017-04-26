import XCTest
@testable import SwiftBncsLib

class FoundationDataXSha1Tests: XCTestCase {

    func testXSha1() {
        let input = Foundation.Data(bytes: [0x74, 0x68, 0x69, 0x73, 0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x74, 0x65, 0x73, 0x74, 0x20, 0x73, 0x74, 0x72, 0x69, 0x6e, 0x67])
        let result = input.xsha1()

        XCTAssertEqual(0xCEF7E12D, result.0)
        XCTAssertEqual(0x8514304A, result.1)
        XCTAssertEqual(0xE56199C5, result.2)
        XCTAssertEqual(0x17C78D34, result.3)
        XCTAssertEqual(0xBDCC1639, result.4)

        let input2 = Foundation.Data(bytes: [0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30])
        let result2 = input2.xsha1()

        XCTAssertEqual(0x99f0fab8, result2.0)
        XCTAssertEqual(0xb5b4523e, result2.1)
        XCTAssertEqual(0x0d58e5ef, result2.2)
        XCTAssertEqual(0xe126fa5f, result2.3)
        XCTAssertEqual(0x12633b4b, result2.4)
    }

}

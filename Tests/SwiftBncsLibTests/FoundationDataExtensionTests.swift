import XCTest
@testable import SwiftBncsLib

class FoundationDataExtensionTests: XCTestCase {

    func testArrayOfBytes() {
        let inputBytes: [UInt8] = [1, 2, 3, 127, 255, 0]

        let testData = Foundation.Data(bytes: inputBytes)

        XCTAssertEqual(testData.arrayOfBytes(), inputBytes)
    }

    func testHexDescription() {
        let inputBytes = [UInt8](1...255)
        let testData = Foundation.Data(bytes: inputBytes)

        let test = testData.hexDescription

        // Printable characters
        XCTAssertEqual(test.components(separatedBy: "\n")[2],
           "0020: 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30    !\"#$%&'()*+,-./0")

        // Non-printable characters
        // Handling non-full lines
        XCTAssertEqual(test.components(separatedBy: "\n")[15],
           "00F0: F1 F2 F3 F4 F5 F6 F7 F8 F9 FA FB FC FD FE FF       ............... ")
    }

}

import XCTest
@testable import SwiftBncsLib

class FourCCTests: XCTestCase {

    func testStringRepresentationRoundTrip() {
        XCTAssertEqual("RATS", FourCC(stringRepresentation: "RATS").stringRepresentation)
    }

    func testRawValue() {
        XCTAssertEqual(BncsProductIdentifier.Starcraft.rawValue, FourCC(stringRepresentation: "RATS").rawValue)
    }

}

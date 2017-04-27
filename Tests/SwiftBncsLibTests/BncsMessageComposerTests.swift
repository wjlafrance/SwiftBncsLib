import XCTest
@testable import SwiftBncsLib

class BncsMessageComposerTests: XCTestCase {

    func testBuild() {
        var testComposer = BncsMessageComposer()
        testComposer.write(0xEFBEADDE as UInt32)
        testComposer.write(0x80000001 as UInt32)
        testComposer.write("str1")
        testComposer.write("str2")

        let testMessage = testComposer.build(messageIdentifier: .Registry)
        XCTAssertEqual(testMessage, BncsMessage.exampleRegistryMessage)

    }

}

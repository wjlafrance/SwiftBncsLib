import XCTest
@testable import SwiftBncsLib

class BncsMessageTests: XCTestCase {

    let examplePingMessageData = Foundation.Data(bytes: [0xFF, 0x25, 0x08, 0x00, 0xDE, 0xAD, 0xBE, 0xEF])

    func testCanBeInitializedWithValidData() {
        guard let testMessage = try? BncsMessage(data: examplePingMessageData) else {
            XCTFail()
            return
        }

        XCTAssertEqual(testMessage.data, examplePingMessageData)

        XCTAssertEqual(testMessage.readIndex, 4, "read index should be past header")
    }

    func testInitializationThrowsForMalformedMessages() {
        let malformedMessages: [[UInt8]] = [
            [], // empty
            [0xFF, 0x25, 0x01], // partial header
            [0x12, 0x25, 0x05, 0x00], // wrong sanity bit
            [0xFF, 0x25, 0x08, 0x00, 0x00], // wrong length
        ]

        for malformedMessage in malformedMessages {
            let data = Foundation.Data(bytes: malformedMessage)

            var hasThrown = false
            do {
                let testMessage = try BncsMessage(data: data)
                XCTFail("\(testMessage)")
            } catch {
                hasThrown = true
            }
            XCTAssertTrue(hasThrown)
        }
    }

}

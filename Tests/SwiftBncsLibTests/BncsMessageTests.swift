import XCTest
@testable import SwiftBncsLib

extension BncsMessage {
    internal static var examplePingMessageData: Foundation.Data {
        return Foundation.Data(bytes: [0xFF, 0x25, 0x08, 0x00, 0xDE, 0xAD, 0xBE, 0xEF])
    }

    internal static var examplePingMessage: BncsMessage {
        return try! BncsMessage(data: examplePingMessageData)
    }
}

class BncsMessageTests: XCTestCase {

    func testCanBeInitializedWithValidData() {
        guard let testMessage = try? BncsMessage(data: BncsMessage.examplePingMessageData) else {
            XCTFail()
            return
        }

        XCTAssertEqual(testMessage.data, BncsMessage.examplePingMessageData)
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

    func testIdentifier() {
        let testMessage = BncsMessage.examplePingMessage

        XCTAssertEqual(BncsMessageIdentifier.Ping, testMessage.identifier)
    }

    func testDebugDescription() {
        let testMessage = BncsMessage.examplePingMessage

        XCTAssertTrue(testMessage.debugDescription.hasPrefix("BncsMessage (Ping):\n0000: FF 25"))
    }

}

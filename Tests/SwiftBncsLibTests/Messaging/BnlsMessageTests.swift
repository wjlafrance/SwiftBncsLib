import XCTest
@testable import SwiftBncsLib

extension BnlsMessage {
    internal static var exampleAuthorizeMessageData: Foundation.Data {
        return Foundation.Data(bytes: [0x05, 0x00, 0x0E, 0x31, 0x00])
    }

    internal static var exampleAuthorizeMessage: BnlsMessage {
        return try! BnlsMessage(data: exampleAuthorizeMessageData)
    }
}

class BnlsMessageTests: XCTestCase {

    func testCanBeInitializedWithValidData() {
        guard let testMessage = try? BnlsMessage(data: BnlsMessage.exampleAuthorizeMessageData) else {
            XCTFail()
            return
        }

        XCTAssertEqual(testMessage.data, BnlsMessage.exampleAuthorizeMessageData)
    }

    func testInitializationThrowsForMalformedMessages() {
        let malformedMessages: [[UInt8]] = [
            [], // empty
            [0x02, 0x00], // partial header
            [0x04, 0x00, 0x0E], // wrong length
        ]

        for malformedMessage in malformedMessages {
            let data = Foundation.Data(bytes: malformedMessage)

            var hasThrown = false
            do {
                let testMessage = try BnlsMessage(data: data)
                XCTFail("\(testMessage)")
            } catch {
                hasThrown = true
            }
            XCTAssertTrue(hasThrown)
        }
    }

    func testIdentifier() {
        let testMessage = BnlsMessage.exampleAuthorizeMessage

        XCTAssertEqual(BnlsMessageIdentifier.Authorize, testMessage.identifier)
    }

    func testDebugDescription() {
        let testMessage = BnlsMessage.exampleAuthorizeMessage

        XCTAssertTrue(testMessage.debugDescription.hasPrefix("BnlsMessage (Authorize):\n0000: 05"))
    }
    
}

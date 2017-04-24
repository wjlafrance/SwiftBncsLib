import XCTest
@testable import SwiftBncsLib

extension BncsMessage {
    internal static var examplePingMessage: BncsMessage {
        return try! BncsMessage(data: Foundation.Data(bytes: [0xFF, 0x25, 0x08, 0x00, 0xDE, 0xAD, 0xBE, 0xEF]))
    }
}

class BncsMessageConsumerTests: XCTestCase {

    func testIdentifier() {
        let testConsumer = BncsMessageConsumer(message: BncsMessage.examplePingMessage)

        XCTAssertEqual(BncsMessageIdentifier.Ping, testConsumer.identifier)
    }

}

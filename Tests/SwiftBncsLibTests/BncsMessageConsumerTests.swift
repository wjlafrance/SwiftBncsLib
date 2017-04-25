import XCTest
@testable import SwiftBncsLib

class BncsMessageConsumerTests: XCTestCase {

    func testInitializationStoresMessage() {
        let testConsumer = BncsMessageConsumer(message: BncsMessage.examplePingMessage)

        XCTAssertEqual(testConsumer.message, BncsMessage.examplePingMessage)
    }

    func testInitializationMovesReadIndex() {
        let testConsumer = BncsMessageConsumer(message: BncsMessage.examplePingMessage)

        XCTAssertEqual(testConsumer.readIndex, 4, "read index should be past header")
    }

}

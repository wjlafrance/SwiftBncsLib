import XCTest
@testable import SwiftBncsLib

class BncsMessageConsumerTests: XCTestCase {

    func generateTestConsumer() -> BncsMessageConsumer {
        return BncsMessageConsumer(message: BncsMessage.exampleRegistryMessage)
    }

    func testInitializationStoresMessage() {
        let testConsumer = generateTestConsumer()

        XCTAssertEqual(testConsumer.message, BncsMessage.exampleRegistryMessage)
    }

    func testInitializationMovesReadIndex() {
        let testConsumer = generateTestConsumer()

        XCTAssertEqual(testConsumer.readIndex, 4, "read index should be past header")
    }
    
    func testDebugDescription() {
        let testConsumer = generateTestConsumer()

        XCTAssertEqual(testConsumer.debugDescription, "BncsMessageConsumer<idx: 4, msg: \(testConsumer.message.debugDescription)")
    }

}

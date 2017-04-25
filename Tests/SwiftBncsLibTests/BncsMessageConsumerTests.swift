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

    func testReadUInt8() {
        let testU8Consumer = generateTestConsumer()
        XCTAssertEqual(0xDE, testU8Consumer.readUInt8())
        XCTAssertEqual(5, testU8Consumer.readIndex)
    }
    func testReadUInt16() {
        let testU16Consumer = generateTestConsumer()
        XCTAssertEqual(0xADDE, testU16Consumer.readUInt16())
        XCTAssertEqual(4 + (16 / 8), testU16Consumer.readIndex)
    }
    func testReadUInt32() {
        let testU32Consumer = generateTestConsumer()
        XCTAssertEqual(0xEFBEADDE, testU32Consumer.readUInt32())
        XCTAssertEqual(4 + (32 / 8), testU32Consumer.readIndex)
    }
    func testReadUInt64() {
        let testU64Consumer = generateTestConsumer()
        XCTAssertEqual(0x80000001EFBEADDE, testU64Consumer.readUInt64())
        XCTAssertEqual(4 + (64 / 8), testU64Consumer.readIndex)
    }

}

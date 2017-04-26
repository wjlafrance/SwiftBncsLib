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
        let testConsumer = generateTestConsumer()
        XCTAssertEqual(0xDE, testConsumer.readUInt8())
        XCTAssertEqual(5, testConsumer.readIndex)
    }
    func testReadUInt16() {
        let testConsumer = generateTestConsumer()
        XCTAssertEqual(0xADDE, testConsumer.readUInt16())
        XCTAssertEqual(4 + (16 / 8), testConsumer.readIndex)
    }
    func testReadUInt32() {
        let testConsumer = generateTestConsumer()
        XCTAssertEqual(0xEFBEADDE, testConsumer.readUInt32())
        XCTAssertEqual(4 + (32 / 8), testConsumer.readIndex)
    }
    func testReadUInt64() {
        let testConsumer = generateTestConsumer()
        XCTAssertEqual(0x80000001EFBEADDE, testConsumer.readUInt64())
        XCTAssertEqual(4 + (64 / 8), testConsumer.readIndex)
    }

    func testReadNullTerminatedString() {
        let testConsumer = generateTestConsumer()
        testConsumer.readIndex = 12 // skip to first string index

        XCTAssertEqual("str1", testConsumer.readNullTerminatedString())
        XCTAssertEqual(17, testConsumer.readIndex)
        XCTAssertEqual("str2", testConsumer.readNullTerminatedString())
        XCTAssertEqual(22, testConsumer.readIndex)
    }

    func testDebugDescription() {
        let testConsumer = generateTestConsumer()

        XCTAssertEqual(testConsumer.debugDescription, "BncsMessageConsumer<idx: 4, msg: \(testConsumer.message.debugDescription)")
    }

}

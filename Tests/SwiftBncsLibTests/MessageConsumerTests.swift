import XCTest
@testable import SwiftBncsLib

class MessageConsumerTests: XCTestCase {

    func generateTestConsumer() -> BncsMessageConsumer {
        return BncsMessageConsumer(message: BncsMessage.exampleRegistryMessage)
    }

    func testBytesRemaining() {
        var testConsumer = generateTestConsumer()
        XCTAssertEqual(18, testConsumer.bytesRemaining)
        let _ = testConsumer.readUInt8Array(5)
        XCTAssertEqual(13, testConsumer.bytesRemaining)
    }

    func testReadUInt8() {
        var testConsumer = generateTestConsumer()
        XCTAssertEqual(0xDE, testConsumer.readUInt8())
        XCTAssertEqual(5, testConsumer.readIndex)
    }

    func testReadUInt8Array() {
        var testConsumer = generateTestConsumer()
        XCTAssertEqual([0xDE, 0xAD], testConsumer.readUInt8Array(2))
        XCTAssertEqual([0xBE, 0xEF], testConsumer.readUInt8Array(2))
        XCTAssertEqual(4 + (32 / 8), testConsumer.readIndex)
    }

    func testReadUInt16() {
        var testConsumer = generateTestConsumer()
        XCTAssertEqual(0xADDE, testConsumer.readUInt16())
        XCTAssertEqual(4 + (16 / 8), testConsumer.readIndex)
    }

    func testReadUInt32() {
        var testConsumer = generateTestConsumer()
        XCTAssertEqual(0xEFBEADDE, testConsumer.readUInt32())
        XCTAssertEqual(4 + (32 / 8), testConsumer.readIndex)
    }

    func testReadUInt64() {
        var testConsumer = generateTestConsumer()
        XCTAssertEqual(0x80000001EFBEADDE, testConsumer.readUInt64())
        XCTAssertEqual(4 + (64 / 8), testConsumer.readIndex)
    }

    func testReadNullTerminatedString() {
        var testConsumer = generateTestConsumer()
        testConsumer.readIndex = 12 // skip to first string index

        XCTAssertEqual("str1", testConsumer.readNullTerminatedString())
        XCTAssertEqual(17, testConsumer.readIndex)
        XCTAssertEqual("str2", testConsumer.readNullTerminatedString())
        XCTAssertEqual(22, testConsumer.readIndex)
    }

    func testReadFixedLengthString() {
        var testConsumer = generateTestConsumer()
        testConsumer.readIndex = 12 // skip to first string index

        XCTAssertEqual("str1", testConsumer.readString(length: 4))
        XCTAssertEqual(0, testConsumer.readUInt8())
        XCTAssertEqual(17, testConsumer.readIndex)
        XCTAssertEqual("str2", testConsumer.readString(length: 4))
        XCTAssertEqual(0, testConsumer.readUInt8())
        XCTAssertEqual(22, testConsumer.readIndex)
    }

}

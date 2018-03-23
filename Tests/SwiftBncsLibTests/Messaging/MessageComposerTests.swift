import XCTest
@testable import SwiftBncsLib

class MessageComposerTests: XCTestCase {

    func testWriteUInt8() {
        var testComposer = RawMessageComposer()
        testComposer.write(0x01 as UInt8)
        XCTAssertEqual(testComposer.data.arrayOfBytes(), [0x01])
    }

    func testWriteUInt16() {
        var testComposer = RawMessageComposer()
        testComposer.write(0xDEAD as UInt16)
        XCTAssertEqual(testComposer.data.arrayOfBytes(), [0xAD, 0xDE])
    }

    func testWriteUInt32() {
        var testComposer = RawMessageComposer()
        testComposer.write(0xDEADBEEF as UInt32)
        XCTAssertEqual(testComposer.data.arrayOfBytes(), [0xEF, 0xBE, 0xAD, 0xDE])
    }

    func testWriteUInt64() {
        var testComposer = RawMessageComposer()
        testComposer.write(0xCAFEBABEDEADBEEF as UInt64)
        XCTAssertEqual(testComposer.data.arrayOfBytes(), [0xEF, 0xBE, 0xAD, 0xDE, 0xBE, 0xBA, 0xFE, 0xCA])
    }

    func testWriteString() {
        var testComposer = RawMessageComposer()
        testComposer.write("1")
        XCTAssertEqual(testComposer.data.arrayOfBytes(), [0x31, 0x00])
    }

    func testWriteByteArray() {
        var testComposer = RawMessageComposer()
        testComposer.write([1, 2, 3])
        XCTAssertEqual(testComposer.data.arrayOfBytes(), [1, 2, 3])
    }

}

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

    func testFromUInt8Array() {
        let incompletePingData: [UInt8] = [0xFF, 0x25, 0x08, 0x00]

        var testInputUInt8Array = [UInt8]()
        testInputUInt8Array.append(contentsOf: BncsMessage.exampleRegistryMessageData.arrayOfBytes())
        testInputUInt8Array.append(contentsOf: BncsMessage.examplePingMessageData.arrayOfBytes())
        testInputUInt8Array.append(contentsOf: incompletePingData) // incomplete message

        let (messages, remainingBytes) = BncsMessageConsumer.fromUInt8Array(testInputUInt8Array)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].message.identifier, BncsMessageIdentifier.Registry)
        XCTAssertEqual(messages[1].message.identifier, BncsMessageIdentifier.Ping)
        XCTAssertEqual(remainingBytes, incompletePingData)
    }

}

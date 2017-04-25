import Foundation

class BncsMessageConsumer {

    var message: BncsMessage
    var readIndex: Foundation.Data.Index

    init(message: BncsMessage) {
        self.message = message
        self.readIndex = 4
    }

    func readUInt8() -> UInt8 {
        let x = message.data.arrayOfBytes()[readIndex]
        readIndex += 1
        return x
    }
    func readUInt16() -> UInt16 {
        return UInt16(readUInt8()) | UInt16(readUInt8()) << 8
    }
    func readUInt32() -> UInt32 {
        return UInt32(readUInt16()) | UInt32(readUInt16()) << 16
    }
    func readUInt64() -> UInt64 {
        return UInt64(readUInt32()) | UInt64(readUInt32()) << 32
    }

}

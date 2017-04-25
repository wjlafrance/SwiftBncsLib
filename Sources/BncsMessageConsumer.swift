import Foundation

class BncsMessageConsumer: CustomDebugStringConvertible {

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

    func readNullTerminatedString() -> String {
        var xs: [UInt8] = []
        var x: UInt8 = readUInt8()
        while x != 0 {
            xs.append(x)
            x = readUInt8()
        }

        guard let result = String(data: Foundation.Data(bytes: xs), encoding: .ascii) else {
            preconditionFailure("failed to decode ASCII string: \(xs)")
        }
        return result
    }

    //MARK: CustomDebugStringConvertible

    var debugDescription: String {
        return "BncsMessageConsumer<idx: \(readIndex), msg: \(message)"
    }

}

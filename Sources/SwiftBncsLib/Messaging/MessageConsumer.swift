import Foundation

protocol MessageConsumer {
    associatedtype MessageType: Message

    var readIndex: Foundation.Data.Index { get set }
    var message: MessageType { get }
}


struct RawMessageConsumer: MessageConsumer {

    var readIndex: Foundation.Data.Index
    var message: Foundation.Data

    init(message: Foundation.Data) {
        self.message = message
        self.readIndex = 0
    }

}

extension MessageConsumer {

    var bytesRemaining: Int {
        return message.data.count - readIndex
    }

    public mutating func readUInt8() -> UInt8 {
        let x: UInt8 = message.data.getByte(at: readIndex)
        readIndex += 1
        return x
    }

    public mutating func readUInt8Array(_ length: Int) -> [UInt8] {
        var xs = [UInt8]()
        for _ in 0..<length {
            xs.append(readUInt8())
        }
        return xs
    }

    public mutating func readUInt16() -> UInt16 {
        return UInt16(readUInt8()) | UInt16(readUInt8()) << 8
    }

    public mutating func readUInt32() -> UInt32 {
        return UInt32(readUInt16()) | UInt32(readUInt16()) << 16
    }

    public mutating func readUInt64() -> UInt64 {
        return UInt64(readUInt32()) | UInt64(readUInt32()) << 32
    }

    public mutating func readNullTerminatedString() -> String {
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

    public mutating func readString(length: Int) -> String {
        var xs: [UInt8] = []
        for _ in 0 ..< length {
            xs.append(readUInt8())
        }

        guard let result = String(data: Foundation.Data(bytes: xs), encoding: .ascii) else {
            preconditionFailure("failed to decode ASCII string: \(xs)")
        }
        return result
    }

}

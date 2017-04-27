import Foundation

protocol MessageComposer {

    associatedtype MessageIdentifier
    associatedtype MessageType

    var data: Foundation.Data { get set }

    func build(messageIdentifier: MessageIdentifier) -> MessageType

}

struct RawMessageComposer: MessageComposer {

    var data: Foundation.Data = Foundation.Data()

    func build(messageIdentifier: ()) -> Foundation.Data {
        return data
    }

}

extension MessageComposer {

    mutating func write(_ x: UInt8) {
        data.append(x)
    }

    mutating func write(_ x: UInt16) {
        write(UInt8(x >> 0 & 0xFF))
        write(UInt8(x >> 8 & 0xFF))
    }

    mutating func write(_ x: UInt32) {
        write(UInt16(x >>  0 & 0xFFFF))
        write(UInt16(x >> 16 & 0xFFFF))
    }

    mutating func write(_ x: UInt64) {
        write(UInt32(x >>  0 & 0xFFFFFFFF))
        write(UInt32(x >> 32 & 0xFFFFFFFF))
    }

    mutating func write(_ x: String) {
        write(x.utf8CString.map { UInt8($0) })
    }
    
    mutating func write(_ x: [UInt8]) {
        data.append(contentsOf: x)
    }

}

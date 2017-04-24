import Foundation

enum BncsMessageError: Error {
    case MalformedHeader
    case IllegalSanityByte
    case IncorrectMessageLength
}

struct BncsMessage {
    var data: Foundation.Data
    var readIndex: Foundation.Data.Index

    init(data: Foundation.Data) throws {

        // Check entire header is present
        guard data.count >= 4 else {
            throw BncsMessageError.MalformedHeader
        }

        // Check sanity bit
        guard 0xFF == data.arrayOfBytes()[0] else {
            throw BncsMessageError.IllegalSanityByte
        }

        // Check length matches
        guard data.count == Int(data.arrayOfBytes()[2]) |
                            Int(data.arrayOfBytes()[3]) << 8 else {
                throw BncsMessageError.IncorrectMessageLength
        }

        self.data = data
        self.readIndex = 4
    }
}

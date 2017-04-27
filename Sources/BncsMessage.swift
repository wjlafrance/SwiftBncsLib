import Foundation

enum BncsMessageError: Error {
    case MalformedHeader
    case IllegalSanityByte
    case IncorrectMessageLength
}

struct BncsMessage: Message, CustomDebugStringConvertible {
    var data: Foundation.Data

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
    }

    var identifier: BncsMessageIdentifier {
        let rawIdentifier = data.arrayOfBytes()[1]

        if let x = BncsMessageIdentifier(rawValue: rawIdentifier) {
            return x
        }

        assertionFailure("Attempted to find BncsMessageIdentifier for unknown ID: \(rawIdentifier)")
        return BncsMessageIdentifier.Unknown
    }

    //MARK: CustomDebugStringConvertible

    var debugDescription: String {
        return "BncsMessage (\(identifier)):\n\(data.hexDescription)"
    }

}

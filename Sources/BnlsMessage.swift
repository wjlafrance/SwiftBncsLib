import Foundation

enum BnlsMessageError: Error {
    case MalformedHeader
    case IncorrectMessageLength
}

struct BnlsMessage: Message, CustomDebugStringConvertible {
    var data: Foundation.Data

    init(data: Foundation.Data) throws {

        // Check entire header is present
        guard data.count >= 3 else {
            throw BnlsMessageError.MalformedHeader
        }

        // Check length matches
        guard data.count == Int(data.arrayOfBytes()[0]) |
                           (Int(data.arrayOfBytes()[1]) << 8) else {
            throw BnlsMessageError.IncorrectMessageLength
        }

        self.data = data
    }

    var identifier: BnlsMessageIdentifier {
        let rawIdentifier = data.arrayOfBytes()[2]

        if let x = BnlsMessageIdentifier(rawValue: rawIdentifier) {
            return x
        }

        assertionFailure("Attempted to find BnlsMessageIdentifier for unknown ID: \(rawIdentifier)")
        return BnlsMessageIdentifier.Unknown
    }

    //MARK: CustomDebugStringConvertible

    var debugDescription: String {
        return "BnlsMessage (\(identifier)):\n\(data.hexDescription)"
    }
    
}

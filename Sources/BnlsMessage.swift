import Foundation

public enum BnlsMessageError: Error {
    case MalformedHeader
    case IncorrectMessageLength
}

public struct BnlsMessage: Message, CustomDebugStringConvertible {
    public let data: Foundation.Data

    public init(data: Foundation.Data) throws {

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

    public var identifier: BnlsMessageIdentifier {
        let rawIdentifier = data.arrayOfBytes()[2]

        if let x = BnlsMessageIdentifier(rawValue: rawIdentifier) {
            return x
        }

        assertionFailure("Attempted to find BnlsMessageIdentifier for unknown ID: \(rawIdentifier)")
        return BnlsMessageIdentifier.Unknown
    }

    //MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return "BnlsMessage (\(identifier)):\n\(data.hexDescription)"
    }
    
}

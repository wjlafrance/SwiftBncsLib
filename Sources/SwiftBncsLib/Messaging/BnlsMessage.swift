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
        guard data.count == data.withUnsafeBytes({ IntUtil.from8to16([$0[0], $0[1]]) }) else {
            throw BnlsMessageError.IncorrectMessageLength
        }

        self.data = data
    }

    public var identifier: BnlsMessageIdentifier {
        // Check entire header is present -- precondition is fine here, guard is used in init
        precondition(data.count > 3)

        let rawIdentifier: UInt8 = data.withUnsafeBytes { return $0[2] }
        return BnlsMessageIdentifier(rawValue: rawIdentifier) ?? .None
    }

    //MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return "BnlsMessage (\(identifier)):\n\(data.hexDescription)"
    }
    
}

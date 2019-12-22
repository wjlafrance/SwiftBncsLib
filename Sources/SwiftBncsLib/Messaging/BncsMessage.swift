import Foundation

enum BncsMessageError: Error {
    case MalformedHeader
    case IllegalSanityByte
    case IncorrectMessageLength
}

public struct BncsMessage: Message, CustomDebugStringConvertible {
    public var data: Foundation.Data

    public init(data: Foundation.Data) throws {

        // Check entire header is present
        guard data.count >= 4 else {
            throw BncsMessageError.MalformedHeader
        }

        // Check sanity bit
        guard 0xFF as UInt8 == data.getByte(at: 0) else {
            throw BncsMessageError.IllegalSanityByte
        }

        // Check length matches
      guard data.count == IntUtil.from8to16([data.getByte(at: 2), data.getByte(at: 3)]) else {
            throw BncsMessageError.IncorrectMessageLength
        }

        self.data = data
    }

    public var identifier: BncsMessageIdentifier {
        // Check entire header is present -- precondition is fine here, guard is used in init
        precondition(data.count > 2)

        let rawIdentifier = data.getByte(at: 1)
        return BncsMessageIdentifier(rawValue: rawIdentifier) ?? .None
    }

    //MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return "BncsMessage (\(identifier)):\n\(data.hexDescription)"
    }

}

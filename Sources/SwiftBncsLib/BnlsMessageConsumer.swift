import Foundation

public struct BnlsMessageConsumer: MessageConsumer, CustomDebugStringConvertible {

    var message: BnlsMessage
    var readIndex: Foundation.Data.Index

    public init(message: BnlsMessage) {
        self.message = message
        self.readIndex = 3
    }

    //MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return "BnlsMessageConsumer<idx: \(readIndex), msg: \(message)"
    }

}

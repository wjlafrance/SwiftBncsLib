import Foundation

public struct BncsMessageConsumer: MessageConsumer, CustomDebugStringConvertible {

    public var message: BncsMessage
    var readIndex: Foundation.Data.Index

    public init(message: BncsMessage) {
        self.message = message
        self.readIndex = 4
    }


    //MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return "BncsMessageConsumer<idx: \(readIndex), msg: \(message)"
    }

}

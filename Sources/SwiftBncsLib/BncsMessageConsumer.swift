import Foundation

struct BncsMessageConsumer: MessageConsumer, CustomDebugStringConvertible {

    var message: BncsMessage
    var readIndex: Foundation.Data.Index

    init(message: BncsMessage) {
        self.message = message
        self.readIndex = 4
    }

    //MARK: CustomDebugStringConvertible

    var debugDescription: String {
        return "BncsMessageConsumer<idx: \(readIndex), msg: \(message)"
    }

}

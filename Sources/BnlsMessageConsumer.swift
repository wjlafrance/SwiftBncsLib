import Foundation

struct BnlsMessageConsumer: MessageConsumer, CustomDebugStringConvertible {

    var message: BnlsMessage
    var readIndex: Foundation.Data.Index

    init(message: BnlsMessage) {
        self.message = message
        self.readIndex = 3
    }

    //MARK: CustomDebugStringConvertible

    var debugDescription: String {
        return "BnlsMessageConsumer<idx: \(readIndex), msg: \(message)"
    }
    
}

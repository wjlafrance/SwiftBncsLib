import Foundation

class BncsMessageConsumer {

    var message: BncsMessage
    var readIndex: Foundation.Data.Index

    init(message: BncsMessage) {
        self.message = message
        self.readIndex = 4
    }
    
}

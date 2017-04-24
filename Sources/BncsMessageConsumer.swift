class BncsMessageConsumer {

    var message: BncsMessage

    var identifier: BncsMessageIdentifier {
        let rawIdentifier = message.data.arrayOfBytes()[1]

        if let x = BncsMessageIdentifier(rawValue: rawIdentifier) {
            return x
        }

        assertionFailure("Attempted to find BncsMessageIdentifier for unknown ID: \(rawIdentifier)")
        return BncsMessageIdentifier.Unknown
    }

    init(message: BncsMessage) {
        self.message = message
    }
    
}

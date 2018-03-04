/// FourCC's stringRepresentation is how it appears in big-endian byte order. This may be the opposite of what you're expecting.

struct FourCC {

    let rawValue: UInt32

    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(stringRepresentation: String) {
        precondition(stringRepresentation.count >= 4, "not enough bytes for a 32-bit integer")
        assert(stringRepresentation.count == 4, "incorrect number of bytes for a 32-bit integer")

        var composer = RawMessageComposer()
        composer.write(stringRepresentation)
        var consumer = RawMessageConsumer(message: composer.build(messageIdentifier: ()))

        self.rawValue = consumer.readUInt32()
    }

    var stringRepresentation: String {
        var composer = RawMessageComposer()
        composer.write(rawValue)
        var consumer = RawMessageConsumer(message: composer.build(messageIdentifier: ()))
        return consumer.readString(length: 4)
    }

}

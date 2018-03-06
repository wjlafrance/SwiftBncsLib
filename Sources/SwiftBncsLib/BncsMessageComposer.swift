import Foundation

public struct BncsMessageComposer: MessageComposer {
    var data: Foundation.Data = Foundation.Data()

    public init() {}

    public func build(messageIdentifier: BncsMessageIdentifier) -> BncsMessage {

        var fullMessageComposer = RawMessageComposer()
        fullMessageComposer.write(0xFF as UInt8)
        fullMessageComposer.write(messageIdentifier.rawValue)
        fullMessageComposer.write(UInt16(4 + data.count))
        fullMessageComposer.write(data.arrayOfBytes())

        do {
            return try BncsMessage(data: fullMessageComposer.data)
        } catch (let error) {
            preconditionFailure("BncsMessageComposer is composing invalid BncsMessage's: \(error)")
        }
    }

}

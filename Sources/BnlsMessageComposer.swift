import Foundation

public struct BnlsMessageComposer: MessageComposer {

    var data: Foundation.Data = Foundation.Data()

    public init() {}

    public func build(messageIdentifier: BnlsMessageIdentifier) -> BnlsMessage {

        var fullMessageComposer = RawMessageComposer()
        fullMessageComposer.write(UInt16(3 + data.count))
        fullMessageComposer.write(messageIdentifier.rawValue)
        fullMessageComposer.write(data.arrayOfBytes())

        do {
            return try BnlsMessage(data: fullMessageComposer.data)
        } catch (let error) {
            preconditionFailure("BnlsMessageComposer is composing invalid BnlsMessage's: \(error)")
        }
    }
    
}

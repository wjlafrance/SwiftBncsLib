import Foundation

public struct BncsMessageConsumer: MessageConsumer, CustomDebugStringConvertible {

    var message: BncsMessage
    var readIndex: Foundation.Data.Index

    public static func fromUInt8Array(_ bytes: [UInt8]) -> ([BncsMessageConsumer], [UInt8]) {
        var messagesConsumers = [BncsMessageConsumer]()

        var bytesConsumer = RawMessageConsumer(message: Data(bytes: bytes))
        while bytesConsumer.bytesRemaining >= 4 {
            let sanity     = bytesConsumer.readUInt8()
            let identifier = bytesConsumer.readUInt8()
            let length     = bytesConsumer.readUInt16()
            bytesConsumer.readIndex -= 4

            if bytesConsumer.bytesRemaining < Int(length) {
                print("waiting on more data for packet identifier \(identifier), need \(length), have \(bytesConsumer.bytesRemaining)")
                break
            }

            print("received packet: sanity \(sanity), identifier: \(identifier), length: \(length)")

            do {
                let message = try BncsMessage(data: Data(bytes: bytesConsumer.readUInt8Array(Int(length))))
                messagesConsumers.append(BncsMessageConsumer(message: message))
            } catch (let error) {
                print("unable to parse bncs packet, moving on: \(error)")
            }

        }

        return (messagesConsumers, Array(bytes.suffix(from: bytesConsumer.readIndex)))
    }

    public init(message: BncsMessage) {
        self.message = message
        self.readIndex = 4
    }


    //MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        return "BncsMessageConsumer<idx: \(readIndex), msg: \(message)"
    }

}

import NIO
import SwiftBncsLib
import Foundation

extension SwiftBncsLib.Message {

    func writeToChannel(_ channel: Channel) -> EventLoopFuture<Void> {
        var buffer = channel.allocator.buffer(capacity: self.data.count)
        buffer.write(bytes: self.data.arrayOfBytes())
        return channel.writeAndFlush(buffer)
    }

}

private final class BncsMessageCodec: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = BncsMessage

    public var cumulationBuffer: ByteBuffer?

    public func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard buffer.readableBytes >= 4 else {
            return .needMoreData
        }

        let length = buffer.withUnsafeReadableBytes { urbp in
            return Int(urbp[2]) | Int(urbp[3] >> 8)
        }

        guard buffer.readableBytes >= length else {
            return .needMoreData
        }

        do {
            let message = try BncsMessage(data: Data(bytes: buffer.readBytes(length: length)!))
            ctx.fireChannelRead(self.wrapInboundOut(message))
        } catch (let error) {
            print("Error in BncsMessageCodec: \(error)")
        }

        return .continue
    }
}

private final class ChatHandler: ChannelInboundHandler {
    public typealias InboundIn = BncsMessage
    public typealias OutboundOut = ByteBuffer

    var incomingBuffer = [UInt8]()

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let message = self.unwrapInboundIn(data)
        var consumer = BncsMessageConsumer(message: message)

        switch consumer.message.identifier {
            case .Ping:
                print("[BNCS] Ping!")

            case .AuthInfo:
                print("[BNCS] Received auth challenge.")
                let loginType   = consumer.readUInt32()
                let serverToken = consumer.readUInt32()
                let udpValue    = consumer.readUInt32()
                let mpqFiletime = consumer.readUInt64()
                let mpqFilename = consumer.readNullTerminatedString()
                let valueString = consumer.readNullTerminatedString()
                print("[BNCS] Auth challenge received. Login type \(loginType), MPQ \(mpqFilename) (\(mpqFiletime)), challenge: \(valueString).")

            default:
                print("No parser for this packet!\n\(consumer)")
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }
}

let group = MultiThreadedEventLoopGroup(numThreads: 1)
let bootstrap = ClientBootstrap(group: group)
    // Enable SO_REUSEADDR.
    .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .channelInitializer { channel in
        channel.pipeline.add(handler: BncsMessageCodec()).then { v in
            channel.pipeline.add(handler: ChatHandler())
        }
    }
defer {
    try! group.syncShutdownGracefully()
}

print("[BNCS] Connecting...")
let channel = try bootstrap.connect(host: "useast.battle.net", port: 6112).wait()

print("[BNCS] Connected to \(channel.remoteAddress!).")

var protocolByteBuffer = channel.allocator.buffer(capacity: 1)
protocolByteBuffer.write(bytes: [1])
try! channel.writeAndFlush(protocolByteBuffer).wait()

var composer = BncsMessageComposer()
composer.write(0 as UInt32)
composer.write(BncsPlatformIdentifier.IntelX86.rawValue)
composer.write(BncsProductIdentifier.Diablo2.rawValue)
composer.write(0xD5 as UInt32)
composer.write(BncsLanguageIdentifier.EnglishUnitedStates.rawValue)
composer.write(0 as UInt32)
composer.write(0 as UInt32)
composer.write(0 as UInt32)
composer.write(0 as UInt32)
composer.write("USA")
composer.write("United States")
let authInfoMessage = composer.build(messageIdentifier: BncsMessageIdentifier.AuthInfo)
print(authInfoMessage)


print("[BNCS] Sending auth info...")
try! authInfoMessage.writeToChannel(channel).wait()



//while let line = readLine(strippingNewline: false) {
//    var buffer = channel.allocator.buffer(capacity: line.utf8.count)
//    buffer.write(string: line)
//    try! channel.writeAndFlush(buffer).wait()
//}

// EOF, close connect
//try! channel.read()

while let _ = readLine(strippingNewline: false) {
//    var buffer = channel.allocator.buffer(capacity: line.utf8.count)
//    buffer.write(string: line)
//    try! channel.writeAndFlush(buffer).wait()
}


//try! channel.close().wait()

//print("[BNCS] Disconnected.")


import NIO
import SwiftBncsLib
import SwiftBncsNIO
import Foundation

extension SwiftBncsLib.Message {

    func writeToChannel(_ channel: Channel) -> EventLoopFuture<Void> {
        var buffer = channel.allocator.buffer(capacity: self.data.count)
        buffer.write(bytes: self.data.arrayOfBytes())
        return channel.writeAndFlush(buffer)
    }

}

class BattleNetHandler: ChannelInboundHandler {
    public typealias InboundIn = BncsMessage
    public typealias OutboundOut = ByteBuffer

    var incomingBuffer = [UInt8]()

    /// Called when the `Channel` has successfully registered with its `EventLoop` to handle I/O.
    public func channelRegistered(ctx: ChannelHandlerContext) {
        ctx.fireChannelRegistered()

        print("[BNCS] Connecting...")
    }

    /// Called when the `Channel` has become active, and is able to send and receive data.
    public func channelActive(ctx: ChannelHandlerContext) {
        ctx.fireChannelActive()

        print("[BNCS] Connected to \(ctx.channel.remoteAddress!).")

        var protocolByteBuffer = ctx.channel.allocator.buffer(capacity: 1)
        protocolByteBuffer.write(bytes: [1])
        let _ = ctx.channel.writeAndFlush(protocolByteBuffer)

        var composer = BncsMessageComposer()
        composer.write(0 as UInt32)
        composer.write(BncsPlatformIdentifier.IntelX86.rawValue)
        composer.write(BncsProductIdentifier.Diablo2.rawValue)
        composer.write(0x0E as UInt32)
        composer.write(BncsLanguageIdentifier.EnglishUnitedStates.rawValue)
        composer.write(0 as UInt32)
        composer.write(0 as UInt32)
        composer.write(0 as UInt32)
        composer.write(0 as UInt32)
        composer.write("USA")
        composer.write("United States")
        print("[BNCS] Sending auth info...")
        let authInfoMessage = composer.build(messageIdentifier: BncsMessageIdentifier.AuthInfo)
        let _ = authInfoMessage.writeToChannel(ctx.channel)
    }

    /// Called when the `Channel` has become inactive and is no longer able to send and receive data`.
    public func channelInactive(ctx: ChannelHandlerContext) {
        ctx.fireChannelInactive()

        print("[BNCS] Disconnected.")
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let message = self.unwrapInboundIn(data)
        var consumer = BncsMessageConsumer(message: message)

        switch consumer.message.identifier {
            case .Null:
                let _ = BncsMessageComposer().build(messageIdentifier: .Null).writeToChannel(ctx.channel)
                print("[BNCS] Keep-alive.")

            case .Ping:
                let cookie = consumer.readUInt32()
                var composer = BncsMessageComposer()
                composer.write(cookie)
                let _ = composer.build(messageIdentifier: .Ping).writeToChannel(ctx.channel)
                print("[BNCS] Ping.")

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
        print("[BNCS] Error: ", error)

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
        channel.pipeline.add(handler: SwiftBncsNIO.ByteToBncsMessageDecoder()).then { v in
            channel.pipeline.add(handler: BattleNetHandler())
        }
    }
defer {
    try! group.syncShutdownGracefully()

}

print("[BNCS] Connecting...")
let channel = try bootstrap.connect(host: "useast.battle.net", port: 6112).wait()

try channel.closeFuture.wait()


//try! channel.close().wait()

//print("[BNCS] Disconnected.")


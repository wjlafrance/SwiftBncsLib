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

private final class ChatHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    var incomingBuffer = [UInt8]()

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)

        let bytesAvailable = buffer.readableBytes
        guard let bytesRead = buffer.readBytes(length: bytesAvailable) else {
            print("error: couldn't readBytes?")
            return
        }

        incomingBuffer.append(contentsOf: bytesRead)
//        print(incomingBuffer)


        // DO THE PARSE!

        let (messageConsumers, remainingBytes) = BncsMessageConsumer.fromUInt8Array(incomingBuffer)
        incomingBuffer = remainingBytes

        for messageConsumer in messageConsumers {
            print(messageConsumer)
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
        channel.pipeline.add(handler: ChatHandler())
    }
defer {
    try! group.syncShutdownGracefully()
}

print("[BNCS] Connecting...")
let channel = try bootstrap.connect(host: "uswest.battle.net", port: 6112).wait()

print("[BNCS] Connected to \(channel.remoteAddress!).")

var protocolByteBuffer = channel.allocator.buffer(capacity: 1)
protocolByteBuffer.write(bytes: [1])
try! channel.writeAndFlush(protocolByteBuffer).wait()

var composer = BncsMessageComposer()
composer.write(0 as UInt32)
composer.write(BncsPlatformIdentifier.IntelX86.rawValue)
composer.write(BncsProductIdentifier.StarcraftExpansion.rawValue)
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

while let line = readLine(strippingNewline: false) {
//    var buffer = channel.allocator.buffer(capacity: line.utf8.count)
//    buffer.write(string: line)
//    try! channel.writeAndFlush(buffer).wait()
}


//try! channel.close().wait()

//print("[BNCS] Disconnected.")


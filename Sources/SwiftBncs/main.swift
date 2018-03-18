import NIO
import SwiftBncsLib
import SwiftBncsNIO
import Foundation

class BattleNetHandler: ChannelInboundHandler {
    public typealias InboundIn = BncsMessage
    public typealias OutboundOut = ByteBuffer

    var incomingBuffer = [UInt8]()

    let clientToken = arc4random_uniform(UInt32.max)
    var serverToken: UInt32 = 0

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
                serverToken = consumer.readUInt32()
                let udpValue    = consumer.readUInt32()
                let mpqFiletime = consumer.readUInt64()
                let mpqFilename = consumer.readNullTerminatedString()
                let challenge   = consumer.readNullTerminatedString()
                print("[BNCS] Auth challenge received. Login type \(loginType), MPQ \(mpqFilename) (\(mpqFiletime)), challenge: \(challenge).")

                let mpqFileNumber = Int(mpqFilename.cString(using: .ascii)![9] - 0x30)

                do {
                    let checkRevisionResults = try CheckRevision.hash(mpqFileNumber: mpqFileNumber, challenge: challenge, files: [
                        "/Users/lafrance/dev/SwiftBncsLib/extern/hashfiles/D2DV/Game.exe"
                    ])

                    var composer = BncsMessageComposer()
                    composer.write(300 as UInt32) // client token
                    composer.write(checkRevisionResults.version)
                    composer.write(checkRevisionResults.hash)
                    composer.write(1 as UInt32) // keys
                    composer.write(0 as UInt32) // spawn

                    let hash = CdKeyDecode(cdkey: "").hashForAuthCheck(clientToken: 300, serverToken: serverToken)
                    composer.write(hash)

                    composer.write(checkRevisionResults.info)
                    composer.write("SwiftBot")
                    print("[BNCS] Sending auth check...")
                    let authCheckMessage = composer.build(messageIdentifier: BncsMessageIdentifier.AuthCheck)
                    let _ = authCheckMessage.writeToChannel(ctx.channel)
                } catch (let error) {
                    print("Error calculating CheckRevision(): \(error)")
                }

            case .AuthCheck:
                let authCheckResult = consumer.readUInt32()
                if authCheckResult == 0 {
                    print("[BNCS] Auth check passed! Logging in..")

                    let passwordHash = "".data(using: .ascii)!.doubleXsha1(clientToken: clientToken, serverToken: serverToken)
                    var composer = BncsMessageComposer()
                    composer.write(clientToken)
                    composer.write(serverToken)
                    composer.write(passwordHash)
                    composer.write("") // username
                    let loginResponseMessage = composer.build(messageIdentifier: BncsMessageIdentifier.LoginResponse2)
                    let _ = loginResponseMessage.writeToChannel(ctx.channel)

                } else {
                    print("[BNCS] Auth check failed. \(authCheckResult)")
                }

            case .RequiredWork:
                let mpqFilename = consumer.readNullTerminatedString()
                print("[BNCS] Required work: \(mpqFilename)")

            case .LoginResponse2:
                let status = consumer.readUInt32()
                switch status {
                    case 0:
                        print("[BNCS] Login successful! Entering chat.")

                        var enterChatComposer = BncsMessageComposer()
                        enterChatComposer.write("")
                        enterChatComposer.write("")
                        let _ = enterChatComposer.build(messageIdentifier: .EnterChat).writeToChannel(ctx.channel)

                        var joinChannelComposer = BncsMessageComposer()
                        joinChannelComposer.write(1 as UInt32) // first join -- contrary to bnet docs, 1 is used by D2 as well
                        joinChannelComposer.write("Diablo II") // channel name
                        let _ = joinChannelComposer.build(messageIdentifier: .JoinChannel).writeToChannel(ctx.channel)

                        var chatCommandComposer = BncsMessageComposer()
                        chatCommandComposer.write("/join Clan BoT")
                        let _ = chatCommandComposer.build(messageIdentifier: .ChatCommand).writeToChannel(ctx.channel)

                    case 1: print("[BNCS] Account does not exist.")
                    case 2: print("[BNCS] Wrong password.")
                    case 6: print("[BNCS] Account does closed.")
                    default: print("[BNCS] Unknown login response code: \(status).")
                }

            case .EnterChat:
                let uniqueUsername = consumer.readNullTerminatedString()
                let statstring = consumer.readNullTerminatedString()
                let accountName = consumer.readNullTerminatedString()
                print("[BNCS] Entered chat with unique username '\(uniqueUsername)', statstring '\(statstring)', account name '\(accountName)'.")

            case .ChatEvent:
                let eventId = BncsChatEvent(rawValue: consumer.readUInt32())
                let userFlags = consumer.readUInt32()
                let ping = consumer.readUInt32()
                let _ = consumer.readUInt32() // defunct, ip address
                let _ = consumer.readUInt32() // defunct, account number
                let _ = consumer.readUInt32() // defunct, registration authority
                let username = consumer.readNullTerminatedString()
                let text = consumer.readNullTerminatedString()

                print("ChatEvent \(eventId), flags \(userFlags), ping \(ping), username \(username), text \(text)")

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
        channel.pipeline.add(handler: SwiftBncsNIO.ByteBufferToBncsMessageDecoder()).then { v in
            channel.pipeline.add(handler: BattleNetHandler())
        }
    }
defer {
    try! group.syncShutdownGracefully()

}

let channel = try bootstrap.connect(host: "useast.battle.net", port: 6112).wait()

try channel.closeFuture.wait()



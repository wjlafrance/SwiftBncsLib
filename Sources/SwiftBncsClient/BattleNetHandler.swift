import NIO
import Foundation
import SwiftBncsLib

class BattleNetHandler: ChannelInboundHandler {

    public typealias InboundIn = BncsMessage
    public typealias OutboundOut = ByteBuffer

    enum BattleNetConnectionStatus {
        case connecting
        case socketOpened
        case authorizing
        case loggingIn
        case connected(username: String, statstring: String, account: String)
        case disconnecting
        case disconnected(error: Error?)
    }

    var netChannel: Channel!
    var chatChannel = ChatChannel(name: "The Void")

    private var state: BattleNetConnectionStatus = .disconnected(error: nil) {
        didSet {
            switch state {
                case .connecting:
                    print("[BNCS] Connecting...")

                case .socketOpened:
                    print("[BNCS] Connected to \(netChannel.remoteAddress!).")
                    sendProtocolByteAndAuthInfo()

                case .authorizing:
                    print("[BNCS] Authorizing...")

                case .loggingIn:
                    print("[BNCS] Logging in...")

                case .disconnecting:
                    print("[BNCS] Disconnecting..")
                    let _ = netChannel.close(mode: .all)

                case let .connected(username, _, _):
                    print("[BNCS] Connected to Battle.net as \(username)!")

                case let .disconnected(error) where error != nil:
                    print("[BNCS] Disconnected with error: \(error.debugDescription).")

                case .disconnected:
                    print("[BNCS] Disconnected.")
            }
        }
    }

    let clientToken = arc4random_uniform(UInt32.max)
    var serverToken: UInt32 = 0

    // MARK - ChannelInboundHandler compliance

    /// Called when the `Channel` has successfully registered with its `EventLoop` to handle I/O.
    public func channelRegistered(ctx: ChannelHandlerContext) {
        netChannel = ctx.channel

        ctx.fireChannelRegistered()

        state = .connecting
    }

    /// Called when the `Channel` has become active, and is able to send and receive data.
    public func channelActive(ctx: ChannelHandlerContext) {
        ctx.fireChannelActive()

        state = .socketOpened
    }

    /// Called when the `Channel` has become inactive and is no longer able to send and receive data`.
    public func channelInactive(ctx: ChannelHandlerContext) {
        ctx.fireChannelInactive()

        state = .disconnected(error: nil)
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let message = self.unwrapInboundIn(data)

        processMessage(message)
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        state = .disconnected(error: error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }

    /// MARK -

    func sendMessage(_ message: BncsMessage) {
        var buffer = netChannel.allocator.buffer(capacity: message.data.count)
        buffer.write(bytes: message.data.arrayOfBytes())
        netChannel.writeAndFlush(buffer, promise: nil)
    }

    func monitorDefunctValues<T: Comparable>(value: T, expected: T, description: String) {
        if value != expected {
            print("[BNCS] Unexpected value in defunct field. Description: \(description), value: \(value).")
        }
    }

    func sendProtocolByteAndAuthInfo() {
        state = .authorizing

        var protocolByteBuffer = netChannel.allocator.buffer(capacity: 1)
        protocolByteBuffer.write(bytes: [1])
        let _ = netChannel.writeAndFlush(protocolByteBuffer)

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
        sendMessage(composer.build(messageIdentifier: BncsMessageIdentifier.AuthInfo))
    }

    func processMessage(_ message: BncsMessage) {
        var consumer = BncsMessageConsumer(message: message)

        switch consumer.message.identifier {
            case .Null:
                sendMessage(BncsMessageComposer().build(messageIdentifier: .Null))

            case .Ping:
                let cookie = consumer.readUInt32()
                var composer = BncsMessageComposer()
                composer.write(cookie)
                sendMessage(composer.build(messageIdentifier: .Ping))

            case .AuthInfo:
                print("[BNCS] Received auth challenge.")
                let loginType   = consumer.readUInt32()
                serverToken     = consumer.readUInt32()
                let _           = consumer.readUInt32() // UDP token
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
                    composer.write(clientToken) // client token
                    composer.write(checkRevisionResults.version)
                    composer.write(checkRevisionResults.hash)
                    composer.write(1 as UInt32) // keys
                    composer.write(0 as UInt32) // spawn

                    let hash = try! CdkeyDecodeAlpha26(cdkey: BotConfig.cdkey).hashForAuthCheck(clientToken: clientToken, serverToken: serverToken)
                    composer.write(hash)

                    composer.write(checkRevisionResults.info)
                    composer.write("SwiftBot")
                    print("[BNCS] Sending auth check...")
                    sendMessage(composer.build(messageIdentifier: BncsMessageIdentifier.AuthCheck))
                } catch (let error) {
                    print("Error calculating CheckRevision(): \(error)")
                }

            case .AuthCheck:
                let authCheckResult = consumer.readUInt32()
                if authCheckResult == 0 {
                    print("[BNCS] Auth check passed! Logging in..")

                    state = .loggingIn

                    let passwordHash = BotConfig.password.data(using: .ascii)!.doubleXsha1(clientToken: clientToken, serverToken: serverToken)
                    var composer = BncsMessageComposer()
                    composer.write(clientToken)
                    composer.write(serverToken)
                    composer.write(passwordHash)
                    composer.write(BotConfig.username) // username
                    sendMessage(composer.build(messageIdentifier: BncsMessageIdentifier.LogonResponse2))

                } else {
                    print("[BNCS] Auth check failed. \(authCheckResult)")
                    state = .disconnecting
                }

            case .RequiredWork:
                let mpqFilename = consumer.readNullTerminatedString()
                print("[BNCS] Required work: \(mpqFilename)")

            case .LogonResponse2:
                let rawStatus = consumer.readUInt32()
                guard let status = BncsLogonResponse2Status(rawValue: rawStatus) else {
                    print("[BNCS] Illegal logon response: \(rawStatus).")
                    state = .disconnecting
                    return
                }

                switch status {
                    case .success:
                        print("[BNCS] Login successful! Entering chat.")

                        var enterChatComposer = BncsMessageComposer()
                        enterChatComposer.write("")
                        enterChatComposer.write("")
                        sendMessage(enterChatComposer.build(messageIdentifier: .EnterChat))

                        var joinChannelComposer = BncsMessageComposer()
                        joinChannelComposer.write(1 as UInt32) // first join -- contrary to bnet docs, 1 is used by D2 as well
                        joinChannelComposer.write("Diablo II") // channel name
                        sendMessage(joinChannelComposer.build(messageIdentifier: .JoinChannel))

                        var chatCommandComposer = BncsMessageComposer()
                        chatCommandComposer.write("/join \(BotConfig.homeChannel)")
                        sendMessage(chatCommandComposer.build(messageIdentifier: .ChatCommand))

                    default:
                        print("[BNCS] Logon failed: \(status).")
                        state = .disconnecting
            }

            case .EnterChat:
                let uniqueUsername = consumer.readNullTerminatedString()
                let statstring = consumer.readNullTerminatedString()
                let account = consumer.readNullTerminatedString()

                state = .connected(username: uniqueUsername, statstring: statstring, account: account)

            case .ChatEvent:
                let rawEventId = consumer.readUInt32()
                let flags = consumer.readUInt32()
                let ping = consumer.readUInt32()
                monitorDefunctValues(value: consumer.readUInt32(), expected: 0, description: "SID_CHATEVENT field 3, IP address")
                monitorDefunctValues(value: consumer.readUInt32(), expected: 0xBAADF00D, description: "SID_CHATEVENT field 4, account number")
                monitorDefunctValues(value: consumer.readUInt32(), expected: 0xBAADF00D, description: "SID_CHATEVENT field 5, registration authority")
                let username = consumer.readNullTerminatedString()
                let text = consumer.readNullTerminatedString()

                guard let eventId = BncsChatEventIdentifier(rawValue: rawEventId) else {
                    print("[BNCS] Unrecognized chat event ID \(rawEventId). Username: \(username), text: \(text), flags: \(flags), ping: \(ping).")
                    return
                }

                chatChannel.processChatEvent(BncsChatEvent(
                    identifier: eventId,
                    username: username,
                    text: text,
                    flags: flags,
                    ping: ping
                ))

            default:
                print("No parser for this packet!\n\(consumer)")
        }
    }
}


import NIO
import Dispatch
import SwiftBncsLib
import Foundation

class BnlsHandler: ChannelInboundHandler {
    public typealias InboundIn = BnlsMessage
    public typealias OutboundOut = ByteBuffer

    // All access to channels is guarded by channelsSyncQueue.
    private let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
    private var channels: [ObjectIdentifier: Channel] = [:]

    func sendMessage(_ message: BnlsMessage, toChannel netChannel: Channel) {
        var buffer = netChannel.allocator.buffer(capacity: message.data.count)
        buffer.write(bytes: message.data.arrayOfBytes())
        netChannel.writeAndFlush(buffer, promise: nil)
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let id = ObjectIdentifier(ctx.channel)
        let message = self.unwrapInboundIn(data)
        var messageReader = BnlsMessageConsumer(message: message)

        switch message.identifier {
            case .CdKeyEx:
                let cookie = messageReader.readUInt32()
                let keysCount = messageReader.readUInt8()
                let flags = CdKeyExFlags(rawValue: messageReader.readUInt32())

                guard flags.contains(.sameSessionKey) else {
                    print("[BNLS] [\(id)] Received BNLS_CDKEYEX with unsupported flags. Ignoring.")
                    return
                }

                guard !flags.contains(.multiServerSessionKeys) && !flags.contains(.oldStyleResponses) else {
                    print("[BNLS] [\(id)] Received BNLS_CDKEYEX with unsupported flags. Ignoring.")
                    return
                }

                print("[BNLS] [\(id)] Received BNLS_CDKEY_EX.")

                let serverToken = messageReader.readUInt32()
                let clientToken: UInt32
                if flags.contains(.givenSessionKey) {
                    clientToken = messageReader.readUInt32()
                } else {
                    clientToken = arc4random_uniform(UInt32.max)
                }

                var bitmask = 0 as UInt32
                var successfulHashCount = 0 as UInt8
                var hashedKeys = [Data]()
                for index in 0..<keysCount {
                    let key = messageReader.readNullTerminatedString()
                    do {
                        hashedKeys.append(try CdkeyDecodeAlpha26(cdkey: key).hashForAuthCheck(clientToken: clientToken, serverToken: serverToken))
                        bitmask |= (1 << index) // successful key hash
                        successfulHashCount += 1
                    } catch (let error) {
                        print("[BNLS] Error hashing key '\(key)': \(error)")
                    }
                }

                var composer = BnlsMessageComposer()
                composer.write(cookie)
                composer.write(keysCount)
                composer.write(successfulHashCount)
                composer.write(bitmask)
                for x in hashedKeys {
                    composer.write(clientToken)
                    composer.write(x)
                }

                sendMessage(composer.build(messageIdentifier: .CdKeyEx), toChannel: ctx.channel)

            case .Authorize:
                let botname = messageReader.readNullTerminatedString()
                print("[BNLS] Received BNLS_AUTHORIZE for '\(botname)'.")

                var composer = BnlsMessageComposer()
                composer.write(0xDEADBEEF as UInt32) // server code

                sendMessage(composer.build(messageIdentifier: .Authorize), toChannel: ctx.channel)

            case .AuthorizeProof:
                let _ = messageReader.readUInt32() // checksum
                print("[BNLS] [\(id)] Received BNLS_AUTHORIZEPROOF.")

                var composer = BnlsMessageComposer()
                composer.write(0 as UInt32) // authorized

                sendMessage(composer.build(messageIdentifier: .AuthorizeProof), toChannel: ctx.channel)

            case .RequestVersionByte:
                guard let product = BnlsProductIdentifier(rawValue: messageReader.readUInt32()) else {
                    print("[BNLS] [\(id)] Requested version byte invalid product.")

                    var composer = BnlsMessageComposer()
                    composer.write(0 as UInt32) // invalid product

                    sendMessage(composer.build(messageIdentifier: .RequestVersionByte), toChannel: ctx.channel)
                    return
                }

                print("[BNLS] [\(id)] Requested version byte for \(product).")

                var composer = BnlsMessageComposer()
                composer.write(product.rawValue)
                composer.write(product.versionByte)

                sendMessage(composer.build(messageIdentifier: .RequestVersionByte), toChannel: ctx.channel)

            case .VersionCheckEx2:
                let productId = messageReader.readUInt32()
                let flags = messageReader.readUInt32()
                let cookie = messageReader.readUInt32()
                let filetime = messageReader.readUInt64()
                let filename = messageReader.readNullTerminatedString()
                let challenge = messageReader.readNullTerminatedString()

                func sendFailure() {
                    var composer = BnlsMessageComposer()
                    composer.write(0 as UInt32) // failure
                    composer.write(cookie)
                    sendMessage(composer.build(messageIdentifier: .VersionCheckEx2), toChannel: ctx.channel)
                }

                guard let product = BnlsProductIdentifier(rawValue: productId) else {
                    print("[BNLS] [\(id)] Requested version check invalid product.")
                    sendFailure()
                    return
                }

                let mpqFileNumber = CheckRevision.numberForMpqFilename(filename)

                do {
                    let checkRevisionResults = try CheckRevision.hash(mpqFileNumber: mpqFileNumber, challenge: challenge, files: product.hashFiles)

                    var composer = BnlsMessageComposer()
                    composer.write(1 as UInt32) // success
                    composer.write(checkRevisionResults.version)
                    composer.write(checkRevisionResults.hash)
                    composer.write(checkRevisionResults.info)
                    composer.write(cookie)
                    composer.write(product.versionByte)
                    sendMessage(composer.build(messageIdentifier: .VersionCheckEx2), toChannel: ctx.channel)
                } catch (let error) {
                    print("[BNLS] [\(id)] CheckRevision error! \(error)")
                    sendFailure()
                }

            default:
                print("[BNLS] [\(id)] Unrecognized packet. Ignoring. \(message.debugDescription)")
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("[BNLS] Error caught: \(error)")

        ctx.close(promise: nil)
    }

    public func channelActive(ctx: ChannelHandlerContext) {
        let id = ObjectIdentifier(ctx.channel)
        let remoteAddress = ctx.remoteAddress!

        channelsSyncQueue.async {
            print("[BNLS] [\(id)] Client connected from \(remoteAddress).")

            self.channels[ObjectIdentifier(channel)] = channel
        }
    }

    public func channelInactive(ctx: ChannelHandlerContext) {
        let id = ObjectIdentifier(ctx.channel)

        channelsSyncQueue.async {
            print("[BNLS] Client disconnected. Identifier: \(id).")

            self.channels.removeValue(forKey: id)
        }
    }

}


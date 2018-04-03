import NIO
import SwiftBncsLib
import SwiftBncsNIO
import Foundation

/*
 useast  199.108.55.54-62
 w3 beta 37.244.26.200
*/
enum BotConfig {
    static let server = ""
    static let username = ""
    static let password = ""
    static let cdkey = ""
    static let homeChannel = ""
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

let channel = try bootstrap.connect(host: BotConfig.server, port: 6112).wait()
try channel.closeFuture.wait()

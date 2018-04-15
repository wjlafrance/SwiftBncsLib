import Foundation
import NIO
import SwiftBncsLib
import SwiftBncsNIO

/*
 useast  199.108.55.54-62
 w3 beta 37.244.26.200
 war3-ptr.classic.blizzard.com
 */
struct BotInstanceConfiguration {
    let name: String
    let server: String
    let username: String
    let password: String
    let cdkey: String?
    let cdkey2: String?
    let homeChannel: String
    let product: BncsProductIdentifier
}

let config = BotInstanceConfiguration(
    name: "<#T##String#>",
    server: "<#T##String#>",
    username: "<#T##String#>",
    password: "<#T##String#>",
    cdkey: "<#T##String#>",
    cdkey2: "<#T##String#>",
    homeChannel: "<#T##String#>",
    product: .Diablo2)

class BotInstance {

    let channel: Channel!

    let battleNetHandler: BattleNetHandler

    init(configuration: BotInstanceConfiguration = config, eventLoopGroup: EventLoopGroup = AppContext.networkEventLoopGroup) {
        let battleNetHandler = BattleNetHandler(configuration: config)
        self.battleNetHandler = battleNetHandler

        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1) // Enable SO_REUSEADDR.
            .channelInitializer { channel in
                channel.pipeline.add(handler: SwiftBncsNIO.ByteBufferToBncsMessageDecoder()).then { v in
                    channel.pipeline.add(handler: battleNetHandler)
                }
            }

        channel = try! bootstrap.connect(host: config.server, port: 6112).wait()
    }

}

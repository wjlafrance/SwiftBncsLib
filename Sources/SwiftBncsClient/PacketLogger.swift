//
//  PacketLogger.swift
//  CNIOAtomics
//
//  Created by William LaFrance on 4/14/18.
//

import Foundation

enum PacketLogger {

    enum Direction {
        case send
        case recv

        var logMarker: String {
            switch self {
                case .send: return "C>S"
                case .recv: return "S>C"
            }
        }
    }

    static func log(config: BotInstanceConfiguration, direction: Direction, data: Data) {
        print("[\(config.name)] \(direction.logMarker)\n\(data.hexDescription)")
    }

}


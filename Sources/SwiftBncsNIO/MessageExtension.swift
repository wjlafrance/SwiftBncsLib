//
//  MessageExtension.swift
//  SwiftBncsLibPackageDescription
//
//  Created by William LaFrance on 3/9/18.
//

import SwiftBncsLib
import NIO

public extension SwiftBncsLib.Message {

    public func writeToChannel(_ channel: Channel) -> EventLoopFuture<Void> {
        var buffer = channel.allocator.buffer(capacity: self.data.count)
        buffer.write(bytes: self.data.arrayOfBytes())
        return channel.writeAndFlush(buffer)
    }

}

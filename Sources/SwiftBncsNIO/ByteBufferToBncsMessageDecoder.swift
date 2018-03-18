import NIO
import SwiftBncsLib
import Foundation

public class ByteBufferToBncsMessageDecoder: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = BncsMessage

    public var cumulationBuffer: ByteBuffer?

    public init() {}

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

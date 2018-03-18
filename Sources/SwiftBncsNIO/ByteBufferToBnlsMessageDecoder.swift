import NIO
import SwiftBncsLib
import Foundation

public class ByteBufferToBnlsMessageDecoder: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = BnlsMessage

    public var cumulationBuffer: ByteBuffer?

    public init() {}

    public func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard buffer.readableBytes >= 2 else {
            return .needMoreData
        }

        let length = buffer.withUnsafeReadableBytes { urbp in
            return Int(urbp[0]) | Int(urbp[1] >> 8)
        }

        guard buffer.readableBytes >= length else {
            return .needMoreData
        }

        do {
            let message = try BnlsMessage(data: Data(bytes: buffer.readBytes(length: length)!))
            ctx.fireChannelRead(self.wrapInboundOut(message))
        } catch (let error) {
            print("Error in BncsMessageCodec: \(error)")
        }

        return .continue
    }
}

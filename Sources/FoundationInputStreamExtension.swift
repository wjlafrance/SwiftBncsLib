import Foundation

public extension InputStream {

    public func readData(maxLength: Int) -> Foundation.Data? {
        var bytes = [UInt8](repeating: 0, count: maxLength)

        let bytesRead = read(&bytes, maxLength: maxLength)

        guard bytesRead >= 0 else {
            return nil
        }

        let data = Foundation.Data(bytes: bytes)

        let range = Range<Data.Index>(uncheckedBounds: (lower: 0, upper: bytesRead))

        return data.subdata(in: range)
    }

    internal func readRawMessage(maxLength: Int) -> RawMessageConsumer? {
        return readData(maxLength: maxLength).map { RawMessageConsumer(message: $0) }
    }

}

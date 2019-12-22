import Foundation

extension Foundation.Data {

    func getByte(at index: Int) -> UInt8 {
        let data: UInt8 = self.subdata(in: index ..< (index + 1)).withUnsafeBytes { rawPointer in
            rawPointer.bindMemory(to: UInt8.self).baseAddress!.pointee
        }

        return data
    }

    public func arrayOfBytes() -> [UInt8] {
        let count = self.count / MemoryLayout<UInt8>.size
        var bytesArray = [UInt8](repeating: 0, count: count)
        copyBytes(to: &bytesArray, count: count * MemoryLayout<UInt8>.stride)
        return bytesArray
    }

    func subdataFromIndex(_ index: Data.Index) -> Data {
        let range = Range<Data.Index>(uncheckedBounds: (lower: index, upper: count))
        return subdata(in: range)
    }

    func subdataFromIndex(_ index: Data.Index, length: Data.Index) -> Data {
        let range = Range<Data.Index>(uncheckedBounds: (lower: index, upper: index + length))
        return subdata(in: range)
    }

    public var hexDescription: String {
        let contents = arrayOfBytes()
        let lineLength = 16
        return ((0...(contents.count / lineLength)).map { lineIndex in
            let hexPrintout = ((0..<lineLength).flatMap { columnIndex in
                let arrayIndex = lineIndex * 16 + columnIndex
                if arrayIndex >= contents.count { return "   " }
                return String(format: "%02X ", contents[arrayIndex])
            }).joined(separator: "")
            let charPrintout = ((0..<lineLength).flatMap { columnIndex in
                let arrayIndex = lineIndex * 16 + columnIndex
                if arrayIndex >= contents.count { return " " }
                if isprint(Int32(contents[arrayIndex])) == 0 { return "." }
                return String(format: "%c", contents[arrayIndex])
            }).joined(separator: "")

            return String(format: "%04X: ", lineIndex * lineLength) + "\(hexPrintout)   \(charPrintout)"
        }).joined(separator: "\n")
    }

}

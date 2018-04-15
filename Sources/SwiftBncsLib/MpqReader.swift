import Foundation

public struct MpqReader {

    private enum Crypto {
        static let MPQ_HASH_FILE_KEY = 0x300 as UInt32
        static let MPQ_HASH_KEY2_MIX = 0x400 as UInt32

        static let MPQ_KEY_HASH_TABLE  = 0xC3AF3770 as UInt32 // Obtained by HashString("(hash table)", MPQ_HASH_FILE_KEY)
        static let MPQ_KEY_BLOCK_TABLE = 0xEC83B3A3 as UInt32

        static let StormBuffer: [UInt32] = {
            var stormBuffer = [UInt32](repeating: 0, count: 0x500)
            var seed = 0x00100001 as UInt32
            for i in 0..<0x100 {
                for j in stride(from: i, to: i + 0x500, by: 0x100) {
                    seed = (seed * 125 + 3) % 0x2AAAAB
                    let temp1 = (seed & 0xFFFF) << 0x10
                    seed = (seed * 125 + 3) % 0x2AAAAB
                    let temp2 = (seed & 0xFFFF)
                    stormBuffer[j] = temp1|temp2
                }
            }
            return stormBuffer
        }()

        static func decryptMpqBlock(data: Data, length: Int, key: UInt32) -> Data {
            var consumer = RawMessageConsumer(message: data)
            var composer = RawMessageComposer()

            var key1 = key
            var key2 = 0xEEEEEEEE as UInt32

            let length = length >> 2 // length is expressed in bytes, but decrypting in DWORDs
            for _ in 0..<length {
                key2 = key2 &+ Crypto.StormBuffer[Int(Crypto.MPQ_HASH_KEY2_MIX &+ (key1 & 0xFF))]

                let decrypted = consumer.readUInt32() ^ (key1 &+ key2)
                composer.write(decrypted)

                key1 = ((~key1 &<< 0x15) + 0x11111111) | (key1 >> 0x0B)
                key2 = decrypted &+ key2 &+ (key2 &<< 5) &+ 3
            }

            return composer.build()
        }

        enum HashStringMode: Int {
            case tableOffset = 0
            case nameA       = 1
            case nameB       = 2
            case fileKey     = 3
        }
        static func hashString(_ x: String, mode: HashStringMode) -> Int {
            var seed1 = 0x7FED7FED as UInt32
            var seed2 = 0xEEEEEEEE as UInt32

            for x in x.uppercased().bytes {
                seed1 = UInt32(Crypto.StormBuffer[mode.rawValue * 0x100 + Int(x)]) ^ (seed1 &+ seed2)
                seed2 = UInt32(x) + seed1 &+ seed2 &+ (seed2 &<< 5) + 3
            }

            return Int(seed1)
        }
    }

    private struct TMPQHeader: CustomDebugStringConvertible {
        let identifier: UInt32
        let headerSize: UInt32
        let archiveSize: UInt32
        let formatVersion: UInt16
        let blockSize: UInt16
        let hashTablePosition: UInt32
        let blockTablePosition: UInt32
        let hashTableSize: UInt32
        let blockTableSize: UInt32

        var debugDescription: String {
            return String(format: "TMPQHeader<format: \(formatVersion + 1), archiveSize: \(archiveSize), hashTableSize: \(hashTableSize), blockTableSize: \(blockTableSize), hashTablePosition: 0x%X, blockTablePosition: 0x%X>", hashTablePosition, blockTablePosition)
        }
    }

    private struct TMPQHash: CustomDebugStringConvertible {
        let nameA: UInt32
        let nameB: UInt32
        let locale: UInt16
        let platform: UInt16
        let blockIndex: UInt32

        var debugDescription: String {
            return "TMPQHash<name: \(nameA) \(nameB), locale: \(locale), platform: \(platform), blockIndex: \(blockIndex)>"
        }
    }

    private struct TMPQBlock: CustomDebugStringConvertible {
        let filePosition: UInt32
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let flags: TMPQBlockFlags

        var debugDescription: String {
            return "TMPQBlock<pos: \(filePosition), size: \(uncompressedSize), \(flags)>"
        }
    }

    private struct TMPQBlockFlags: OptionSet, CustomDebugStringConvertible {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let implode      = TMPQBlockFlags(rawValue: 0x00000100)
        public static let compress     = TMPQBlockFlags(rawValue: 0x00000200)
        public static let encrypted    = TMPQBlockFlags(rawValue: 0x00010000)
        public static let fixKey       = TMPQBlockFlags(rawValue: 0x00020000)
        public static let patchFile    = TMPQBlockFlags(rawValue: 0x00100000)
        public static let singleUnit   = TMPQBlockFlags(rawValue: 0x01000000)
        public static let deleteMarker = TMPQBlockFlags(rawValue: 0x02000000)
        public static let sectorCrc    = TMPQBlockFlags(rawValue: 0x04000000)
        public static let exists       = TMPQBlockFlags(rawValue: 0x80000000)

        var debugDescription: String {
            var flagStrings = [String]()
            if self.contains(.implode)      { flagStrings.append("implode") }
            if self.contains(.compress)     { flagStrings.append("compress") }
            if self.contains(.encrypted)    { flagStrings.append("encrypted") }
            if self.contains(.fixKey)       { flagStrings.append("fixKey") }
            if self.contains(.patchFile)    { flagStrings.append("patchFile") }
            if self.contains(.singleUnit)   { flagStrings.append("singleUnit") }
            if self.contains(.deleteMarker) { flagStrings.append("deleteMarker") }
            if self.contains(.sectorCrc)    { flagStrings.append("sectorCrc") }
            if self.contains(.exists)       { flagStrings.append("exists") }
            return "TMPQBlockFlags<\(flagStrings.joined(separator: ", "))>"
        }
    }

    private let header: TMPQHeader
    private let hashTable: [TMPQHash]
    private let blockTable: [TMPQBlock]

    private var consumer: RawMessageConsumer

    public init?(path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        self.init(data: data)
    }

    public init(data: Data) {
        consumer = RawMessageConsumer(message: data)

        var dwID = consumer.readUInt32()
        while dwID == 0x1B51504D { // MPQ\1B
            print("Encountered TMPQUserData, skipping")
            consumer.readIndex -= 4
            consumer.readIndex += 0x200
            dwID = consumer.readUInt32()
        }

        guard dwID == 0x1A51504D else { // MPQ\1A
            preconditionFailure("Encountered header other than TMPQHeader or TMPQUserData -- bailing")
        }

        header = TMPQHeader(
            identifier: dwID,
            headerSize: consumer.readUInt32(),
            archiveSize: consumer.readUInt32(),
            formatVersion: consumer.readUInt16(),
            blockSize: consumer.readUInt16(),
            hashTablePosition: consumer.readUInt32(),
            blockTablePosition: consumer.readUInt32(),
            hashTableSize: consumer.readUInt32(),
            blockTableSize: consumer.readUInt32())

        print("Parsing MPQ file version \(header)")

        let encryptedHashtable = data.subdataFromIndex(Data.Index(header.hashTablePosition), length: Data.Index(header.hashTableSize) * 16)
        let decryptedHashtable = Crypto.decryptMpqBlock(data: encryptedHashtable, length: Int(header.hashTableSize) * 16, key: Crypto.MPQ_KEY_HASH_TABLE)
        var hashtableConsumer = RawMessageConsumer(message: decryptedHashtable)
        var _hashTable = [TMPQHash]()
        for _ in 0..<header.hashTableSize {
            _hashTable.append(TMPQHash(
                nameA:      hashtableConsumer.readUInt32(),
                nameB:      hashtableConsumer.readUInt32(),
                locale:     hashtableConsumer.readUInt16(),
                platform:   hashtableConsumer.readUInt16(),
                blockIndex: hashtableConsumer.readUInt32()))
        }

        let encryptedBlocktable = data.subdataFromIndex(Data.Index(header.blockTablePosition), length: Data.Index(header.blockTableSize) * 16)
        let decryptedBlocktable = Crypto.decryptMpqBlock(data: encryptedBlocktable, length: Int(header.hashTableSize) * 16, key: Crypto.MPQ_KEY_BLOCK_TABLE)
        var blocktableConsumer = RawMessageConsumer(message: decryptedBlocktable)
        var _blockTable = [TMPQBlock]()
        for _ in 0..<header.blockTableSize {
            _blockTable.append(TMPQBlock(
                filePosition:     blocktableConsumer.readUInt32(),
                compressedSize:   blocktableConsumer.readUInt32(),
                uncompressedSize: blocktableConsumer.readUInt32(),
                flags:            TMPQBlockFlags(rawValue: blocktableConsumer.readUInt32())))
        }

        hashTable = _hashTable
        blockTable = _blockTable
    }

    private func hashTableEntryForFilename(name: String) -> TMPQHash? {
        let offset = Crypto.hashString(name, mode: .tableOffset) & (Int(header.hashTableSize) - 1)
        let nameA = Crypto.hashString(name, mode: .nameA), nameB = Crypto.hashString(name, mode: .nameB)

        for index in offset ..< Int(header.hashTableSize) {
            let entry = hashTable[index]
            if entry.blockIndex == 0xFFFFFFFF {
                return nil
            }
            if entry.nameA == nameA && entry.nameB == nameB {
                return hashTable[index]
            }
        }
        return nil
    }

    public func openFile(name: String) {

        guard let entry = hashTableEntryForFilename(name: name) else {
            print("unable to open file, does not seem to exist: \(name)")
            return
        }

        let block = blockTable[Int(entry.blockIndex)]

        let rawData = consumer.message.subdataFromIndex(Data.Index(block.filePosition), length: Data.Index(block.compressedSize))

//        print("entry ): \(blockTable[Int(entry.blockIndex)])")

    }

}

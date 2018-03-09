//
//  PortableExecutableUtil.swift
//  SwiftBncsLibPackageDescription
//
//  Created by William LaFrance on 3/8/18.
//

// lifted HEAVILY from JBLS

import Foundation

enum PortableExecutableUtil {

    enum PortableExecutableError: Error {
        case invalidSignature
    }

    static let PEStartOffset = 0x3C

    static func getVersion(file: String) throws -> UInt32 {

        let bytes = try Data(contentsOf: URL(fileURLWithPath: file)).arrayOfBytes()

        let peStart = Int(bytes[PEStartOffset]) | Int(bytes[PEStartOffset + 1]) << 8

        let peSignature: UInt32 = {
            var x = UInt32(bytes[peStart])
            x |= UInt32(bytes[peStart + 1]) << 8
            x |= UInt32(bytes[peStart + 2]) << 16
            x |= UInt32(bytes[peStart + 3]) << 24
            return x
        }()

        guard peSignature == 0x00004550 else {
            throw PortableExecutableError.invalidSignature
        }

        let numberOfSections = Int(bytes[peStart + 6]) | Int(bytes[peStart + 7]) << 8

        let ptrOptionalHeader = peStart + 24

        return processOptionalHeader(bytes: bytes, ptrOptionalHeader: ptrOptionalHeader, numberOfSections: numberOfSections)
    }

    static func processOptionalHeader(bytes: [UInt8], ptrOptionalHeader: Int, numberOfSections: Int) -> UInt32 {

        /* PE+ files have the first ("magic") byte set to 0x20b */
        let isPePlus = 0x020b == (UInt16(bytes[ptrOptionalHeader]) | UInt16(bytes[ptrOptionalHeader + 1]) << 8)

        let numberOfRvaAndSizes: Int = {
            var x = Int(bytes[ptrOptionalHeader + (isPePlus ? 108 : 92)])
            x |= Int(bytes[ptrOptionalHeader + (isPePlus ? 109 : 93)]) << 8
            x |= Int(bytes[ptrOptionalHeader + (isPePlus ? 110 : 94)]) << 16
            x |= Int(bytes[ptrOptionalHeader + (isPePlus ? 111 : 95)]) << 24
            return x
        }()

        let ptrSectionTable = ptrOptionalHeader + 96 + (numberOfRvaAndSizes * 8)

        for i in 0..<numberOfSections {
            let ptrSectionBase = ptrSectionTable + i * 40
            let virtualStart: Int = {
                var x = Int(bytes[ptrSectionBase + 12])
                x |= Int(bytes[ptrSectionBase + 13]) << 8
                x |= Int(bytes[ptrSectionBase + 14]) << 16
                x |= Int(bytes[ptrSectionBase + 15]) << 24
                return x
            }()
            let rawStart: Int = {
                var x = Int(bytes[ptrSectionBase + 20])
                x |= Int(bytes[ptrSectionBase + 21]) << 8
                x |= Int(bytes[ptrSectionBase + 22]) << 16
                x |= Int(bytes[ptrSectionBase + 23]) << 24
                return x
            }()
            let rsrcVirtualToRaw = rawStart - virtualStart

            // 0x000000637273722EL
            let sectionType: Int = {
                var x = Int(bytes[ptrSectionBase])
                x |= Int(bytes[ptrSectionBase + 1]) << 8
                x |= Int(bytes[ptrSectionBase + 2]) << 16
                x |= Int(bytes[ptrSectionBase + 3]) << 24
                x |= Int(bytes[ptrSectionBase + 4]) << 32
                x |= Int(bytes[ptrSectionBase + 5]) << 40
                x |= Int(bytes[ptrSectionBase + 6]) << 48
                x |= Int(bytes[ptrSectionBase + 7]) << 56
                return x
            }()

            if sectionType == 0x000000637273722E {
                return processResourceRecord(bytes: bytes, recordOffset: 0, rsrcStart: rawStart, rsrcVirtualToRaw: rsrcVirtualToRaw)
            }

        }

        return 0
    }

    static func processResourceRecord(bytes: [UInt8], recordOffset: Int, rsrcStart: Int, rsrcVirtualToRaw: Int, tree: [Int] = []) -> UInt32 {
        let ptrRecord = rsrcStart + recordOffset

        let numberNameEntries = Int(bytes[ptrRecord + 12]) | Int(bytes[ptrRecord + 13]) >> 8
        let numberIDEntries = Int(bytes[ptrRecord + 14]) | Int(bytes[ptrRecord + 15]) >> 8

        let ptrIDEntriesBase = ptrRecord + 16 + (numberNameEntries * 8)

        for i in 0..<numberIDEntries {
            let ptrEntry = ptrIDEntriesBase + (i * 8)

            let x = processEntry(bytes: bytes, ptrEntry: ptrEntry, rsrcStart: rsrcStart, rsrcVirtualToRaw: rsrcVirtualToRaw, tree: tree)
            if x != 0 {
                return x
            }
        }

        return 0
    }

    static func processEntry(bytes: [UInt8], ptrEntry: Int, rsrcStart: Int, rsrcVirtualToRaw: Int, tree: [Int]) -> UInt32 {
        let thisIdentifier: Int = {
            var x = Int(bytes[ptrEntry])
            x |= Int(bytes[ptrEntry + 1]) << 8
            x |= Int(bytes[ptrEntry + 2]) << 16
            x |= Int(bytes[ptrEntry + 3]) << 24
            return x
        }()
        let nextAddress: Int = {
            var x = Int(bytes[ptrEntry + 4])
            x |= Int(bytes[ptrEntry + 5]) << 8
            x |= Int(bytes[ptrEntry + 6]) << 16
            x |= Int(bytes[ptrEntry + 7]) << 24
            return x
        }()

        var tree = tree
        tree.append(thisIdentifier)

        if nextAddress & 0x80000000 != 0 {
            // branch
            let x = processResourceRecord(bytes: bytes, recordOffset: nextAddress & 0x7FFFFFFF, rsrcStart: rsrcStart, rsrcVirtualToRaw: rsrcVirtualToRaw, tree: tree)
            if x != 0 {
                return x
            }
        } else {
            // leaf
            if tree.first! == 16 { // RT_VERSION

                let rawDataAddress: Int = {
                    var x = Int(bytes[rsrcStart + nextAddress])
                    x |= Int(bytes[rsrcStart + nextAddress + 1]) << 8
                    x |= Int(bytes[rsrcStart + nextAddress + 2]) << 16
                    x |= Int(bytes[rsrcStart + nextAddress + 3]) << 24
                    return x + rsrcVirtualToRaw
                }()
//                let dataSize: Int = {
//                    var x = Int(bytes[rsrcStart + nextAddress + 4])
//                    x |= Int(bytes[rsrcStart + nextAddress + 5]) << 8
//                    x |= Int(bytes[rsrcStart + nextAddress + 6]) << 16
//                    x |= Int(bytes[rsrcStart + nextAddress + 7]) << 24
//                    return x
//                }()

                var version = UInt32(bytes[rawDataAddress + 0x3C])
                version |= UInt32(bytes[rawDataAddress + 0x3E]) << 8
                version |= UInt32(bytes[rawDataAddress + 0x38]) << 16
                version |= UInt32(bytes[rawDataAddress + 0x3A]) << 24
                return version

            }
        }

        return 0
    }

}


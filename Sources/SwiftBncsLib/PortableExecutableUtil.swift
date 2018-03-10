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

        let peSignature = IntUtil.from8to32([
            bytes[peStart],     bytes[peStart + 1],
            bytes[peStart + 2], bytes[peStart + 3]
        ])

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

        let numberOfRvaAndSizes = Int(IntUtil.from8to32([
            bytes[ptrOptionalHeader + (isPePlus ? 108 : 92)], bytes[ptrOptionalHeader + (isPePlus ? 109 : 93)],
            bytes[ptrOptionalHeader + (isPePlus ? 110 : 94)], bytes[ptrOptionalHeader + (isPePlus ? 111 : 95)]
        ]))

        let ptrSectionTable = ptrOptionalHeader + 96 + (numberOfRvaAndSizes * 8)

        for i in 0..<numberOfSections {
            let ptrSectionBase = ptrSectionTable + i * 40
            let virtualStart = Int(IntUtil.from8to32([
                bytes[ptrSectionBase + 12], bytes[ptrSectionBase + 13],
                bytes[ptrSectionBase + 14], bytes[ptrSectionBase + 15]
            ]))
            let rawStart = Int(IntUtil.from8to32([
                bytes[ptrSectionBase + 20], bytes[ptrSectionBase + 21],
                bytes[ptrSectionBase + 22], bytes[ptrSectionBase + 23]
            ]))
            let sectionType = Int(IntUtil.from8to64([
                bytes[ptrSectionBase],     bytes[ptrSectionBase + 1],
                bytes[ptrSectionBase + 2], bytes[ptrSectionBase + 3],
                bytes[ptrSectionBase + 4], bytes[ptrSectionBase + 5],
                bytes[ptrSectionBase + 6], bytes[ptrSectionBase + 7]
            ]))

            let rsrcVirtualToRaw = rawStart - virtualStart

            if sectionType == 0x000000637273722E {
                return processResourceRecord(bytes: bytes, recordOffset: 0, rsrcStart: rawStart, rsrcVirtualToRaw: rsrcVirtualToRaw)
            }

        }

        return 0
    }

    static func processResourceRecord(bytes: [UInt8], recordOffset: Int, rsrcStart: Int, rsrcVirtualToRaw: Int, tree: [Int] = []) -> UInt32 {
        let ptrRecord = rsrcStart + recordOffset

        let numberNameEntries = Int(IntUtil.from8to16([
            bytes[ptrRecord + 12], bytes[ptrRecord + 13]
        ]))
        let numberIDEntries = Int(IntUtil.from8to16([
            bytes[ptrRecord + 14], bytes[ptrRecord + 15]
        ]))

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
        let thisIdentifier = Int(IntUtil.from8to32([
            bytes[ptrEntry],     bytes[ptrEntry + 1],
            bytes[ptrEntry + 2], bytes[ptrEntry + 3]
        ]))
        let nextAddress    = Int(IntUtil.from8to32([
            bytes[ptrEntry + 4], bytes[ptrEntry + 5],
            bytes[ptrEntry + 6], bytes[ptrEntry + 7]
        ]))

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

                let rawDataAddress = Int(IntUtil.from8to32([
                    bytes[rsrcStart + nextAddress],     bytes[rsrcStart + nextAddress + 1],
                    bytes[rsrcStart + nextAddress + 2], bytes[rsrcStart + nextAddress + 3]
                ])) + rsrcVirtualToRaw

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


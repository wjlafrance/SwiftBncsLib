//
//  IntUtil.swift
//  SwiftBncsLibPackageDescription
//
//  Created by William LaFrance on 3/4/18.
//

import Foundation

enum IntUtil {

    static func from8to32(_ x: [UInt8]) -> UInt32 {
        precondition(x.count >= 4)
        assert(x.count == 4)

        let x = x.map { UInt32($0) }

        return x[0] | x[1] << 8 | x[2] << 16 | x[3] << 24
    }

    static func from32to8(_ x: UInt32) -> [UInt8] {
        return [
            UInt8(truncatingIfNeeded: x),
            UInt8(truncatingIfNeeded: x >> 8),
            UInt8(truncatingIfNeeded: x >> 16),
            UInt8(truncatingIfNeeded: x >> 24)
        ]
    }

}

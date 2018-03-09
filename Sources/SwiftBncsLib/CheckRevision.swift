//
//  CheckRevision.swift
//  SwiftBncsLibPackageDescription
//
//  Created by William LaFrance on 3/7/18.
//

import Foundation

enum CheckRevisionError: Error {
    case malformedChallenge
    case fileError
}

enum CheckRevisionOperation: CChar {
    case add      = 0x2B
    case subtract = 0x2D
    case multiply = 0x2A
    case xor      = 0x5E
}

public typealias CheckRevisionResult = (
    version: UInt32,
    hash: UInt32,
    info: String
)

private typealias CheckRevisionEquation = (
    assignIndex: Int,
    leftOperandIndex: Int,
    rightOperandIndex: Int,
    operation: CheckRevisionOperation
)

public enum CheckRevision {

    private static let InitialXorValues: [UInt32] = [ 0xE7F4CB62, 0xF6A14FFC, 0xAA5504AF, 0x871FCDC2, 0x11BF6A18, 0xC57292E6, 0x7927D27E, 0x2FEC8733 ]

    private static func fileInfoString(file: String) throws -> String {
        let attributes = try FileManager.default.attributesOfItem(atPath: file)
        guard let creationDate = attributes[.creationDate] as? Date else {
            throw CheckRevisionError.fileError
        }
        guard let size = attributes[.size] as? Int else {
            throw CheckRevisionError.fileError
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        let timestamp = dateFormatter.string(from: creationDate)

        let filename = URL(fileURLWithPath: file).lastPathComponent

        return "\(filename) \(timestamp) \(size)"
    }

    public static func hash(mpqFileNumber: Int, challenge: String, files: [String]) throws -> CheckRevisionResult {

        func valueIndex(character: CChar) -> Int? {
            switch character {
                case 0x41: return 0
                case 0x42: return 1
                case 0x43: return 2
                case 0x53: return 3
                default: return nil
            }
        }

        var values: [UInt64] = [0, 0, 0, 0]
        var equations = [CheckRevisionEquation]()

        for challengeToken in challenge.split(separator: " ") {

            if !challengeToken.contains("=") {
                continue;
            }

            let challengeTokenChars = challengeToken.cString(using: .ascii)!

            if nil != challengeToken.range(of: "[ABC]=\\d+", options: .regularExpression) {
                // A=2059673008

                guard let index = valueIndex(character: challengeTokenChars[0]) else {
                    throw CheckRevisionError.malformedChallenge
                }
                let value = UInt64(challengeToken.split(separator: "=")[1])!
                values[index] = value

            } else if nil != challengeToken.range(of: "[ABC]=[ABC][+-\\^][ABCS]", options: .regularExpression) {
                //A=A-S

                guard let assignIndex = valueIndex(character: challengeTokenChars[0]),
                    let leftOperandIndex = valueIndex(character: challengeTokenChars[2]),
                    let operation = CheckRevisionOperation(rawValue: challengeTokenChars[3]),
                    let rightOperandIndex = valueIndex(character: challengeTokenChars[4]) else {

                    throw CheckRevisionError.malformedChallenge
                }

                equations.append((
                    assignIndex: assignIndex,
                    leftOperandIndex: leftOperandIndex,
                    rightOperandIndex: rightOperandIndex,
                    operation: operation
                ))

            } else {
                throw CheckRevisionError.malformedChallenge
            }
        }

        values[0] ^= UInt64(InitialXorValues[mpqFileNumber])

        for filePath in files {

            guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                throw CheckRevisionError.fileError
            }

            var fill: UInt8 = 0xFF
            var fileBytes = fileData.arrayOfBytes()
            while fileBytes.count % 1024 != 0 {
                fileBytes.append(fill)
                fill = fill &- 1
            }

            for index in stride(from: 0, to: fileBytes.count, by: 4) {
                values[3]  = UInt64(fileBytes[index])
                values[3] |= UInt64(fileBytes[index + 1]) << 8
                values[3] |= UInt64(fileBytes[index + 2]) << 16
                values[3] |= UInt64(fileBytes[index + 3]) << 24

                for (assign, lhs, rhs, operation) in equations {
                    switch operation {
                        case .add:      values[assign] = values[lhs] &+ values[rhs]
                        case .subtract: values[assign] = values[lhs] &- values[rhs]
                        case .multiply: values[assign] = values[lhs] &* values[rhs]
                        case .xor:      values[assign] = values[lhs] ^  values[rhs]
                    }
                }
            }

        }

        return (
            version: try PortableExecutableUtil.getVersion(file: files[0]),
            hash: UInt32(truncatingIfNeeded: values[2]),
            info: try fileInfoString(file: files[0])
        )
    }
}


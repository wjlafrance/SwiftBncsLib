import Foundation

public enum BnlsMessageIdentifier: UInt8 {
    case CdKeyEx            = 0x0C
    case Authorize          = 0x0E
    case AuthorizeProof     = 0x0F
    case RequestVersionByte = 0x10
    case VersionCheckEx2    = 0x1A
    case Unknown            = 0xFF
}

public enum BnlsProductIdentifier: UInt32 {
    case Starcraft          = 1
    case StarcraftExpansion = 2
    case Warcraft2          = 3
    case Diablo2            = 4
    case Diablo2Expansion   = 5
    case StarcraftJapan     = 6
    case Warcraft3          = 7
    case Warcraft3Expansion = 8
    case Diablo             = 9
    case DiabloShareware    = 10
    case StarcraftShareware = 11
    case Warcraft3Demo      = 12

    public var versionByte: UInt32 {
        let x: [BnlsProductIdentifier: UInt32] = [
            .Starcraft:          0,
            .StarcraftExpansion: 0,
            .Warcraft2:          0,
            .Diablo2:            0x0E,
            .Diablo2Expansion:   0x0E,
            .StarcraftJapan:     0,
            .Warcraft3:          0,
            .Warcraft3Expansion: 0,
            .Diablo:             0,
            .DiabloShareware:    0,
            .StarcraftShareware: 0,
            .Warcraft3Demo:      0
        ]

        return x[self]!
    }

    private var bncsProduct: BncsProductIdentifier {
        let x: [BnlsProductIdentifier: BncsProductIdentifier] = [
            .Starcraft:          .Starcraft,
            .StarcraftExpansion: .StarcraftExpansion,
            .Warcraft2:          .Warcraft2,
            .Diablo2:            .Diablo2,
            .Diablo2Expansion:   .Diablo2Expansion,
            .StarcraftJapan:     .StarcraftJapan,
            .Warcraft3:          .Warcraft3,
            .Warcraft3Expansion: .Warcraft3Expansion,
            .Diablo:             .Diablo,
            .DiabloShareware:    .DiabloShareware,
            .StarcraftShareware: .StarcraftShareware,
            .Warcraft3Demo:      .Warcraft3Demo
        ]

        return x[self]!
    }

    public var hashFiles: [String] {
        let x: [BnlsProductIdentifier: [String]] = [
            .Starcraft:          [],
            .StarcraftExpansion: [],
            .Warcraft2:          [],
            .Diablo2:            ["Game.exe"],
            .Diablo2Expansion:   ["Game.exe"],
            .StarcraftJapan:     [],
            .Warcraft3:          [],
            .Warcraft3Expansion: [],
            .Diablo:             [],
            .DiabloShareware:    [],
            .StarcraftShareware: [],
            .Warcraft3Demo:      []
        ]

        let productStringRepresentation = String(FourCC(rawValue: self.bncsProduct.rawValue).stringRepresentation.reversed())
        let prefix = "\(FileManager.default.currentDirectoryPath)/extern/hashfiles/\(productStringRepresentation)/"

        return x[self]!.map { "\(prefix)\($0)" }
    }

}

public struct CdKeyExFlags: OptionSet {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let sameSessionKey         = CdKeyExFlags(rawValue: 1)
    public static let givenSessionKey        = CdKeyExFlags(rawValue: 2)
    public static let multiServerSessionKeys = CdKeyExFlags(rawValue: 4)
    public static let oldStyleResponses      = CdKeyExFlags(rawValue: 8)
}

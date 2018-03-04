public enum BnlsMessageIdentifier: UInt8 {
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
}

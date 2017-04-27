enum BnlsMessageIdentifier: UInt8 {
    case Authorize          = 0x0E
    case AuthorizeProof     = 0x0F
    case RequestVersionByte = 0x10
    case VersionCheckEx2    = 0x1A
    case Unknown            = 0xFF
}

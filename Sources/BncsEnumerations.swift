enum BncsMessageIdentifier: UInt8 {
    case Ping      = 0x25
    case AuthInfo  = 0x50
    case AuthCheck = 0x51
    case Unknown   = 0xFF
}

enum BncsPlatformIdentifier: UInt32 {
    case IntelX86 = 0x36385849
}

enum BncsProductIdentifier: UInt32 {
    case StarcraftJapan = 0x5254534a
}
